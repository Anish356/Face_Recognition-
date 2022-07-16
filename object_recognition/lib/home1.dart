import 'dart:developer';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:object_recognition/main.dart';
import 'package:tflite/tflite.dart';

class home1 extends StatefulWidget {
  const home1({Key? key}) : super(key: key);

  @override
  _home1State createState() => _home1State();
}

class _home1State extends State<home1> {
  List? _recognitions;
  CameraController? controller;
  CameraImage? img;
  String result = "";
  bool isbusy = false;
  double? _imagehight;
  double? _imagewidth;

  @override
  initState() {
    super.initState();
    loadmodel();
    initcamera();
  }

  initcamera() {
    controller = CameraController(cameras![0], ResolutionPreset.max);
    controller!.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        controller!.startImageStream((image) => {
              if (!isbusy) {isbusy = true, img = image, startimageLabelling()}
            });
      });
    });
  }

  startimageLabelling() async {
    _imagewidth = img!.width + 0.0;
    _imagehight = img!.height + 0.0;
    var recognitions = await Tflite.runModelOnFrame(
        bytesList: img!.planes.map((plane) {
          return plane.bytes;
        }).toList(), // required
        imageHeight: img!.height,
        imageWidth: img!.width,
        imageMean: 127.5, // defaults to 127.5
        imageStd: 127.5, // defaults to 127.5
        rotation: 90, // defaults to 90, Android only
        numResults: 2, // defaults to 5
        threshold: 0.1, // defaults to 0.1
        asynch: true // defaults to true
        );

    result = "";
    recognitions!.forEach((element) {
      result += element["label"] + "\n";
      //log(element);
    });

    setState(() {
      result;
      _recognitions = recognitions;
    });
    isbusy = false;
    log(result);
  }

  loadmodel() async {
    String? res = await Tflite.loadModel(
        model: "assets/ssd_mobilenet.tflite",
        labels: "assets/ssd_mobilenet.txt",
        numThreads: 1, // defaults to 1
        isAsset:
            true, // defaults to true, set to false to load resources outside assets
        useGpuDelegate:
            false // defaults to false, set to true to use GPU delegate
        );
  }

  @override
  void dispose() async {
    // TODO: implement dispose
    super.dispose();
    controller?.dispose();
  }

  List<Widget> renderbox(Size screen) {
    if (_recognitions == null) return [];
    if (_imagehight == null || _imagewidth == null) return [];
    double factorX = screen.width;
    double factorY = _imagehight!;
    Color blue = Color.fromRGBO(37, 213, 253, 1.0);

    return _recognitions!.map((re) {
      //  log(re["rect"]);
      return Positioned(
          left: re["rect"]["x"] * factorX,
          top: re["rect"]["y"] * factorY,
          width: re["rect"]["w"] * factorX,
          height: re["rect"]["h"] * factorY,
          child: Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                border: Border.all(color: blue, width: 2)),
            child: Text(
              result,
              style: TextStyle(backgroundColor: blue),
            ),
          ));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: Text("Object_Recognition"),
      ),
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            //Container(),

            CameraPreview(controller!),
            Text(
              "$result",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            ...renderbox(size)
          ],
        ),
      ),
    );
  }
}
