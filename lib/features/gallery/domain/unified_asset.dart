import 'dart:io';
import 'package:photo_manager/photo_manager.dart';

class UnifiedAsset {
  //---------*Core Fields*---------
  final String id;
  final bool isLocal;
  final DateTime dateModified;

  //---------*Local Data*---------
  final File? localFile;
  // For Standard Mobile Gallery items
  final AssetEntity? deviceAsset;

  //---------*Remote Data*---------
  // URL for assets on the connected device
  final String? remoteUrl;

  //---------*Constructor*---------
  UnifiedAsset({
    required this.id,
    required this.isLocal,
    required this.dateModified,
    this.localFile,
    this.deviceAsset,
    this.remoteUrl,
  });
}
