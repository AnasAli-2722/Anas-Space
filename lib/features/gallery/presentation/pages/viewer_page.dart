import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../domain/unified_asset.dart';

class ViewerPage extends StatelessWidget {
  final UnifiedAsset asset;

  const ViewerPage({super.key, required this.asset});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: _buildImage(),
            ),
          ),
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    final bool isMobile = Platform.isAndroid || Platform.isIOS;

    // 📱 Mobile Local
    if (isMobile && asset.isLocal) {
      return FutureBuilder<File?>(
        future: AssetEntity.fromId(asset.id).then((e) => e?.file),
        builder: (c, s) {
          if (s.hasData && s.data != null) {
            return Image.file(s.data!, fit: BoxFit.contain);
          }
          return const CircularProgressIndicator(color: Colors.blueAccent);
        },
      );
    }

    if (asset.isLocal && asset.localFile != null) {
      return Image.file(asset.localFile!, fit: BoxFit.contain);
    }

    if (asset.remoteUrl != null) {
      return Image.network(asset.remoteUrl!, fit: BoxFit.contain);
    }

    return const Icon(Icons.error);
  }
}
