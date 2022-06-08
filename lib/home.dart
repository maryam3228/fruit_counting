import 'dart:io';
import 'dart:math';
import 'package:fruit_counting/image_screen.dart';
import 'package:image/image.dart' as img;
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

  Future<void> _getCount() async {
    try {
      // Create interpreter from asset.
      tfl.Interpreter interpreter = await tfl.Interpreter.fromAsset(
        "best-fp16.tflite",
        options: tfl.InterpreterOptions(),
      );

      var inputType = interpreter.getInputTensor(0).type;
      var outputShape = interpreter.getOutputTensor(0).shape;
      var outputDataType = interpreter.getOutputTensor(0).type;

      // Create a TensorImage object from a File
      TensorImage tensorImage = TensorImage(inputType);
      img.Image imageInput = img.decodeImage(_image!.readAsBytesSync())!;
      tensorImage.loadImage(imageInput);

      var cropSize = min(
        tensorImage.height,
        tensorImage.width,
      );

      // Initialization code
      ImageProcessor imageProcessor = ImageProcessorBuilder()
          .add(
            ResizeWithCropOrPadOp(
              cropSize,
              cropSize,
            ),
          )
          // Resize using Bilinear or Nearest neighbour
          .add(
            ResizeOp(
              640,
              640,
              ResizeMethod.NEAREST_NEIGHBOUR,
            ),
          )
          .add(
            QuantizeOp(0, 0.0),
          )
          .add(
            NormalizeOp(
              127.5,
              127.5,
            ),
          )
          .build();

      // Preprocess the image.
      tensorImage = imageProcessor.process(tensorImage);

      var outputBuffer = TensorBuffer.createFixedSize(
        outputShape,
        outputDataType,
      );

      var input = tensorImage.buffer;
      var output = outputBuffer.getBuffer();

      interpreter.run(
        input,
        output,
      );

      interpreter.close();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error loading model: ' + e.toString(),
          ),
        ),
      );
    }
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
              width: MediaQuery.of(context).size.width * 0.5,
              height: MediaQuery.of(context).size.height * 0.5,
              decoration: BoxDecoration(
                border: Border.all(),
              ),
              child: _image != null
                  ? Image.file(
                      _image!,
                      fit: BoxFit.fill,
                    )
                  : const Center(
                      child: Text(
                        'No image selected.',
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
              onPressed: () async {
                // await _getCount();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) {
                      return const ImageScreen();
                    },
                  ),
                );
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
