import 'dart:io';
import 'dart:math';
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

  void _getCount() async {
    var labels = await FileUtil.loadLabels('assets/labels.txt');
    print(labels);

    try {
      // Create interpreter from asset.
      tfl.Interpreter interpreter = await tfl.Interpreter.fromAsset(
        "best-fp16.tflite",
        options: tfl.InterpreterOptions(),
      );

      var inputShape = interpreter.getInputTensor(0).shape;
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

      print(inputShape);
      print(interpreter.getOutputTensor(0));

      var _probabilityProcessor = TensorProcessorBuilder()
          .add(
            NormalizeOp(
              127.5,
              127.5,
            ),
          )
          .build();
      Map<String, double> labeledProb = TensorLabel.fromList(
              labels, _probabilityProcessor.process(outputBuffer))
          .getMapWithFloatValue();
      print('labeledProb: $labeledProb');
    } catch (e) {
      print('Error loading model: ' + e.toString());
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
