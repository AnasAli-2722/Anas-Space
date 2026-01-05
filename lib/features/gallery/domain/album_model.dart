import 'package:photo_manager/photo_manager.dart';
import 'unified_asset.dart';

class UnifiedAlbum {
  //---------*Core Fields*---------
  final String id;
  final String name;
  final int count;
  final UnifiedAsset? coverAsset;

  //---------*Platform Specifics*---------
  // Used for Android/iOS standard albums (PhotoManager)
  final AssetPathEntity? mobileAlbum;

  // Used for Desktop folders or "Hidden" mobile folders
  final List<UnifiedAsset>? desktopAssets;

  //---------*Constructor*---------
  UnifiedAlbum({
    required this.id,
    required this.name,
    required this.count,
    this.coverAsset,
    this.mobileAlbum,
    this.desktopAssets,
  });
}
