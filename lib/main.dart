import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
// import 'package:image_picker/image_picker.dart';
import 'dart:io';
// import 'package:path/path.dart' as path;
import 'package:google_ml_kit/google_ml_kit.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const GalleryScreen(),
    );
  }
}

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  GalleryScreenStates createState() => GalleryScreenStates();
}

class GalleryScreenStates extends State<GalleryScreen> {
  List<String> imagePaths = [];
  Map<String, List<String>> imageGroups = {};
  @override
  void initState() {
    super.initState();
    getImages();
  }

  void getImages() async {
    final directory = await getExternalStorageDirectory();
    debugPrint('directory: ${directory}');

    final path = directory!.path;
    debugPrint('path: ${path}');
    final allFiles = Directory(path).listSync();
    debugPrint('allFiles: ${allFiles}');

    for (var file in allFiles) {
      if (file is File && _isImageFile(file.path)) {
        setState(() {
          imagePaths.add(file.path);
        });
      }
    }

    sortAndGroupImages();
  }

  bool _isImageFile(String path) {
    final validExtensions = ['.jpg', '.jpeg', '.png', '.gif'];
    final extension = path.toLowerCase();
    return validExtensions
        .any((validExtension) => extension.endsWith(validExtension));
  }

  void sortAndGroupImages() async {
    final imageLabeler = GoogleMlKit.vision.imageLabeler();
    for (var imagePath in imagePaths) {
      final inputImage = InputImage.fromFile(File(imagePath));
      final labels = await imageLabeler.processImage(inputImage);

      String category = 'Other';
      for (var label in labels) {
        if (label.label.toLowerCase().contains('nature')) {
          category = 'Nature';
          break;
        } else if (label.label.toLowerCase().contains('person') ||
            label.label.toLowerCase().contains('selfie')) {
          category = 'Selfie';
          break;
        }
      }

      if (imageGroups.containsKey(category)) {
        imageGroups[category]!.add(imagePath);
      } else {
        imageGroups[category] = [imagePath];
      }
    }

    imageLabeler.close();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gallery')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: imageGroups.length,
              itemBuilder: (context, index) {
                final category = imageGroups.keys.elementAt(index);
                final images = imageGroups[category]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        category,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 4.0,
                        mainAxisSpacing: 4.0,
                      ),
                      itemCount: images.length,
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemBuilder: (context, index) {
                        return Image.file(
                          File(images[index]),
                          fit: BoxFit.cover,
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
