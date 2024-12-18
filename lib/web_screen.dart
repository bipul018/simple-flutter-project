import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http_parser/http_parser.dart';
import 'package:video_player/video_player.dart';
import 'navigator.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'request_maker.dart';
import 'task_items.dart';

// Make a class type thingy,
// That takes in a list of items,
// With name, type (null | string | int | video file)
// Then a builder kind of func that makes a list of form fields
// based on those items
// Then you make a list of such class type thingies
// That you use to submit a post request thingy
// Which you then print to a snackbar


Future<String> fetchData(Uri url) async {
  //final response = await http.get(Uri.parse('https://fast.com'));
  //final response = await http.get(Uri.parse(url));
  final response = await http.get(url).timeout(
    const Duration(seconds: 10),
    onTimeout: () => throw TimeoutException("Connection timed out"),
  );

  if (response.statusCode == 200) {
    // If the server did return a 200 OK response,
    // then parse the JSON.
    String data = response.body;
    //print(data); // Or do something more useful with the data
    print("Data was received of length : ${data.length}");
    return data;
  } else {
    // If the server did not return a 200 OK response,
    // then throw an exception.
    throw Exception('Failed to load data with status: ${response.statusCode}');
  }
}

class WebScreen extends StatefulWidget{
  WebScreen(title, {super.key}): title = title[0]+": Web";
  final String title;
  @override
  State<WebScreen> createState() => _WebScreenState();
}


class _WebScreenState extends State<WebScreen> {
  String content="";
  final TextEditingController _hostnameController = TextEditingController();
  final TextEditingController _portController = TextEditingController();
  //Future<DynamicApiService>? _apiService=null;

  var _current_task = task_items[4];

  String _responseText = "";
  VideoPlayerController? _vid_player = null;
  
  @override
  void initState(){
    super.initState();
  }

  Uri? get _url { //Helper getter
    String hostname = _hostnameController.text;
    String? port = _portController.text.isNotEmpty ? _portController.text : null; //Port is optional

    if (hostname.isEmpty) return null; //Checks we have a hostname

    // Construct URL based on entered values
    Uri uri;
    try {
      uri = Uri.parse(hostname);
    } on FormatException {
      //Handle invalid URL formats
      return null;
    }


    if (port != null) {
      try {
        final portInt = int.parse(port);
        if (portInt >=0 && portInt <= 65535){
          return Uri(scheme: uri.scheme, host: uri.host, port: portInt);
        } else {
          return null;
        }      
      } on FormatException {  //If port isn't a valid int
        return null;
      }
    } else {
      return uri;
    }
  }

  @override
  Widget build(BuildContext cxt){
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      drawer:Drawer(
        child: Center(child:
          ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              // DrawerHeader (optional, for visual separation)
              const DrawerHeader(
                decoration: BoxDecoration(color: Colors.blue),
                child: Text('Network Settings', style: TextStyle(color: Colors.white)),),
              Padding( // Add some padding around the TextFields
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: <Widget>[
                    TextFormField(
                      controller: _hostnameController,
                      decoration: const InputDecoration(labelText: 'Hostname/IP/URL'),  //Clarify what can be entered
                    ),
                    TextFormField(
                      controller: _portController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Port (optional)'),
                    ),
                  ],
                ),
              ),
            ],
          )
        ),
      ),
      body : Column(
        children:[
          DropdownMenu(
            initialSelection: _current_task,
            label: const Text("Task Endpoint"),
            onSelected: (sel_task){
              if(sel_task != null){
                //ScaffoldMessenger.of(cxt).showSnackBar(
                //  SnackBar(
                //    content: Text("Task to be done is now : ${sel_task}"),
                //    backgroundColor: Colors.blue,
                //));
                //_current_task.endpoint = sel_task.endpoint;
                //_current_task.request_fields = List.from(sel_task.request_fields);
                _current_task = sel_task;
                setState(()=>{});
              }else{
                ScaffoldMessenger.of(cxt).showSnackBar(
                  SnackBar(
                    content: Text("No task was selected!!!"),
                    backgroundColor: Colors.red,
                ));
              }
              //ScaffoldMessenger.of(cxt).showSnackBar(
              //  SnackBar(
              //    content: Text("Current task is now : ${_current_task}"),
              //    backgroundColor: Colors.green,
              //));
            },
            dropdownMenuEntries: task_items.map(
              (it) => DropdownMenuEntry(
                value: it,
                label: it.endpoint,
              )
            ).toList()
          ),
          RequestObject(
            base_builder: (){
              final url = _url;
              if(url == null){
                return "";
              }
              return "${url}";
            },
            endpoint: _current_task.endpoint,
            request_fields: (){
              //print(">>>>>>>> Current task is now : ${_current_task}");
              return _current_task.request_fields;
            }(),
            //endpoint: "task/play_video",
            //request_fields: [
            //  (field_name: "name", type:RequestUnitType.string, nullable:false),
            //  (field_name: "phone", type:RequestUnitType.integer, nullable:true),
            //],
            on_submit: (response)async{
              _responseText = "";

              final Map<String, dynamic> jsonresp = json.decode(response.body);
              setState(() => {});
              
              // TODO:: Disable video player controller aka _vid_player

              if(jsonresp['status'] is String){
                if(jsonresp['status'].toLowerCase() == "error"){
                  ScaffoldMessenger.of(cxt).showSnackBar(
                    SnackBar(
                      content: Text("The task resulted in an error!!"),
                      backgroundColor: Colors.blue,
                  ));
                } else {
                  ScaffoldMessenger.of(cxt).showSnackBar(
                    SnackBar(
                      content: Text("The task was completed successfully!!"),
                      backgroundColor: Colors.blue,
                  ));
                }
              } else {
                throw Exception("Expected string as status of task response");
              }

              final val = jsonresp['value'];

              if((val is Map<String, dynamic>) && val.containsKey("type")){
                if(val["type"].toLowerCase() == "video/mp4"){
                  if(val.containsKey("bytes")){
                    // Setup video controller
                    // Decode base64 video bytes
                    Uint8List videoBytes = base64.decode(val["bytes"]);

                    // Create a temporary file to store the video
                    final tempDir = await getTemporaryDirectory();
                    final tempFile = File('${tempDir.path}/video.mp4');
                    await tempFile.writeAsBytes(videoBytes);

                    // Try making a uri first then play video for potential web support
                    // TODO:: check if for windows need to make special case or not
                    final file_uri = Uri.file(tempFile.path);

                    // Initialize video player
                    _vid_player = VideoPlayerController.contentUri(file_uri)
                    //_vid_player = VideoPlayerController.file(tempFile)
                      ..initialize().then((_) {
                        setState(() {});
                        _vid_player?.play();
                      });
                  } else{
                    throw Exception("Expected `bytes` field for video type");
                  }
                } else {
                  throw Exception("Unknown type ${val['type']} in json response");
                }
              } else {
                // Setup text printing
                _responseText = "${val}";
              }
              setState(()=>{});                  
              // check if value is a string/ dict
              // if dict, check if the value has a video
              // if video, play video just below this form, else print the text of this form
              
              
            }
        ),
        Expanded(child:((_vid_player == null) || (!_vid_player!.value.isInitialized))?Text(_responseText):
        AspectRatio(aspectRatio: _vid_player!.value.aspectRatio,
          child: VideoPlayer(_vid_player!))),
    ]),
      persistentFooterButtons: [Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: get_buttons(cxt),
      )]
    );
  }
}

