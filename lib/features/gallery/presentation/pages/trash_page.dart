import 'package:flutter/material.dart';
import '../../data/gallery_service.dart';

class TrashPage extends StatelessWidget {
  final GalleryService galleryService;
  const TrashPage({super.key, required this.galleryService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Trash"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          "Trash Coming Soon!",
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
