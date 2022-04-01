import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  File? _image;

  Future<void> _pickImage() async {
    var image = await ImagePicker().pickImage(source: ImageSource.gallery);
    try {
      if (image != null) {
        setState(() {
          _image = File(image.path);
        });
      }
    } on PlatformException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image. Error: $e'),
        ),
      );
    }
  }

  void _getCount() async {
    final interpreter = await tfl.Interpreter.fromAsset('assetName');
    var tensorImage = TensorImage.fromFile(_image!);
    ImageProcessor imageProcessor = ImageProcessorBuilder()
        .add(
          ResizeOp(640, 640, ResizeMethod.NEAREST_NEIGHBOUR),
        )
        .build();
    tensorImage = imageProcessor.process(tensorImage);
    var output = interpreter.getOutputTensor(0);
    interpreter.run(tensorImage, output);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EyeCount'),
        centerTitle: true,
      ),
      body: Container(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(),
                borderRadius: const BorderRadius.all(
                  Radius.circular(12.0),
                ),
              ),
              child: _image != null
                  ? Image.file(_image!)
                  : const Text(
                      'No image selected.',
                    ),
            ),
            const SizedBox(
              height: 20,
            ),
            ElevatedButton(
              style: ButtonStyle(
                shape: MaterialStateProperty.all(
                  const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(12.0),
                    ),
                  ),
                ),
              ),
              onPressed: () async {
                await _pickImage();
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: const [
                    Icon(
                      Icons.add_a_photo,
                    ),
                    SizedBox(
                      width: 20,
                    ),
                    Text('Choose Photo'),
                  ],
                ),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            ElevatedButton(
              style: ButtonStyle(
                shape: MaterialStateProperty.all(
                  const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(12.0),
                    ),
                  ),
                ),
              ),
              onPressed: () {
                _getCount();
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: const [
                    Icon(
                      Icons.numbers,
                    ),
                    SizedBox(
                      width: 20,
                    ),
                    Text('Get Count'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
