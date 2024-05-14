import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:simpsons/main.dart';
import 'package:tensorflow_lite_flutter/tensorflow_lite_flutter.dart';

import 'customCountainer.dart';

class homeScreen extends StatefulWidget {
  const homeScreen({super.key});

  @override
  State<homeScreen> createState() => _homeScreenState();
}

class _homeScreenState extends State<homeScreen> {
  CameraController? cameraController;
  ImagePicker imagePicker = ImagePicker();
  File? image;
  CameraImage? cameraImage;
  String output = '';
  late bool _loading = true;

  loadCamera() {
    cameraController = CameraController(cameras![0], ResolutionPreset.high);
    cameraController!.initialize().then((_) {
      if (!mounted) {
        return;
      } else {
        setState(() {
          cameraController!.startImageStream((image) {
            runCameraModel(image);
          });
        });
      }
    });
  }

  loadImageCamera() async {
    var img = await imagePicker.pickImage(source: ImageSource.camera);
    setState(() {
      if (img != null) {
        image = File(img.path);
      } else {
        return null;
      }
    });
    runModelImage(image);
  }

  loadImageGallery() async {
    var img = await imagePicker.pickImage(source: ImageSource.gallery);
    setState(() {
      if (img != null) {
        image = File(img.path);
      } else {
        return null;
      }
    });
    runModelImage(image);
  }

  runCameraModel(CameraImage img) async {
    //output
    var recognitions = await Tflite.runModelOnFrame(
        bytesList: img.planes.map((plane) {
          return plane.bytes;
        }).toList(), // required
        imageHeight: img.height,
        imageWidth: img.width,
        imageMean: 127.5, // defaults to 127.5
        imageStd: 127.5, // defaults to 127.5
        rotation: 90, // defaults to 90, Android only
        numResults: 2, // defaults to 5
        threshold: 0.1, // defaults to 0.1
        asynch: true // defaults to true
        );
    for (var i in recognitions!) {
      setState(() {
        output = i['label'];
      });
    }
  }

  runModelImage(image) async {
    var recognitions = await Tflite.runModelOnImage(
        path: image.path, // required
        imageMean: 0.0, // defaults to 117.0
        imageStd: 255.0, // defaults to 1.0
        numResults: 2, // defaults to 5
        threshold: 0.2, // defaults to 0.1
        asynch: true // defaults to true
        );
    for (var i in recognitions!) {
      setState(() {
        output = i['label'];
      });
    }
    setState(() {
      _loading = false;
      recognitions = recognitions!;
    });
  }

  LoadModel() async {
    await Tflite.loadModel(
      model: 'assets/simpsons_cnn.tflite',
      labels: 'assets/labels.txt',
    );
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadCamera();
    LoadModel();
  }

  void dispose() {
    cameraController!.dispose();
    //Tflite.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            height: 20,
          ),
          Center(
            child: Image.asset('assets/Simpsons_FamilyPicture.png'),
          ),
          const Text(
            'Who am I ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          CustomContainer(
            text: 'Gallery',
            onPressed: () {
              cameraImage = null;
              loadImageGallery();
            },
          ),
          const SizedBox(
            height: 10,
          ),
          CustomContainer(
            text: 'Camera',
            onPressed: () {
              cameraImage = null;
              loadImageCamera();
            },
          ),
          const SizedBox(
            height: 10,
          ),
          CustomContainer(
            text: 'Live Detection',
            onPressed: () {
              loadCamera();
            },
          ),
          const SizedBox(
            height: 10,
          ),
          _loading == false && cameraImage == null
              ? Column(
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width * .6,
                      height: MediaQuery.of(context).size.height * .3,
                      child: Image.file(image!),
                    ),
                    Text(
                      output,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 40,
                      ),
                    )
                  ],
                )
              : cameraImage != null
                  ? Column(
                      children: [
                        AspectRatio(
                          aspectRatio: cameraController!.value.aspectRatio,
                          child: CameraPreview(cameraController!),
                        ),
                        const SizedBox(
                          height: 0,
                        ),
                        Text(
                          output,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 40,
                          ),
                        ),
                      ],
                    )
                  : Container()

// const SizedBox(
//   height: 100,
// ),
// ElevatedButton(
//     onPressed: () {
//       loadImageGallery();
//     },
//     child: const Text('pick image')),
// image == null ? const Text('No chosen image') : Image.file(image!),
// const SizedBox(
//   height: 20,
// ),
// Text(output),
        ],
      ),
    );
  }
}
