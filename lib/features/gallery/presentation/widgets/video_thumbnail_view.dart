import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class VideoThumbnailView extends StatefulWidget {
  final File videoFile;
  const VideoThumbnailView({super.key, required this.videoFile});

  @override
  State<VideoThumbnailView> createState() => _VideoThumbnailViewState();
}

class _VideoThumbnailViewState extends State<VideoThumbnailView> {
  File? _cachedFile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  Future<void> _loadThumbnail() async {
    try {
      if (!(Platform.isAndroid || Platform.isIOS)) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      final cacheDir = await getTemporaryDirectory();

      final uniqueName = "thumb_${widget.videoFile.path.hashCode}.jpg";
      final file = File("${cacheDir.path}/$uniqueName");

      if (await file.exists()) {
        if (mounted) {
          setState(() {
            _cachedFile = file;
            _isLoading = false;
          });
        }
        return;
      }

      final String? path = await VideoThumbnail.thumbnailFile(
        video: widget.videoFile.path,
        thumbnailPath: cacheDir.path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 200,
        quality: 50,
      );

      if (path != null) {
        final generatedFile = File(path);
        await generatedFile.rename(file.path);

        if (mounted) {
          setState(() {
            _cachedFile = file;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        color: Colors.grey[900],
        child: const Center(child: Icon(Icons.movie, color: Colors.white12)),
      );
    }

    if (_cachedFile != null) {
      return Image.file(
        _cachedFile!,
        fit: BoxFit.cover,
        errorBuilder: (ctx, error, stackTrace) =>
            Container(color: Colors.grey[900]),
      );
    }

    return Container(
      color: Colors.grey[900],
      child: const Center(
        child: Icon(Icons.error_outline, color: Colors.white24),
      ),
    );
  }
}
