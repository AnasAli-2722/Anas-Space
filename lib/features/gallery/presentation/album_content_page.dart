import 'package:flutter/material.dart';
import '../../gallery/domain/album_model.dart';
import '../presentation/widgets/asset_tile.dart';
import '../../gallery/domain/unified_asset.dart';
import '../../../ui/widgets/stone_theme_switch.dart';
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
    final bool isDesktop = MediaQuery.of(context).size.width > 600;
    final double screenWidth = MediaQuery.of(context).size.width;
    late int crossAxisCount;
    if (screenWidth > 1200) {
      crossAxisCount = 6;
    } else if (screenWidth > 800) {
      crossAxisCount = 4;
    } else if (screenWidth > 500) {
      crossAxisCount = 3;
    } else {
      crossAxisCount = 2;
    }
    final double spacing = isDesktop ? 10 : 6;
    final double padding = isDesktop ? 16 : 10;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.album.name.toUpperCase(),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        actions: [
          const StoneThemeSwitch(),
          Container(
            margin: EdgeInsets.only(right: isDesktop ? 16 : 12),
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 12 : 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.55),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(10),
              color: Theme.of(context).colorScheme.surface,
            ),
            child: Text(
              "${_assets.length} ITEMS",
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.75),
                fontWeight: FontWeight.w700,
                fontSize: isDesktop ? 13 : 11,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : GridView.builder(
              padding: EdgeInsets.all(padding),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: spacing,
                crossAxisSpacing: spacing,
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

