import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import '../domain/unified_asset.dart';
import '../domain/album_model.dart';
import '../../../core/services/trash_service.dart';

class GalleryService {
  List<UnifiedAsset> _cachedAssets = [];
  List<UnifiedAsset> get cachedAssets => _cachedAssets;

  TrashService? _trashService;

  final List<String> _ignoredKeywords = [
    "2021",
    "2022",
    "2023",
    "2024",
    "2025",
    "2026",
  ];

  Set<String> get _excludedFolderNames => _ignoredKeywords.toSet();

  void initTrash(String trashPath) {
    _trashService = TrashService(trashPath: trashPath);
  }

  TrashService? get trashService => _trashService;

  Future<List<UnifiedAsset>> scanWhatsAppRaw() async {
    List<UnifiedAsset> found = [];

    // Accessing WhatsApp's raw media folders on Android often requires broad storage permissions.
    // If not granted, fail closed (skip hidden WhatsApp scan) rather than crashing.
    final hasAllFilesAccess = await Permission.manageExternalStorage.isGranted;
    if (!hasAllFilesAccess) {
      final req = await Permission.manageExternalStorage.request();
      if (!req.isGranted) return [];
    }

    final List<String> targetFolders = [
      "WhatsApp Images",
      "WhatsApp Video",
      "WhatsApp Documents",
    ];

    final List<String> basePaths = [
      '/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media',
      '/storage/emulated/0/WhatsApp/Media',
      '/storage/emulated/0/Android/media/com.whatsapp.w4b/WhatsApp Business/Media',
      '/storage/emulated/0/WhatsApp Business/Media',
    ];

    for (var base in basePaths) {
      final baseDir = Directory(base);
      if (!await baseDir.exists()) continue;

      for (var target in targetFolders) {
        final specificPath = Directory("$base/$target");
        if (!await specificPath.exists()) continue;

        try {
          final entities = specificPath
              .list(recursive: true, followLinks: false)
              .timeout(
                const Duration(seconds: 30),
                onTimeout: (sink) {
                  debugPrint("Scan timeout for $target");
                  sink.close();
                },
              );

          await for (var entity in entities) {
            if (entity is File) {
              final path = entity.path;
              final lowerPath = path.toLowerCase();

              if (path.contains("/Sent/") || path.contains("/Private/")) {
                continue;
              }

              if (_isValidMediaExtension(lowerPath)) {
                found.add(
                  UnifiedAsset(
                    id: entity.path,
                    isLocal: true,
                    dateModified: entity.lastModifiedSync(),
                    localFile: entity,
                  ),
                );
              }
            }
          }
        } catch (e, stackTrace) {
          debugPrintStack(
            label: "Error scanning $target: $e",
            stackTrace: stackTrace,
          );
        }
      }
    }
    return found;
  }

  Future<List<UnifiedAsset>> scanMobileGallery() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (!ps.isAuth) {
      return [];
    }

    List<UnifiedAsset> foundAssets = [];

