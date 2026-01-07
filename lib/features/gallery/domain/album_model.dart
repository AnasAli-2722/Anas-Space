import 'package:photo_manager/photo_manager.dart';
import 'unified_asset.dart';
class UnifiedAlbum {
  final String id;
  final String name;
  final int count;
  final UnifiedAsset? coverAsset;
  final AssetPathEntity? mobileAlbum;
  final List<UnifiedAsset>? desktopAssets;
  UnifiedAlbum({
    required this.id,
    required this.name,
    required this.count,
    this.coverAsset,
    this.mobileAlbum,
    this.desktopAssets,
  });
}

