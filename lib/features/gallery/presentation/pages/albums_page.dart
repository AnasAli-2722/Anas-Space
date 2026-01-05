import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

import '../../data/gallery_service.dart';
import '../../domain/album_model.dart';
import '../../domain/unified_asset.dart';
import '../widgets/video_thumbnail_view.dart';
import '../album_content_page.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Albums"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white12),
                            color: Colors.grey[900],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
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
                                      thumbnailSize: const ThumbnailSize.square(
                                        200,
                                      ),
                                      fit: BoxFit.cover,
                                    )
                                  else if (album.coverAsset!.localFile != null)
                                    Image.file(
                                      album.coverAsset!.localFile!,
                                      fit: BoxFit.cover,
                                    ),
                                ],

                                Center(
                                  child: _buildPlaceholderIcon(
                                    hasCover,
                                    isVideoCover,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        album.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        "${album.count} items",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildPlaceholderIcon(bool hasCover, bool isVideoCover) {
    if (!hasCover) {
      return const Icon(Icons.folder_open, size: 50, color: Colors.white24);
    }

    if (isVideoCover) {
      return const SizedBox();
    }
    return const SizedBox();
  }
}