    final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
      type: RequestType.common,
    );

    if (albums.isNotEmpty) {
      final recentAlbum = albums[0];
      final int assetCount = await recentAlbum.assetCountAsync;
      final List<AssetEntity> entities = await recentAlbum.getAssetListRange(
        start: 0,
        end: assetCount,
      );

      for (var e in entities) {
        foundAssets.add(
          UnifiedAsset(
            id: e.id,
            isLocal: true,
            dateModified: e.createDateTime,
            deviceAsset: e,
          ),
        );
      }
    }

    List<UnifiedAsset> hiddenWhatsApp = [];
    if (Platform.isAndroid) {
      hiddenWhatsApp = await scanWhatsAppRaw();
    }

    Map<String, UnifiedAsset> uniqueAssets = {};
    for (var asset in foundAssets) {
      uniqueAssets[asset.id] = asset;
    }
    for (var asset in hiddenWhatsApp) {
      uniqueAssets[asset.id] = asset;
    }

    _cachedAssets = uniqueAssets.values.toList();
    final cleanDashboardList = _cachedAssets.where((asset) {
      if (asset.localFile != null) {
        return !asset.localFile!.path.toLowerCase().contains("whatsapp");
      }
      if (asset.deviceAsset != null) {
        final path = (asset.deviceAsset!.relativePath ?? "").toLowerCase();
        return !path.contains("whatsapp");
      }
      return true;
    }).toList();

    return cleanDashboardList;
  }

  Future<List<UnifiedAsset>> scanDesktopGallery() async {
    if (!Platform.isWindows) return [];

    final files = <File>[];
    final userProfile = Platform.environment['USERPROFILE'];
    final oneDrive =
        Platform.environment['OneDrive'] ??
        Platform.environment['OneDriveConsumer'];

    final paths = <String>[];
    if (userProfile != null && userProfile.isNotEmpty) {
      paths.addAll([
        '$userProfile${Platform.pathSeparator}Pictures',
        '$userProfile${Platform.pathSeparator}Downloads',
        '$userProfile${Platform.pathSeparator}Videos',
      ]);
    }
    if (oneDrive != null && oneDrive.isNotEmpty) {
      paths.add('$oneDrive${Platform.pathSeparator}Pictures');
    }

    for (final p in paths.toSet()) {
      final dir = Directory(p);
      if (!await dir.exists()) continue;

      try {
        final scanned = await _scanDirectoryWindows(
          dir,
          timeout: const Duration(seconds: 30),
        );
        files.addAll(scanned);
      } catch (e, stackTrace) {
        debugPrintStack(
          label: 'Error scanning directory $p: $e',
          stackTrace: stackTrace,
        );
      }
    }

    _cachedAssets = files
        .map(
          (f) => UnifiedAsset(
            id: f.path,
            isLocal: true,
            localFile: f,
            dateModified: f.lastModifiedSync(),
          ),
        )
        .toList();

    return _cachedAssets;
  }

  Future<List<File>> _scanDirectoryWindows(
    Directory root, {
    required Duration timeout,
  }) async {
    final results = <File>[];
    final stopwatch = Stopwatch()..start();
    final queue = <Directory>[root];

    while (queue.isNotEmpty) {
      if (stopwatch.elapsed > timeout) {
        debugPrint('Scan timeout for directory: ${root.path}');
        break;
      }

      final current = queue.removeLast();
      try {
        await for (final entity in current.list(followLinks: false)) {
          if (stopwatch.elapsed > timeout) break;

          if (entity is Directory) {
            final folderName = entity.path
                .split(Platform.pathSeparator)
                .where((s) => s.isNotEmpty)
                .last;
            if (_excludedFolderNames.contains(folderName)) {
              continue;
            }
            queue.add(entity);
          } else if (entity is File) {
            if (_isUnderExcludedFolder(entity.path)) continue;
            final lower = entity.path.toLowerCase();
            if (_isValidMediaExtension(lower)) {
              results.add(entity);
            }
          }
        }
      } catch (_) {
        // Ignore per-folder read errors (permissions, transient issues)
      }
    }

    return results;
  }

  bool _isUnderExcludedFolder(String filePath) {
    final parts = filePath.split(Platform.pathSeparator);
    if (parts.length <= 1) return false;

    // Exclude only folder segments, not the filename.
    for (var i = 0; i < parts.length - 1; i++) {
      final part = parts[i];
      if (_excludedFolderNames.contains(part)) return true;
    }
    return false;
  }

  Future<List<UnifiedAlbum>> fetchAlbums() async {
    List<UnifiedAlbum> albums = [];
    Map<String, UnifiedAlbum> albumMap = {};

    if (Platform.isAndroid || Platform.isIOS) {
      final paths = await PhotoManager.getAssetPathList(
        type: RequestType.common,
      );

      for (var path in paths) {
        if (await path.assetCountAsync == 0) continue;

        final assets = await path.getAssetListRange(start: 0, end: 1);
        UnifiedAsset? cover;
        if (assets.isNotEmpty) {
          cover = UnifiedAsset(
            id: assets.first.id,
            isLocal: true,
            dateModified: assets.first.createDateTime,
            deviceAsset: assets.first,
          );
        }

        albumMap[path.name] = UnifiedAlbum(
          id: path.id,
          name: path.name,
          count: await path.assetCountAsync,
          mobileAlbum: path,
          coverAsset: cover,
        );
      }
    }

    final hiddenAssets = _cachedAssets
        .where((a) => a.deviceAsset == null && a.localFile != null)
        .toList();

    Map<String, List<UnifiedAsset>> hiddenFolders = {};
    for (var asset in hiddenAssets) {
      final parent = asset.localFile!.parent;
      final folderName = parent.path.split(Platform.pathSeparator).last;
      hiddenFolders.putIfAbsent(folderName, () => []).add(asset);
    }

    hiddenFolders.forEach((name, assets) {
      assets.sort((a, b) => b.dateModified.compareTo(a.dateModified));
      String albumName = albumMap.containsKey(name) ? "$name (Hidden)" : name;

      albumMap[albumName] = UnifiedAlbum(
        id: "hidden_$name",
        name: albumName,
        count: assets.length,
        desktopAssets: assets,
        coverAsset: assets.first,
      );
    });
    if (!Platform.isAndroid && !Platform.isIOS) {
      if (_cachedAssets.isEmpty) await scanDesktopGallery();

      Map<String, List<UnifiedAsset>> desktopFolders = {};
      for (var asset in _cachedAssets) {
        if (asset.localFile != null) {
          final parent = asset.localFile!.parent;
          final folderName = parent.path.split(Platform.pathSeparator).last;
          desktopFolders.putIfAbsent(folderName, () => []).add(asset);
        }
      }

      desktopFolders.forEach((name, assets) {
        assets.sort((a, b) => b.dateModified.compareTo(a.dateModified));
        albumMap[name] = UnifiedAlbum(
          id: name,
          name: name,
          count: assets.length,
          desktopAssets: assets,
          coverAsset: assets.first,
        );
      });
    }

    albums = albumMap.values.toList();
    albums.sort((a, b) {
      final nameA = a.name.toLowerCase();
      final nameB = b.name.toLowerCase();

      if (a.mobileAlbum?.isAll == true) return -1;
      if (b.mobileAlbum?.isAll == true) return 1;
      if (nameA.contains("camera")) return -1;
      if (nameB.contains("camera")) return 1;
      if (nameA.contains("whatsapp") && !nameB.contains("whatsapp")) return -1;
      if (!nameA.contains("whatsapp") && nameB.contains("whatsapp")) return 1;

      return nameA.compareTo(nameB);
    });

    return albums;
  }

  Future<List<UnifiedAsset>> scanLocker(String lockerPath) async {
    final dir = Directory(lockerPath);
    final files = <File>[];
    if (await dir.exists()) {
      try {
        await for (final entity in dir.list(followLinks: false)) {
          if (entity is File) files.add(entity);
        }
      } catch (e, stackTrace) {
        debugPrintStack(
          label: 'Error scanning locker $lockerPath: $e',
          stackTrace: stackTrace,
        );
      }
    }
    return files
        .map(
          (f) => UnifiedAsset(
            id: f.path,
            isLocal: true,
            localFile: f,
            dateModified: f.lastModifiedSync(),
          ),
        )
        .toList();
  }

  bool _isValidMediaExtension(String path) {
    return path.endsWith('.jpg') ||
        path.endsWith('.jpeg') ||
        path.endsWith('.png') ||
        path.endsWith('.mp4') ||
        path.endsWith('.mov') ||
        path.endsWith('.3gp') ||
        path.endsWith('.mkv');
  }
}
