import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_tflite/flutter_tflite.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:developer' as devtools;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Avengers Image Classification',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate to the main page after a delay
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MyHomePage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.deepPurple, Colors.purple, Colors.indigo],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(
                Icons.shield,
                size: 100,
                color: Colors.white,
              ),
              SizedBox(height: 14),
              Text(
                'Avengers Image Classification',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 100),
              Text(
                'Powered by Flutter',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File? filePath;
  String label = '';
  double confidence = 0.0;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _initTfLite();
  }

  Future<void> _initTfLite() async {
    try {
      await Tflite.loadModel(
        model: "assets/model.tflite",
        labels: "assets/labels.txt",
        numThreads: 1,
        isAsset: true,
        useGpuDelegate: false,
      );
      devtools.log("Model loaded successfully");
    } catch (e) {
      devtools.log("Error loading model: $e");
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: source);

      if (image == null) return;

      final imageFile = File(image.path);

      setState(() {
        filePath = imageFile;
        isLoading = true;
      });

      final recognitions = await Tflite.runModelOnImage(
        path: image.path,
        imageMean: 0.0,
        imageStd: 255.0,
        numResults: 2,
        threshold: 0.2,
        asynch: true,
      );

      if (recognitions != null && recognitions.isNotEmpty) {
        setState(() {
          confidence = (recognitions[0]['confidence'] * 100);
          label = recognitions[0]['label'];
          isLoading = false;
        });
      } else {
        devtools.log("No recognitions found");
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      devtools.log("Error picking image: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    Tflite.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Avengers Classification"),
        backgroundColor: Colors.indigo.shade900,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepPurple,
              Colors.purple,
              Colors.indigo,
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              children: [
                const SizedBox(height: 12),
                Card(
                  elevation: 20,
                  color: Colors.indigo.shade900,
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox(
                    width: 300,
                    child: Column(
                      children: [
                        const SizedBox(height: 18),
                        Container(
                          height: 350,
                          width: 350,
                          decoration: BoxDecoration(
                            color: Colors.indigo.shade800,
                            borderRadius: BorderRadius.circular(12),
                            image: filePath == null
                                ? const DecorationImage(
                                    image: AssetImage('assets/upload.jpeg'),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: filePath == null
                              ? const Text('')
                              : Image.file(
                                  filePath!,
                                  fit: BoxFit.cover,
                                ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              Text(
                                label,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "The Accuracy is ${confidence.toStringAsFixed(0)}%",
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                        if (isLoading)
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                        foregroundColor: Colors.white,
backgroundColor: Colors.indigo.shade900,
),
icon: const Icon(
Icons.camera_alt,
size: 24,
),
label: const Text(
"| Open Camera",
style: TextStyle(
fontSize: 20,
),
),
),
const SizedBox(height: 16),
ElevatedButton.icon(
onPressed: () => _pickImage(ImageSource.gallery),
style: ElevatedButton.styleFrom(
padding: const EdgeInsets.symmetric(
horizontal: 24,
vertical: 20,
),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(13),
),
foregroundColor: Colors.white,
backgroundColor: Colors.indigo.shade900,
),
icon: const Icon(
Icons.photo_library,
size: 24,
),
label: const Text(
"| Import from Gallery",
style: TextStyle(
fontSize: 20,
),
),
),
],
),
const SizedBox(height: 16),
ElevatedButton(
onPressed: () {
showModalBottomSheet(
context: context,
backgroundColor: Colors.transparent,
builder: (BuildContext context) {
return Container(
decoration: BoxDecoration(
color: Colors.indigo.shade900,
borderRadius: const BorderRadius.only(
topLeft: Radius.circular(20),
topRight: Radius.circular(20),
),
),
child: Column(
mainAxisSize: MainAxisSize.min,
children: const [
SizedBox(height: 16),
Text(
' - Description - ',
style: TextStyle(
fontSize: 20,
fontWeight: FontWeight.bold,
color: Colors.white,
),
),
SizedBox(height: 16),
Padding(
padding: EdgeInsets.symmetric(vertical: 16),
child: Text(
'This app uses TensorFlow Lite to classify Avengers characters based on the provided image. It supports both taking photos and selecting from the gallery.',
style: TextStyle(
fontSize: 16,
color: Colors.white,
),
),
),
SizedBox(height: 16),
],
),
);
},
);
},
style: ElevatedButton.styleFrom(
padding: const EdgeInsets.symmetric(
horizontal: 20,
vertical: 16,
),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(16),
),
foregroundColor: Colors.white,
backgroundColor: Colors.indigo.shade900,
),
child: const Text(
'Description',
style: TextStyle(
fontSize: 20,
),
),
),
],
),
),
),
),
bottomNavigationBar: Container(
height: 50,
decoration: const BoxDecoration(
gradient: LinearGradient(
begin: Alignment.topCenter,
end: Alignment.bottomCenter,
colors: [
Colors.deepPurple,
Colors.purple,
Colors.indigo,
],
),
),
),
);
}
}
