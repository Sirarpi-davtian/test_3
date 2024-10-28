import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:location/location.dart';

void main() {
  runApp(PhotoApp());
}

class PhotoApp extends StatelessWidget {
  const PhotoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: PhotoCaptureScreen(),
    );
  }
}

class PhotoCaptureScreen extends StatefulWidget {
  const PhotoCaptureScreen({super.key});

  @override
  State<PhotoCaptureScreen> createState() => _PhotoCaptureScreenState();
}

class _PhotoCaptureScreenState extends State<PhotoCaptureScreen> {
  File? _image;
  final TextEditingController _commentController = TextEditingController();
  LocationData? _location;

  final ImagePicker _picker = ImagePicker();
  final Location _locationService = Location();

//   @override
//   Widget build(BuildContext context) {
//     return const Placeholder();
//   }
// }
// // class PhotoCaptureScreen extends StatefulWidget {
// //   const PhotoCaptureScreen({super.key});

// //   @override
// //   _PhotoCaptureScreenState createState() => _PhotoCaptureScreenState();
// // }

// class _PhotoCaptureScreenState extends State<PhotoCaptureScreen> {
//   // File? _image;
//   // final TextEditingController _commentController = TextEditingController();
//   // LocationData? _location;

//   // final ImagePicker _picker = ImagePicker();
//   // final Location _locationService = Location();

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    bool serviceEnabled = await _locationService.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _locationService.requestService();
      if (!serviceEnabled) return;
    }

    PermissionStatus permissionGranted = await _locationService.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _locationService.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }

    _location = await _locationService.getLocation();
  }

  Future<void> _captureImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _sendData() async {
    if (_image == null || _location == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please capture an image and enable location.')),
        );
      }
      return;
    }

    final comment = _commentController.text;
    final uri =
        Uri.parse('https://flutter-sandbox.free.beeceptor.com/upload_photo/');

    final request = http.MultipartRequest('POST', uri)
      ..fields['comment'] = comment
      ..fields['latitude'] = _location!.latitude.toString()
      ..fields['longitude'] = _location!.longitude.toString()
      ..files.add(await http.MultipartFile.fromPath('photo', _image!.path));

    final response = await request.send();

    if (mounted) {
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo uploaded successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload photo.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Capture Photo')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_image != null)
              Image.file(_image!,
                  height: 200, width: double.infinity, fit: BoxFit.cover),
            const SizedBox(height: 20),
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                labelText: 'Enter your comment',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _captureImage,
              child: const Text('Capture Photo'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _sendData,
              child: const Text('Upload Photo'),
            ),
          ],
        ),
      ),
    );
  }
}
