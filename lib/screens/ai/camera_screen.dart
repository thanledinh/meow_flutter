import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../config/theme.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});
  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  String? _imagePath;

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.camera, maxWidth: 1200, imageQuality: 85);
    if (img != null) setState(() => _imagePath = img.path);
  }

  Future<void> _fromGallery() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 85);
    if (img != null) setState(() => _imagePath = img.path);
  }

  @override
  void initState() { super.initState(); _takePhoto(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: const Text('Camera', style: TextStyle(color: Colors.white)),
      ),
      body: _imagePath != null
          ? Column(children: [
              Expanded(child: Image.file(File(_imagePath!), fit: BoxFit.contain)),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                    ElevatedButton.icon(
                      onPressed: _takePhoto,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Chụp lại'),
                      style: ElevatedButton.styleFrom(backgroundColor: MoewColors.primary),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context, _imagePath),
                      icon: const Icon(Icons.check),
                      label: const Text('Sử dụng'),
                      style: ElevatedButton.styleFrom(backgroundColor: MoewColors.success),
                    ),
                  ]),
                ),
              ),
            ])
          : Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                IconButton(icon: const Icon(Icons.camera_alt, size: 64, color: Colors.white70), onPressed: _takePhoto),
                const SizedBox(height: 16),
                TextButton(onPressed: _fromGallery, child: const Text('Chọn từ thư viện', style: TextStyle(color: Colors.white70))),
              ]),
            ),
    );
  }
}
