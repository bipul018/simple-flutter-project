import 'package:image/image.dart' as imglib;
import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';
import 'dart:typed_data';

Future<Image?> convert_from_camera_image(CameraImage img) async{

  Uint8List? img_data = await convertImagetoPng(img);
  if(img_data == null) return null;
  return Image.memory(img_data);
}

Future<Uint8List?> convertImagetoPng(CameraImage image) async {
  try {
    imglib.Image? img = null;
    if (image.format.group == ImageFormatGroup.yuv420) {
      img = _convertYUV420(image);
    } else if (image.format.group == ImageFormatGroup.bgra8888) {
      img = _convertBGRA8888(image);
    }

    imglib.BmpEncoder bmpEncoder = new imglib.BmpEncoder();

    // Convert to bmp
    //List<int> bmp = bmpEncoder.encode(img);
    Uint8List bmp = bmpEncoder.encode(img!);
    return bmp;
  } catch (e) {
    print(">>>>>>>>>>>> ERROR:" + e.toString());
  }
  return null;
}

// CameraImage BGRA8888 -> PNG
// Color
imglib.Image _convertBGRA8888(CameraImage image) {
  return imglib.Image.fromBytes(
    width: image.width,
    height: image.height,
    bytes: image.planes[0].bytes.buffer,
    format: imglib.Format.uint8,
    order: imglib.ChannelOrder.bgra
  );
  //return imglib.Image.fromBytes(
    //image.width,
    //image.height,
    //image.planes[0].bytes,
    //format: imglib.Format.bgra,
  //);
}

// CameraImage YUV420_888 -> PNG -> Image (compresion:0, filter: none)
// Black
imglib.Image _convertYUV420(CameraImage image) {
  var img = imglib.Image(width: image.width, height: image.height, format:imglib.Format.uint8, numChannels: 4); // Create Image buffer

  Plane plane = image.planes[0];
  const int shift = (0xFF << 24);

  // Fill image buffer with plane[0] from YUV420_888
  var img_data = img.buffer.asUint32List();
  for (int x = 0; x < image.width; x++) {
    for (int planeOffset = 0;
      planeOffset < image.height * image.width;
      planeOffset += image.width) {
      final pixelColor = plane.bytes[planeOffset + x];
      // color: 0x FF  FF  FF  FF
      //           A   B   G   R
      // Calculate pixel color
      var newVal = shift | (pixelColor << 16) | (pixelColor << 8) | pixelColor;

      //img.data![planeOffset + x] = newVal;
      try{
        img_data[planeOffset + x] = newVal;
      }
      catch(e){
        print(">>>>>>>>>>>> ERROR: When trying to convert yuv, the size of image is ${image.width * image.height} and size of plane is${plane.bytes.length} and bytes per pixel is : ${img?.data?.bitsPerChannel} " + e.toString());
        throw e;
      }
    }
  }

  return img;
}

/*
import 'package:camera/camera.dart';
import 'package:cross_file/cross_file.dart';
// TODO:: Support IOS also by tweaking functions later
import 'package:processing_camera_image/processing_camera_image.dart';
import 'package:image/image.dart' as imglib;
import 'package:flutter/widgets.dart';

import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';
import 'package:image/image.dart' as imglib;
import 'dart:isolate';

// ... other imports

Future<Image?> convertYUV420toImage(CameraImage image) async {
  final int width = image.width;
  final int height = image.height;

  final ReceivePort receivePort = ReceivePort();

  await Isolate.spawn(
    _convertYUV420ToImageIsolate,
    [image.planes.map((plane) => plane.bytes).toList(), width, height, receivePort.sendPort],
  );

  final imglib.Image? img = await receivePort.first;

  if (img != null) {
    final pngBytes = imglib.PngEncoder().encode(img);
    return Image.memory(pngBytes);
  }

  return null;
}


void _convertYUV420ToImageIsolate(List<dynamic> args) {
  List<Uint8List> planes = args[0];
  int width = args[1];
  int height = args[2];
  SendPort sendPort = args[3];
  imglib.Image? img;

  try {
    img = imglib.Image.fromBytes(width: width, height: height,bytes: _yuv420toBytes(planes, width, height), format: imglib.Format.uint8, order: imglib.ChannelOrder.bgra);    
  } catch (e) {
    print("Error in isolate: $e");
  }
  sendPort.send(img);

}




Uint8List _yuv420toBytes(List<Uint8List> planes, int width, int height) {
  final Uint8List bytes = Uint8List(width * height * 4);
  final int uvRowStride = planes[1].bytesPerRow;
  final int? uvPixelStride = planes[1].bytesPerPixel;

  for (int x = 0; x < width; x++) {
    for (int y = 0; y < height; y++) {
      final int uvIndex = uvPixelStride! * x + uvRowStride * (y >> 1);
      final int index = y * width + x;

      final yp = planes[0][index];
      final up = planes[1][uvIndex];
      final vp = planes[2][uvIndex];


      int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
      int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91)
      .round()
      .clamp(0, 255);
      int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255);





      bytes[index * 4] = b; //b
      bytes[index * 4 + 1] = g;//g
      bytes[index * 4 + 2] = r; //r
      bytes[index * 4 + 3] = 255; //a
    }
  }
  return bytes;
}


Image? convert_from_camera_image_old(CameraImage img) {
  try{
    // Find details about image plane and show it

    // Convert img to a bytearray or something
    // TODO:: Convert this to IOS compatible
    var imgor = ProcessingCameraImage().processCameraImageToRGB(
      plane0:img.planes[0].bytes, bytesPerRowPlane0: img.planes[0].bytesPerRow,
      plane1:img.planes[1].bytes, bytesPerRowPlane1: img.planes[1].bytesPerRow,
      plane2:img.planes[2].bytes, width: img.width, height:img.height,
      bytesPerPixelPlan1: img.planes[1].bytesPerPixel, rotationAngle: 90.0);

    if(imgor != null){
      if(imgor.data == null){
        print("The image did not have any data at all ");
      }
      else{
        print("The image did have some data ");
      }
        return Image.memory(imglib.PngEncoder().
        encode(imgor, singleFrame: true));
      //_streamstr += "It Was Not Null\n";
    }
  }
  catch (e){
    return null;
  }
  return null;
}
*/
