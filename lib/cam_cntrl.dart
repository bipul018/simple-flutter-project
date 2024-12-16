import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:video_player/video_player.dart';
import 'img_conv.dart';

class AdvancedCameraController {
  final CameraController _cameraController;
  final List<CameraDescription> _cameras;
  //VideoPlayerController? _videoPlayerController;
  StreamController<CameraImage>? _frameStreamController;
  //Timer? _frameStreamTimer;

  AdvancedCameraController._(this._cameras, this._cameraController);

  static Future<AdvancedCameraController> create() async{
    final cameras = await availableCameras();
    final cameraController = CameraController(
      cameras![0], 
      ResolutionPreset.high,
      enableAudio: true
    );
    await cameraController!.initialize();
    return AdvancedCameraController._(cameras, cameraController);
  }
  // Cleanup method
  void dispose() {
    _cameraController.dispose();
    //_videoPlayerController?.dispose();
    _frameStreamController?.close();
    //_frameStreamTimer?.cancel();
  }
  // B: Frame Streaming Methods
  void startFrameStreaming(int samplingRateHz) {
    _frameStreamController = StreamController<CameraImage>();

    DateTime start = DateTime.now();
    final to_wait = 1000 / samplingRateHz;
    
    
    _cameraController!.startImageStream((CameraImage image) {
        DateTime ftime = DateTime.now();
        if(ftime.difference(start).inMilliseconds > to_wait){
          start = DateTime.now();
          _frameStreamController!.add(image);
        }
    });

    // Control sampling rate
    // _frameStreamTimer = Timer.periodic(
    //   Duration(milliseconds: 1000 ~/ samplingRateHz), 
    //   (_) {
    //     // You can add additional frame processing logic here
    //   }
    // );
  }

  Stream<CameraImage>? get frameStream => _frameStreamController?.stream;
  Widget get cameraPreview => CameraPreview(_cameraController);

  void stopFrameStreaming() {
    _cameraController!.stopImageStream();
    _frameStreamController?.close();
    //_frameStreamTimer?.cancel();
  }

  // C: Custom Preview Processing
  Widget buildCustomCameraPreview(Widget Function(CameraImage?) previewBuilder) {
    if(frameStream != null) {
      return StreamBuilder<CameraImage?>(
        stream: frameStream,
        builder: (context, snapshot) {
          // Allow custom processing/drawing before display
          return previewBuilder(snapshot.data);
        }
      );
    }
    return previewBuilder(null);
  }


  /*
  Future<void> startVideoRecording({bool withSound = true}) async {
  if (!_cameraController!.value.isInitialized) {
  throw Exception('Camera not initialized');
}

  await _cameraController!.startVideoRecording();
}

  Future<File?> stopVideoRecording() async {
  if (!_cameraController!.value.isRecordingVideo) {
  return null;
}

  final XFile videoFile = await _cameraController!.stopVideoRecording();
  return File(videoFile.path);
}
  */


}

class CameraBox extends StatefulWidget{
  const CameraBox({super.key});

  @override
  State<CameraBox> createState() => _CameraBoxState();
}

class _CameraBoxState extends State<CameraBox>{
  bool _showPreview = true;
  late Future<AdvancedCameraController> _cameraHandler;
  @override
  void initState(){
    super.initState();
    _cameraHandler = AdvancedCameraController.create();
  }
  
  @override
  void dispose(){
    () async {
      (await _cameraHandler).dispose();
    }();
    super.dispose();
  }

  Widget _makeCameraPreview(Widget Function(CameraImage?) previewBuilder){
    return FutureBuilder<AdvancedCameraController>(
      future: _cameraHandler,
      builder: (cxt, snap){
        if(snap.hasData){
          return snap.data!.buildCustomCameraPreview(previewBuilder);
        }
        else{
          return previewBuilder(null);
        }
      }
    );
  }

  @override
  Widget build(BuildContext cxt){
    return Scaffold(
      //body: _cameraHandler.buildCustomCameraPreview((image) {
      body: Column(
        children: [
          SizedBox(
            height: 350,
            child:Center(child: (_showPreview?
              FutureBuilder<AdvancedCameraController>(
                future: _cameraHandler,
                builder: (cxt, snap){
                  if(snap.hasData){
                    return snap.data!.cameraPreview;
                  }
                  else{
                    return Text('No camera preview');
                  }
              }):Text("Camera Paused")))),
          Text("-----"),
          SizedBox(
            height: 350,
            child:Center(child: _makeCameraPreview((image) {
                // Example of custom processing: Add a red overlay
                if (image == null) return Text('No camera image');
                final fimg = convert_from_camera_image(image);
                return FutureBuilder<Image?>(
                  future:fimg,
                  builder:(cxt, snap){
                    if(snap.hasData && (snap.data! != null)){
                      return snap.data!!;
                    }
                    else return Text('No camera image');
                  }
                );
                //return Stack(
                //children: [
                //return img;
                // Custom overlay
                //Positioned.fill(
                //  child: Opacity(
                //    opacity: 0.3,
                //    child: Container(color: Colors.red),
                //  ),dddddddd
                //),
        }))),
      ]),
      floatingActionButton:
      FutureBuilder<AdvancedCameraController>(
        future: _cameraHandler,
        builder: (cxt, snap){
          if(snap.hasData){
            return Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton(
                  onPressed: (){
                    _showPreview = !_showPreview;
                    setState(()=>{});
                  },
                  child: Icon(_showPreview?
                    Icons.pause:
                    Icons.play_arrow),
                ),
                SizedBox(height: 10),
                FloatingActionButton(
                  onPressed: (){
                    snap.data!.startFrameStreaming(1); // 10 fps
                    setState(()=>{});
                  },
                  child: Icon(Icons.stream),
                )
              ],
            );
          }
          else{
            return Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: []
            );
          }
      }),
    );
  }
}
