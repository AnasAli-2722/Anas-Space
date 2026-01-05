import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import '../../domain/unified_asset.dart';
import '../pages/asset_viewer_page.dart';
import 'video_thumbnail_view.dart';

class AssetTile extends StatelessWidget {
  final UnifiedAsset asset;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onSelect;

  const AssetTile({
    super.key,
    required this.asset,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    bool isVideo = false;
    if (asset.deviceAsset != null) {
      isVideo = asset.deviceAsset!.type == AssetType.video;
    } else if (asset.localFile != null) {
      final path = asset.localFile!.path.toLowerCase();
      isVideo =
          path.endsWith('.mp4') ||
          path.endsWith('.mov') ||
          path.endsWith('.avi') ||
          path.endsWith('.3gp') ||
          path.endsWith('.mkv');
    }

    return GestureDetector(
      onTap: isSelectionMode
          ? onSelect
          : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AssetViewerPage(asset: asset),
                ),
              );
            },
      onLongPress: onSelect,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                color: Colors.grey[900],
                child: _buildImageContent(context, isVideo),
              ),
            ),
          ),

          if (isVideo)
            const Center(
              child: Icon(
                Icons.play_circle_fill,
                color: Colors.white70,
                size: 40,
              ),
            ),

          if (isSelected)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blueAccent, width: 3),
                ),
                child: const Center(
                  child: Icon(Icons.check, color: Colors.white, size: 30),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageContent(BuildContext context, bool isVideo) {
    if (asset.deviceAsset != null) {
      return AssetEntityImage(
        asset.deviceAsset!,
        isOriginal: false,
        thumbnailSize: const ThumbnailSize.square(200),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Center(child: Icon(Icons.error, color: Colors.red));
        },
      );
    }

    if (asset.localFile != null) {
      if (isVideo) {
        return VideoThumbnailView(videoFile: asset.localFile!);
      }

      return Image.file(
        asset.localFile!,
        fit: BoxFit.cover,
        cacheWidth: 200,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(Icons.broken_image, color: Colors.white24),
          );
        },
      );
    }

    return Container();
  }
}
