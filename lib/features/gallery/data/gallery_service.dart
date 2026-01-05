import 'dart:io';
import 'package:photo_manager/photo_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import '../domain/unified_asset.dart';
import '../domain/album_model.dart';

class GalleryService {
  //---------*Variables & Cache*---------
  List<UnifiedAsset> _cachedAssets = [];
  List<UnifiedAsset> get cachedAssets => _cachedAssets;

  // Folders or keywords to exclude from scans
  final List<String> _ignoredKeywords = [
    "2021",
    "2022",
    "2023",
    "2024",
    "2025",
  ];

  //---------*WhatsApp Scanner (Android)*---------
  Future<List<UnifiedAsset>> scanWhatsAppRaw() async {
    List<UnifiedAsset> found = [];

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
          // Recursive scan for files
          final entities = specificPath.list(
            recursive: true,
            followLinks: false,
          );

          await for (var entity in entities) {
            if (entity is File) {
              final path = entity.path;
              final lowerPath = path.toLowerCase();

              // Skip Sent and Private folders to avoid duplicates
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
        } catch (e) {
          print("Error scanning $target: $e");
        }
      }
    }
    return found;
  }

  //---------*Mobile Scanner*---------
  Future<List<UnifiedAsset>> scanMobileGallery() async {
    // Permission Check
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (!ps.isAuth) {
      await Permission.storage.request();
      if (!await Permission.storage.isGranted) return [];
    }

    List<UnifiedAsset> foundAssets = [];

    // Standard PhotoManager Scan
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

    // specific WhatsApp Scan (Android only)
    List<UnifiedAsset> hiddenWhatsApp = [];
    if (Platform.isAndroid) {
      hiddenWhatsApp = await scanWhatsAppRaw();
    }

    // Merge Lists into Master Cache
    Map<String, UnifiedAsset> uniqueAssets = {};
    for (var asset in foundAssets) uniqueAssets[asset.id] = asset;
    for (var asset in hiddenWhatsApp) uniqueAssets[asset.id] = asset;

    _cachedAssets = uniqueAssets.values.toList();

    // Filter for Dashboard (Exclude WhatsApp items to avoid clutter)
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

  //---------*Desktop Scanner*---------
  Future<List<UnifiedAsset>> scanDesktopGallery() async {
    List<File> files = [];
    final userProfile = Platform.environment['USERPROFILE'];
    List<String> paths = [];

    if (userProfile != null) {
      paths = [
        '$userProfile\\Pictures',
        '$userProfile\\Downloads',
        '$userProfile\\Videos',
        '$userProfile\\OneDrive - University of Engineering and Technology Taxila\\Pictures',
      ];
    }

    for (var p in paths) {
      final dir = Directory(p);
      if (await dir.exists()) {
        try {
          await for (final file in dir.list(
            recursive: true,
            followLinks: false,
          )) {
            if (file is File) {
              final path = file.path.toLowerCase();

              // Apply blacklist filter
              bool isBlocked = _ignoredKeywords.any(
                (k) => path.contains(k.toLowerCase()),
              );
              if (isBlocked) continue;

              if (_isValidMediaExtension(path)) {
                files.add(file);
              }
            }
          }
        } catch (e) {
          // Access denied or system file error
        }
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

  //---------*Album Fetching*---------
  Future<List<UnifiedAlbum>> fetchAlbums() async {
    List<UnifiedAlbum> albums = [];
    Map<String, UnifiedAlbum> albumMap = {};

    // 1. Mobile Standard Albums
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

    // 2. Hidden/Raw Files Processing
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

    // 3. Desktop Logic
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

    // 4. Final Sort
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

  //---------*Locker Scanner*---------
  Future<List<UnifiedAsset>> scanLocker(String lockerPath) async {
    final dir = Directory(lockerPath);
    List<File> files = [];
    if (await dir.exists()) {
      files = dir.listSync().whereType<File>().toList();
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

  //---------*Helpers*---------
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
