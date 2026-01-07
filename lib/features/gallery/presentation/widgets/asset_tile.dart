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
    final cs = Theme.of(context).colorScheme;
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
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  color: cs.surface,
                  border: Border.all(
                    color: isSelected
                        ? cs.primary
                        : cs.outlineVariant.withValues(alpha: 0.55),
                    width: isSelected ? 2.5 : 1.0,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: cs.shadow.withValues(alpha: 0.22),
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                          ),
                        ]
                      : null,
                ),
                child: _buildImageContent(context, isVideo),
              ),
            ),
          ),

          if (isVideo)
            Center(
              child: Container(
                decoration: BoxDecoration(
                  color: cs.surface.withValues(alpha: 0.72),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: cs.shadow.withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.play_circle_fill,
                  color: cs.onSurface.withValues(alpha: 0.85),
                  size: 36,
                ),
              ),
            ),

          if (isSelected)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cs.primary,
                      boxShadow: [
                        BoxShadow(
                          color: cs.shadow.withValues(alpha: 0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(6),
                    child: const Icon(
                      Icons.check,
                      color: Colors.black,
                      size: 24,
                    ),
                  ),
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
