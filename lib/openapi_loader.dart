import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'file_picking.dart';

class OpenApiSpecResolver {
  final Map<String, dynamic> specification;

  OpenApiSpecResolver(this.specification);

  // Resolve a reference in the OpenAPI specification
  dynamic resolveReference(String reference) {
    // Remove the '#/' prefix if present
    final cleanRef = reference.startsWith('#/') 
      ? reference.substring(2) 
      : reference;
    
    // Split the reference path
    final parts = cleanRef.split('/');
    
    // Traverse the specification to find the referenced object
    dynamic currentObj = specification;
    for (var part in parts) {
      currentObj = currentObj[part];
      if (currentObj == null) {
        throw ArgumentError('Could not resolve reference: $reference');
      }
    }
    
    return currentObj;
  }

  // Find the video upload field name for a specific endpoint
  String findVideoUploadFieldName(Map<String, dynamic> pathSpec) {
    try {
      // Get the request body specification
      final requestBody = pathSpec['post']['requestBody']?['content']?['multipart/form-data']?['schema'];
      
      // Check if it uses $ref or allOf
      if (requestBody == null) {
        throw ArgumentError('No multipart/form-data schema found');
      }

      // Resolve references if needed
      Map<String, dynamic> resolvedSchema;
      if (requestBody.containsKey('\$ref')) {
        // Directly resolve a full reference
        resolvedSchema = resolveReference(requestBody['\$ref']);
      } else if (requestBody.containsKey('allOf')) {
        // Merge schemas from allOf
        resolvedSchema = _mergeAllOfSchemas(requestBody['allOf']);
      } else {
        resolvedSchema = requestBody;
      }

      // Find the binary file field
      final properties = resolvedSchema['properties'] ?? {};
      final videoFieldName = properties.keys.firstWhere(
        (key) => properties[key]['type'] == 'string' && 
                properties[key]['format'] == 'binary',
        orElse: () => 'video'
      );

      return videoFieldName;
    } catch (e) {
      print('Error finding video upload field: $e');
      return 'video'; // Fallback to default
    }
  }

  // Merge schemas from allOf to handle complex references
  Map<String, dynamic> _mergeAllOfSchemas(List<dynamic> allOfSchemas) {
    Map<String, dynamic> mergedSchema = {};

    for (var schemaRef in allOfSchemas) {
      // Resolve each reference
      dynamic schema;
      if (schemaRef.containsKey('\$ref')) {
        schema = resolveReference(schemaRef['\$ref']);
      } else {
        schema = schemaRef;
      }

      // Merge properties
      if (schema['properties'] != null) {
        mergedSchema.addAll(schema['properties']);
      }
    }

    return {'properties': mergedSchema};
  }
}

class DynamicApiService {
  final String baseUrl;
  final Map<String, dynamic> apiSpecification;
  late OpenApiSpecResolver _specResolver;

  DynamicApiService({
      required this.baseUrl, 
      required this.apiSpecification
  }){
    _specResolver=OpenApiSpecResolver(apiSpecification);
  }

  // Factory constructor to load OpenAPI spec from a file or network
  static Future<DynamicApiService> create({
    required String baseUrl, 
    String? specPath,
    Map<String, dynamic>? specJson
  }) async {
    Map<String, dynamic> specification;
    
    if (specJson != null) {
      specification = specJson;
    } else if (specPath != null) {
      // Load from file
      final file = File(specPath);
      specification = json.decode(await file.readAsString());
    } else {
      throw ArgumentError('Either specPath or specJson must be provided');
    }

    return DynamicApiService(
      baseUrl: baseUrl, 
      apiSpecification: specification
    );
  }

  Future<dynamic> executeTaskEndpoint({
      required String endpointPath, 
      Map<String, dynamic>? queryParams,
      File? videoFile
  }) async {
    // Remove '/task/' prefix if present
    final cleanPath = endpointPath.startsWith('/task/') 
      ? endpointPath.substring(6) 
      : endpointPath;
    
    // Construct full URL
    final fullPath = '/task/$cleanPath';
    
    // Find the endpoint specification
    final pathSpec = apiSpecification['paths'][fullPath];
    if (pathSpec == null) {
      throw ArgumentError('Endpoint $fullPath not found in API specification');
    }
    
    // Prepare URI with query parameters
    var uri = Uri.parse('$baseUrl$fullPath');
    if (queryParams != null) {
      uri = uri.replace(
        queryParameters: queryParams.map((key, value) => 
          MapEntry(key, value?.toString())
        )
      );
    }

    
    var request = http.MultipartRequest('POST', uri);

    // Dynamically find the video upload field name
    final videoFieldName = _specResolver.findVideoUploadFieldName(pathSpec);

    // Rest of the existing implementation remains the same...
    // Just replace the hardcoded 'video' with videoFieldName when adding the file

    print(">>>>>>> Going to send some stuff such as : video ${videoFieldName}, with video file : {videoFile?.path}");

    if(videoFile != null){
      request.files.add(await http.MultipartFile.fromPath(
          videoFieldName, 
          videoFile!.path,
          contentType: MediaType('video', 'mp4')
      ));
    }
    // Send the request
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    
    // Handle response
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.body;
    } else {
      throw HttpException('Request failed with status ${response.statusCode}: ${response.body}');
    }
  }


  // Dynamic method to handle task endpoints
  //Future<dynamic> executeTaskEndpoint({
  //  required String endpointPath, 
  //  Map<String, dynamic>? queryParams,
  //  File? videoFile
  //}) async {
  //  // Remove '/task/' prefix if present
  //  final cleanPath = endpointPath.startsWith('/task/') 
  //    ? endpointPath.substring(6) 
  //    : endpointPath;
  //  
  //  // Construct full URL
  //  final fullPath = '/task/$cleanPath';
  //  
  //  // Find the endpoint specification
  //  finspiSpecification['paths'][fullPath];
  //  if (pathSpec == null) {
  //    throw ArgumentError('Endpoint $fullPath not found in API specification');
  //  }
