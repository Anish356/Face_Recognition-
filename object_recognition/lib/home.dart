import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:object_recognition/main.dart';
import 'package:tflite/tflite.dart';

class home extends StatefulWidget {
  const home({Key? key}) : super(key: key);

  @override
  _homeState createState() => _homeState();
}

class _homeState extends State<home> {
  CameraController? controller;
  CameraImage? img;
  String result = "";
  bool isbusy = false;

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

    log(recognitions.toString());

    setState(() {
      result;
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
    await Tflite.close();

    controller?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Object_Recognition"),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            //Container(),

            CameraPreview(controller!),
            Text(
              "$result",
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[400]),
            )
          ],
        ),
      ),
    );
  }
}
