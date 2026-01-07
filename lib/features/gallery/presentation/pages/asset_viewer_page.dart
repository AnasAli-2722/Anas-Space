import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../domain/unified_asset.dart';
import '../widgets/cinematic_background.dart';

class AssetViewerPage extends StatefulWidget {
  final UnifiedAsset asset;

  const AssetViewerPage({super.key, required this.asset});

  @override
  State<AssetViewerPage> createState() => _AssetViewerPageState();
}

class _AssetViewerPageState extends State<AssetViewerPage> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isVideo = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _checkTypeAndLoad();
  }

  Future<void> _checkTypeAndLoad() async {
    if (widget.asset.deviceAsset != null) {
      _isVideo = widget.asset.deviceAsset!.type == AssetType.video;
    } else if (widget.asset.localFile != null) {
      final path = widget.asset.localFile!.path.toLowerCase();
      _isVideo =
          path.endsWith('.mp4') ||
          path.endsWith('.mov') ||
          path.endsWith('.avi') ||
          path.endsWith('.mkv');
    } else if (widget.asset.remoteUrl != null) {
      final path = widget.asset.remoteUrl!.toLowerCase();
      _isVideo = path.endsWith('.mp4') || path.endsWith('.mov');
    }

    if (!_isVideo) {
      setState(() => _isInitialized = true);
      return;
    }

    try {
      if (widget.asset.deviceAsset != null) {
        final file = await widget.asset.deviceAsset!.file;
        if (file != null) {
          _videoController = VideoPlayerController.file(file);
        }
      } else if (widget.asset.localFile != null) {
        _videoController = VideoPlayerController.file(widget.asset.localFile!);
      } else if (widget.asset.remoteUrl != null) {
        _videoController = VideoPlayerController.networkUrl(
          Uri.parse(widget.asset.remoteUrl!),
        );
      }

      if (_videoController != null) {
        await _videoController!.initialize();
        _chewieController = ChewieController(
          videoPlayerController: _videoController!,
          autoPlay: true,
          looping: true,
          aspectRatio: _videoController!.value.aspectRatio,
          errorBuilder: (context, errorMessage) {
            return Center(
              child: Text(
                errorMessage,
                style: const TextStyle(color: Colors.white),
              ),
            );
          },
        );
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      debugPrint("Error loading video: $e");
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bool isDesktop = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            thickness: 1,
            color: cs.outlineVariant.withValues(alpha: 0.8),
          ),
        ),
      ),
      body: CinematicBackground(
        child: Center(
          child: _isVideo
              ? _buildVideoPlayer()
              : Hero(tag: widget.asset.id, child: _buildFullImage()),
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (!_isInitialized || _chewieController == null) {
      return const CircularProgressIndicator(strokeWidth: 2);
    }
    return AspectRatio(
      aspectRatio: _videoController!.value.aspectRatio,
      child: Chewie(controller: _chewieController!),
    );
  }

  Widget _buildFullImage() {
    if (widget.asset.deviceAsset != null) {
      return AssetEntityImage(
        widget.asset.deviceAsset!,
        isOriginal: true,
        fit: BoxFit.contain,
      );
    }

    if (widget.asset.localFile != null) {
      return Image.file(widget.asset.localFile!, fit: BoxFit.contain);
    }

    if (widget.asset.remoteUrl != null) {
      return Image.network(widget.asset.remoteUrl!, fit: BoxFit.contain);
    }

    return const Icon(Icons.error, color: Colors.white);
  }
}
