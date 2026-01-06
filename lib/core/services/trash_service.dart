import 'dart:io';
import 'package:flutter/foundation.dart';

/// Manages soft delete and restore operations for Windows
/// Files are moved to a `.trash` directory instead of being permanently deleted
class TrashService {
  final String _trashPath;

  TrashService({required String trashPath}) : _trashPath = trashPath;

  /// Initialize trash directory
  Future<void> init() async {
    final dir = Directory(_trashPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  /// Get the trash directory
  Directory get trashDirectory => Directory(_trashPath);

  /// Move file to trash (soft delete)
  /// Returns the trash path if successful, null otherwise
  Future<String?> moveToTrash(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;

      final fileName = filePath.split(Platform.pathSeparator).last;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final trashFileName = '${timestamp}_$fileName';
      final trashFilePath =
          '$_trashPath${Platform.pathSeparator}$trashFileName';

      // Create a metadata file to track original path
      final metadataPath = '$trashFilePath.meta';
      final metadataFile = File(metadataPath);
      await metadataFile.writeAsString(filePath);

      // Move file to trash.
      // On Windows, rename can fail for some locations (cloud drives, cross-device)
      // or behave unexpectedly depending on underlying provider. We guarantee the
      // original path no longer exists by falling back to copy+delete.
      try {
        await file.rename(trashFilePath);
      } on FileSystemException {
        await file.copy(trashFilePath);
        if (await File(trashFilePath).exists()) {
          await file.delete();
        }
      }

      // Extra safety: if the original still exists for any reason, delete it.
      final originalStillExists = await File(filePath).exists();
      if (originalStillExists) {
        try {
          await File(filePath).delete();
        } catch (_) {
          // If we can't delete, keep the trash copy but report failure.
          return null;
        }
      }

      debugPrint('Moved to trash: $filePath -> $trashFilePath');
      return trashFilePath;
    } catch (e, stackTrace) {
      debugPrintStack(
        label: 'Error moving to trash: $e',
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Get all trashed files with their original paths
  Future<List<TrashItem>> listTrash() async {
    final items = <TrashItem>[];

    try {
      final trashDir = Directory(_trashPath);
      if (!await trashDir.exists()) return items;

      await for (final entity in trashDir.list()) {
        if (entity is File && !entity.path.endsWith('.meta')) {
          final metadataPath = '${entity.path}.meta';
          final metadataFile = File(metadataPath);

          String originalPath = entity.path;
          if (await metadataFile.exists()) {
            originalPath = await metadataFile.readAsString();
          }

          items.add(
            TrashItem(
              trashedPath: entity.path,
              originalPath: originalPath,
              trashedAt: DateTime.fromMillisecondsSinceEpoch(
                int.tryParse(
                      entity.path
                          .split(Platform.pathSeparator)
                          .last
                          .split('_')
                          .first,
                    ) ??
                    0,
              ),
              fileSize: await entity.length(),
            ),
          );
        }
      }

      // Sort by date, most recent first
      items.sort((a, b) => b.trashedAt.compareTo(a.trashedAt));
    } catch (e, stackTrace) {
      debugPrintStack(label: 'Error listing trash: $e', stackTrace: stackTrace);
    }

    return items;
  }

  /// Restore file from trash to its original location
  Future<bool> restore(String trashedPath) async {
    try {
      final trashedFile = File(trashedPath);
      if (!await trashedFile.exists()) return false;

      final metadataPath = '$trashedPath.meta';
      final metadataFile = File(metadataPath);

      String originalPath = trashedPath;
      if (await metadataFile.exists()) {
        originalPath = await metadataFile.readAsString();
      }

      // Ensure destination directory exists
      final destDir = File(originalPath).parent;
      if (!await destDir.exists()) {
        await destDir.create(recursive: true);
      }

      // Handle name collision
      var finalPath = originalPath;
      int counter = 1;
      while (await File(finalPath).exists()) {
        final nameparts = originalPath.split('.');
        if (nameparts.length > 1) {
          final ext = nameparts.removeLast();
          final base = nameparts.join('.');
          finalPath = '$base (restored $counter).$ext';
        } else {
          finalPath = '$originalPath (restored $counter)';
        }
        counter++;
      }

      // Restore file
      await trashedFile.rename(finalPath);

      // Clean up metadata
      if (await metadataFile.exists()) {
        await metadataFile.delete();
      }

      debugPrint('Restored from trash: $trashedPath -> $finalPath');
      return true;
    } catch (e, stackTrace) {
      debugPrintStack(
        label: 'Error restoring from trash: $e',
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Permanently delete file from trash
  Future<bool> permanentlyDelete(String trashedPath) async {
    try {
      final file = File(trashedPath);
      if (await file.exists()) {
        await file.delete();
      }

      // Clean up metadata
      final metadataPath = '$trashedPath.meta';
      final metadataFile = File(metadataPath);
      if (await metadataFile.exists()) {
        await metadataFile.delete();
      }

      debugPrint('Permanently deleted: $trashedPath');
      return true;
    } catch (e, stackTrace) {
      debugPrintStack(
        label: 'Error permanently deleting: $e',
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Empty the trash (permanent delete all)
  Future<int> emptyTrash() async {
    int deletedCount = 0;
    try {
      final trashDir = Directory(_trashPath);
      if (!await trashDir.exists()) return 0;

      await for (final entity in trashDir.list()) {
        try {
          if (entity is File) {
            await entity.delete();
            deletedCount++;
          }
        } catch (_) {
          // Skip individual file errors
        }
      }

      debugPrint('Emptied trash: deleted $deletedCount files');
    } catch (e, stackTrace) {
      debugPrintStack(
        label: 'Error emptying trash: $e',
        stackTrace: stackTrace,
      );
    }

    return deletedCount;
  }

  /// Get total trash size in bytes
  Future<int> getTrashSize() async {
    int totalSize = 0;

    try {
      final trashDir = Directory(_trashPath);
      if (!await trashDir.exists()) return 0;

      await for (final entity in trashDir.list()) {
        if (entity is File && !entity.path.endsWith('.meta')) {
          totalSize += await entity.length();
        }
      }
    } catch (e) {
      debugPrint('Error calculating trash size: $e');
    }

    return totalSize;
  }
}

class TrashItem {
  final String trashedPath;
  final String originalPath;
  final DateTime trashedAt;
  final int fileSize;

  TrashItem({
    required this.trashedPath,
    required this.originalPath,
    required this.trashedAt,
    required this.fileSize,
  });

  String get fileName => originalPath.split(Platform.pathSeparator).last;

  String get fileSizeDisplay {
    if (fileSize < 1024) {
      return '$fileSize B';
    }
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    }
    if (fileSize < 1024 * 1024 * 1024) {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
