import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'dart:io';
import 'dart:typed_data';
import 'dart:math';

class ObjectDetectionScreen extends StatefulWidget {
  @override
  _ObjectDetectionScreenState createState() => _ObjectDetectionScreenState();
}

class _ObjectDetectionScreenState extends State<ObjectDetectionScreen> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  String _prediction = "No image analyzed";
  String _ecoTip = "";
  XFile? _imageFile;
  FlutterTts _tts = FlutterTts();
  Interpreter? _interpreter;
  List<String> _labels = [];

  Map<String, Map<String, dynamic>> carbonFootprintData = {
    "plastic bottle": {"co2": 0.1, "alternative": "Use a reusable bottle"},
    "glass bottle": {"co2": 0.08, "alternative": "Recycle glass bottles"},
    "paper": {"co2": 0.05, "alternative": "Use digital alternatives"},
    "organic waste": {"co2": 0.02, "alternative": "Compost food waste"},
    "e-waste": {"co2": 50.0, "alternative": "Recycle electronic waste properly"},
  };

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _loadModel();
  }

  void _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isNotEmpty) {
      _cameraController = CameraController(cameras.first, ResolutionPreset.medium);
      await _cameraController!.initialize();
      setState(() => _isCameraInitialized = true);
    }
  }

  void _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset("assets/models/model_unquant.tflite");

      // Load labels correctly
      String labelsData = await rootBundle.loadString('assets/models/labels.txt');
      _labels = labelsData.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

      print("Model and labels loaded successfully! Labels: $_labels");
    } catch (e) {
      print("Error loading model: $e");
    }
  }

  /// **Preprocess Image for TensorFlow Lite Model**
  Float32List _preprocessImage(String imagePath) {
    File imageFile = File(imagePath);
    img.Image? image = img.decodeImage(imageFile.readAsBytesSync());

    if (image == null) {
      throw Exception("Error decoding image");
    }

    // Resize to 224x224 as required by the model
    img.Image resizedImage = img.copyResize(image, width: 224, height: 224);

    // Convert image to Float32List
    var imageAsList = Float32List(224 * 224 * 3);
    int index = 0;
    for (int y = 0; y < 224; y++) {
      for (int x = 0; x < 224; x++) {
        var pixel = resizedImage.getPixel(x, y);
        imageAsList[index++] = pixel.r / 255.0; // Normalize [0,1]
        imageAsList[index++] = pixel.g / 255.0;
        imageAsList[index++] = pixel.b / 255.0;
      }
    }

    return imageAsList;
  }

  void _classifyImage(String imagePath) async {
    if (_interpreter == null) {
      print("Model not loaded!");
      return;
    }

    try {
      Float32List inputBytes = _preprocessImage(imagePath);
      var input = inputBytes.reshape([1, 224, 224, 3]);

      // Fetch actual output shape dynamically
      var numClasses = _interpreter!.getOutputTensor(0).shape[1];
      var outputBuffer = List.generate(numClasses, (index) => 0.0).reshape([1, numClasses]);

      print("Running inference...");
      _interpreter!.run(input, outputBuffer);
      print("Inference complete. Output: $outputBuffer");

      // Get highest probability label index
      int maxIndex = outputBuffer[0].indexOf(outputBuffer[0].reduce((double a, double b) => a > b ? a : b));
      double maxConfidence = outputBuffer[0][maxIndex];

      if (maxConfidence < 0.5) {
        setState(() {
          _prediction = "⚠️ Low Confidence - Try Again";
          _ecoTip = "";
        });
        return;
      }

      // Remove number prefix and format detected label
      String detectedItem = _labels[maxIndex].replaceAll(RegExp(r'^\d+\s*'), '').toLowerCase().trim();
      print("Detected: $detectedItem (Confidence: $maxConfidence)");

      // Retrieve carbon footprint data
      var footprintData = carbonFootprintData[detectedItem];

      if (footprintData == null) {
        print("⚠️ No carbon footprint data found for: $detectedItem");
        setState(() {
          _prediction = "Detected: $detectedItem\n(No carbon footprint data available)";
          _ecoTip = "";
        });
        return;
      }

      double co2Emission = footprintData["co2"];
      String ecoTip = footprintData["alternative"];

      setState(() {
        _prediction = "Detected: $detectedItem\nCO₂ Emission: ${co2Emission.toStringAsFixed(2)} kg";
        _ecoTip = ecoTip;
      });

      _tts.speak("Detected: $detectedItem. CO2 emission is ${co2Emission.toStringAsFixed(2)} kilograms. $ecoTip");

    } catch (e) {
      print("Error during classification: $e");
    }
  }

  void _captureImage() async {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      XFile image = await _cameraController!.takePicture();
      setState(() {
        _imageFile = image;
      });
    }
  }

  void _pickImageFromGallery() async {
    final picker = ImagePicker();
    XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
      });
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _interpreter?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("AI Waste Scanner")),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _imageFile == null
              ? (_isCameraInitialized
                  ? CameraPreview(_cameraController!)
                  : CircularProgressIndicator())
              : Image.file(File(_imageFile!.path), height: 250),
          SizedBox(height: 20),
          Text(_prediction, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          if (_ecoTip.isNotEmpty)
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("Eco Tip: $_ecoTip", style: TextStyle(color: Colors.green)),
            ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(icon: Icon(Icons.camera), label: Text("Capture"), onPressed: _captureImage),
              SizedBox(width: 10),
              ElevatedButton.icon(icon: Icon(Icons.image), label: Text("Gallery"), onPressed: _pickImageFromGallery),
            ],
          ),
          if (_imageFile != null)
            Padding(
              padding: EdgeInsets.only(top: 20),
              child: ElevatedButton.icon(icon: Icon(Icons.search), label: Text("Analyze"), onPressed: () => _classifyImage(_imageFile!.path)),
            ),
        ],
      ),
    );
  }
}
