import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class FilePickerService {
  // Singleton pattern
  static final FilePickerService _instance = FilePickerService._internal();
  factory FilePickerService() => _instance;
  FilePickerService._internal();

  // Video file picking methods
  Future<File?> pickVideoFile({
    FileType fileType = FileType.video,
    bool allowMultiple = false,
}) async {
  //TODO:: I dont know how, but it works without permissions, perhaps due to being debug versions, but need to add them whenever possible
    // Check and request permissions
    //if (!(await _checkAndRequestStoragePermission())) {
    //  return null;
    //}

    try {
      // Use file_picker for desktop, web, and as a fallback
      if (kIsWeb || !Platform.isAndroid && !Platform.isIOS) {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: fileType,
          allowMultiple: allowMultiple,
        );

        if (result != null) {
          return File(result.files.single.path!);
        }
      } 
      // Use image_picker for mobile platforms for better native integration
      else if (Platform.isAndroid || Platform.isIOS) {
        final picker = ImagePicker();
        final pickedFile = await picker.pickVideo(
          source: ImageSource.gallery,
        );

        if (pickedFile != null) {
          return File(pickedFile.path);
        }
      }
    } catch (e) {
      print('Error picking video file: $e');
    }

    return null;
  }

  // Camera video recording method
  Future<File?> recordVideoFile() async {
    // Check and request camera permissions
    if (!(await _checkAndRequestCameraPermission())) {
      return null;
    }

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickVideo(
        source: ImageSource.camera,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
    } catch (e) {
      print('Error recording video: $e');
    }

    return null;
  }

  // Generic file picking method
  Future<File?> pickGenericFile({
    FileType fileType = FileType.any,
    bool allowMultiple = false,
  }) async {
    // Check and request permissions
    if (!(await _checkAndRequestStoragePermission())) {
      return null;
    }

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: fileType,
        allowMultiple: allowMultiple,
      );

      if (result != null) {
        return File(result.files.single.path!);
      }
    } catch (e) {
      print('Error picking file: $e');
    }

    return null;
  }

  // Permission checking and requesting methods
  Future<bool> _checkAndRequestStoragePermission() async {
    // Different permission logic for different platforms
    if (Platform.isAndroid) {
      final status = await Permission.storage.status;
      if (!status.isGranted) {
        final result = await Permission.storage.request();
        return result.isGranted;
      }
      return true;
    } else if (Platform.isIOS) {
      // iOS doesn't require explicit storage permission
      return true;
    }
    // Desktop and web don't need special storage permissions
    return true;
  }

  Future<bool> _checkAndRequestCameraPermission() async {
    final status = await Permission.camera.status;
    if (!status.isGranted) {
      final result = await Permission.camera.request();
      return result.isGranted;
    }
    return true;
  }
}

// Example Usage in a Widget
class FilePickerExample extends StatefulWidget {
  @override
  _FilePickerExampleState createState() => _FilePickerExampleState();
}

class _FilePickerExampleState extends State<FilePickerExample> {
  final FilePickerService _filePickerService = FilePickerService();
  File? _selectedFile;

  Future<void> _pickVideoFile() async {
    final file = await _filePickerService.pickVideoFile();
    setState(() {
      _selectedFile = file;
    });
  }

  Future<void> _recordVideoFile() async {
    final file = await _filePickerService.recordVideoFile();
    setState(() {
      _selectedFile = file;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('File Picker Demo')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Display selected file path
            if (_selectedFile != null)
              Text('Selected File: ${_selectedFile!.path}'),

            // Buttons for picking and recording videos
            ElevatedButton(
              onPressed: _pickVideoFile,
              child: Text('Pick Video from Gallery'),
            ),
            ElevatedButton(
              onPressed: _recordVideoFile,
              child: Text('Record Video'),
            ),
          ],
        ),
      ),
    );
  }
}

// // Main app configuration
// void main() {
//   runApp(MaterialApp(
//     home: FilePickerExample(),
//   ));
// }
