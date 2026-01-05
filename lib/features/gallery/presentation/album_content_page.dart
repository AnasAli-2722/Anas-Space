import 'package:flutter/material.dart';
import '../../gallery/domain/album_model.dart';
import '../presentation/widgets/asset_tile.dart';
import '../../gallery/domain/unified_asset.dart';

class AlbumContentPage extends StatefulWidget {
  final UnifiedAlbum album;
  const AlbumContentPage({super.key, required this.album});

  @override
  State<AlbumContentPage> createState() => _AlbumContentPageState();
}

class _AlbumContentPageState extends State<AlbumContentPage> {
  List<UnifiedAsset> _assets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  Future<void> _loadAssets() async {
    List<UnifiedAsset> loaded = [];

    if (widget.album.mobileAlbum != null) {
      final count = await widget.album.mobileAlbum!.assetCountAsync;
      final entities = await widget.album.mobileAlbum!.getAssetListRange(
        start: 0,
        end: count,
      );

      loaded = entities
          .map(
            (e) => UnifiedAsset(
              id: e.id,
              isLocal: true,
              dateModified: e.createDateTime,
              deviceAsset: e,
            ),
          )
          .toList();
    } else if (widget.album.desktopAssets != null) {
      loaded = widget.album.desktopAssets!;
    }

    if (mounted) {
      setState(() {
        _assets = loaded;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.album.name),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(10),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 150,
                mainAxisSpacing: 5,
                crossAxisSpacing: 5,
              ),
              itemCount: _assets.length,
              itemBuilder: (ctx, i) => AssetTile(
                asset: _assets[i],
                isSelected: false,
                isSelectionMode: false,
                onSelect: () {},
              ),
            ),
    );
  }
}