//
  //  // Prepare URI with query parameters
  //  var uri = Uri.parse('$baseUrl$fullPath');
  //  if (queryParams != null) {
  //    uri = uri.replace(
  //      queryParameters: queryParams.map((key, value) => 
  //        MapEntry(key, value?.toString())
  //      )
  //    );
  //  }
//
  //  // Prepare multipart request
  //  var request = http.MultipartRequest('POST', uri);
  //  
  //  // Add video file if required and provided
  //  if (videoFile != null) {
  //    // Determine the file field name from the specification
  //    final requestBodySpec = pathSpec['post']['requestBody']?['content']?['multipart/form-data']?['schema']?['properties'];
  //    final videoFieldName = requestBodySpec?.keys.firstWhere(
  //      (key) => requestBodySpec[key]['type'] == 'string' && 
  //              requestBodySpec[key]['format'] == 'binary',
  //      orElse: () => 'video'
  //    );
  //    print(">>>>> From just before sending a multipartfile, the value of pathspec['post']['requestBody']['content']['multipart/form-data']['schema'] is ${pathSpec['post']['requestBody']['content']['multipart/form-data']['schema']}");
  //    
  //    print(">>>>> From just before sending a multipartfile, videofieldname is of type ${videoFieldName.runtimeType} and videofile type is ${videoFile.runtimeType}");
//
  //    request.files.add(await http.MultipartFile.fromPath(
  //      videoFieldName, 
  //      videoFile.path,
  //      contentType: MediaType('video', 'mp4')
  //    ));
  //  }
//
  //  // Send the request
  //  var streamedResponse = await request.send();
  //  var response = await http.Response.fromStream(streamedResponse);
//
  //  // Handle response
  //  if (response.statusCode >= 200 && response.statusCode < 300) {
  //    return response.body;
  //  } else {
  //    throw HttpException('Request failed with status ${response.statusCode}: ${response.body}');
  //  }
  //}

  // Method to get available task endpoints
  List<String> getAvailableTaskEndpoints() {
    return (apiSpecification['paths'] as Map<String, dynamic>).keys
      .where((path) => path.startsWith('/task/'))
      .toList();
  }
}

// Example Usage in a Flutter Widget
class DynamicApiExample extends StatefulWidget {
  final DynamicApiService apiService;

  const DynamicApiExample({Key? key, required this.apiService}) : super(key: key);

  @override
  _DynamicApiExampleState createState() => _DynamicApiExampleState();
}

class _DynamicApiExampleState extends State<DynamicApiExample> {
  List<String> availableEndpoints = [];
  String? selectedEndpoint;
  File? selectedVideoFile;
  final _filePicking = FilePickerService();

  @override
  void initState() {
    super.initState();
    // Populate available endpoints
    availableEndpoints = widget.apiService.getAvailableTaskEndpoints();
  }

  Future<void> _processVideo() async {
    if (selectedEndpoint == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select an endpoint'))
      );
      return;
    }

    try {
      // Dynamic endpoint execution
      final result = await widget.apiService.executeTaskEndpoint(
        endpointPath: selectedEndpoint!,
        videoFile: selectedVideoFile,
        // Optional: Add query parameters if needed
        // queryParams: {'fps': 1, 'frames': 10}
      );

      // Handle result
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Processing complete: $result'))
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Dynamic API Service')),
      body: Column(
        children: [
          // Endpoint Dropdown
          DropdownButton<String>(
            hint: Text('Select Endpoint'),
            value: selectedEndpoint,
            items: availableEndpoints.map((endpoint) => 
              DropdownMenuItem(
                value: endpoint,
                child: Text(endpoint)
              )
            ).toList(),
            onChanged: (value) {
              setState(() {
                selectedEndpoint = value;
              });
            },
          ),
          // File Picker (simplified, replace with proper file picking logic)
          ElevatedButton(
            onPressed: () async{
              selectedVideoFile = await _filePicking.pickVideoFile();
            },
            child: Text('Pick Video File'),
          ),
          ElevatedButton(
            onPressed: () {
              selectedVideoFile = null;
            },
            child: Text('Clear Video File'),
          ),
          // Process Button
          ElevatedButton(
            onPressed: _processVideo,
            child: Text('Process Video'),
          )
        ],
      ),
    );
  }
}

// Example of creating and using the service
void initializeDynamicApiService(Map<String, dynamic> openApiJson) async {
  try {
    final apiService = DynamicApiService(
      baseUrl: 'http://your-api-endpoint.com',
      apiSpecification: openApiJson
    );

    // Get available task endpoints
    print(apiService.getAvailableTaskEndpoints());

    // Example of dynamically calling an endpoint
    final result = await apiService.executeTaskEndpoint(
      endpointPath: '/task/downsample_it',
      videoFile: File('/path/to/video.mp4'),
      queryParams: {'factor': 2}
    );
  } catch (e) {
    print('Error initializing API service: $e');
  }
}
