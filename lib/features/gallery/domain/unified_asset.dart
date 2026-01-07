import 'dart:io';
import 'package:photo_manager/photo_manager.dart';
class UnifiedAsset {
  final String id;
  final bool isLocal;
  final DateTime dateModified;
  final File? localFile;
  final AssetEntity? deviceAsset;
  final String? remoteUrl;
  UnifiedAsset({
    required this.id,
    required this.isLocal,
    required this.dateModified,
    this.localFile,
    this.deviceAsset,
    this.remoteUrl,
  });
}

