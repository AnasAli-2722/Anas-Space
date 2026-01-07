import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

import '../../data/gallery_service.dart';
import '../../domain/album_model.dart';
import '../../domain/unified_asset.dart';
import '../widgets/video_thumbnail_view.dart';
import '../album_content_page.dart';
import '../../../../ui/widgets/stone_theme_switch.dart';
import '../../../../ui/helpers/shadow_helpers.dart';

class AlbumsPage extends StatefulWidget {
  final GalleryService galleryService;
  const AlbumsPage({super.key, required this.galleryService});

  @override
  State<AlbumsPage> createState() => _AlbumsPageState();
}

class _AlbumsPageState extends State<AlbumsPage> {
  List<UnifiedAlbum> _albums = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlbums();
  }

  Future<void> _loadAlbums() async {
    final albums = await widget.galleryService.fetchAlbums();
    if (mounted) {
      setState(() {
        _albums = albums;
        _isLoading = false;
      });
    }
  }

  bool _isVideo(UnifiedAsset? asset) {
    if (asset == null) return false;
    if (asset.deviceAsset != null) {
      return asset.deviceAsset!.type == AssetType.video;
    }
    if (asset.localFile != null) {
      final path = asset.localFile!.path.toLowerCase();
      return path.endsWith('.mp4') ||
          path.endsWith('.mov') ||
          path.endsWith('.avi') ||
          path.endsWith('.mkv') ||
          path.endsWith('.3gp');
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final bool isDesktop = MediaQuery.of(context).size.width > 600;
    final double screenWidth = MediaQuery.of(context).size.width;

    // Responsive cross axis count
    int crossAxisCount;
    if (screenWidth > 1200) {
      crossAxisCount = 4;
    } else if (screenWidth > 800) {
      crossAxisCount = 3;
    } else if (screenWidth > 500) {
      crossAxisCount = 2;
    } else {
      crossAxisCount = 2;
    }

    final double spacing = isDesktop ? 16 : 12;
    final double padding = isDesktop ? 16 : 12;

    return Scaffold(
      appBar: AppBar(
        actions: const [StoneThemeSwitch()],
        title: Text(
          'ALBUMS',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.0,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : GridView.builder(
              padding: EdgeInsets.all(padding),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
                childAspectRatio: 0.8,
              ),
              itemCount: _albums.length,
              itemBuilder: (context, index) {
                final album = _albums[index];

                final isVideoCover = _isVideo(album.coverAsset);
                final hasCover = album.coverAsset != null;

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AlbumContentPage(album: album),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color.lerp(
                            cs.surface,
                            cs.onSurface,
                            isDarkTheme ? 0.06 : 0.03,
                          )!,
                          cs.surface,
                          Color.lerp(
                            cs.surface,
                            cs.onSurface,
                            isDarkTheme ? 0.02 : 0.01,
                          )!,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(isDesktop ? 16 : 12),
                      border: Border.all(
                        color: cs.outlineVariant.withValues(alpha: 0.85),
                        width: 1.5,
                      ),
                      boxShadow: [
                        subtleBoxShadow(
                          context,
                          color: cs.shadow,
                          lightAlpha: 0.25,
                          darkAlpha: 0.06,
                          lightBlur: 16,
                          darkBlur: 6,
                          lightOffset: const Offset(0, 8),
                          darkOffset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            margin: EdgeInsets.all(isDesktop ? 8 : 6),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                isDesktop ? 12 : 8,
                              ),
                              border: Border.all(
                                color: cs.outlineVariant.withValues(
                                  alpha: 0.75,
                                ),
                                width: 1,
                              ),
                              color: cs.surface,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                isDesktop ? 11 : 7,
                              ),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  if (hasCover) ...[
                                    if (isVideoCover &&
                                        album.coverAsset!.localFile != null)
                                      VideoThumbnailView(
                                        videoFile: album.coverAsset!.localFile!,
                                      )
                                    else if (album.coverAsset!.deviceAsset !=
                                        null)
                                      AssetEntityImage(
                                        album.coverAsset!.deviceAsset!,
                                        isOriginal: false,
                                        thumbnailSize:
                                            const ThumbnailSize.square(200),
                                        fit: BoxFit.cover,
                                      )
                                    else if (album.coverAsset!.localFile !=
                                        null)
                                      Image.file(
                                        album.coverAsset!.localFile!,
                                        fit: BoxFit.cover,
                                      ),
                                  ],
                                  // Subtle stone overlay (only on this large surface)
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          cs.onSurface.withValues(
                                            alpha: hasCover ? 0.06 : 0.08,
                                          ),
                                          Colors.transparent,
                                          cs.onSurface.withValues(
                                            alpha: hasCover ? 0.04 : 0.06,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Center(
                                    child: _buildPlaceholderIcon(
                                      hasCover,
                                      isVideoCover,
                                      isDesktop,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isDesktop ? 12 : 8,
                            vertical: isDesktop ? 8 : 6,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                album.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: isDesktop ? 16 : 14,
                                  color: cs.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.photo_library,
                                    size: isDesktop ? 14 : 12,
                                    color: cs.onSurface.withValues(alpha: 0.75),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "${album.count} items",
                                    style: TextStyle(
                                      color: cs.onSurface.withValues(
                                        alpha: 0.70,
                                      ),
                                      fontSize: isDesktop ? 12 : 11,
                                      fontFamily: 'Courier',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildPlaceholderIcon(
    bool hasCover,
    bool isVideoCover,
    bool isDesktop,
  ) {
    final cs = Theme.of(context).colorScheme;
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    if (!hasCover) {
      return Container(
        padding: EdgeInsets.all(isDesktop ? 16 : 12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              Color.lerp(cs.surface, cs.onSurface, isDarkTheme ? 0.08 : 0.04)!,
              cs.surface,
            ],
          ),
          border: Border.all(
            color: cs.outlineVariant.withValues(alpha: 0.85),
            width: 2,
          ),
        ),
        child: Icon(
          Icons.folder_open,
          size: isDesktop ? 50 : 40,
          color: cs.onSurface.withValues(alpha: 0.75),
        ),
      );
    }

    if (isVideoCover) {
      return const SizedBox();
    }
    return const SizedBox();
  }
}
