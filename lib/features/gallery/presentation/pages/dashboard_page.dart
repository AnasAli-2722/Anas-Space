import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:anas_space/ui/widgets/extruded_surface.dart';
import 'package:anas_space/ui/theme/cyberpunk_theme.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:path_provider/path_provider.dart';
import '../../domain/unified_asset.dart';
import '../../data/gallery_service.dart';
import '../widgets/asset_tile.dart';
import '../../presentation/widgets/cinematic_background.dart';
import '../../presentation/widgets/glass_app_bar.dart';
import '../constants/ui_constants.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../../../ui/widgets/stone_theme_switch.dart';

import '../../../sync/presentation/pages/sync_page.dart';

import 'albums_page.dart';
import 'trash_page.dart';

class DashboardPage extends StatefulWidget {
  final GalleryService galleryService;

  const DashboardPage({super.key, required this.galleryService});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final GalleryService _galleryService;
  final SecureStorageService _secureStorage = SecureStorageService();

  List<UnifiedAsset> _gallery = [];
  Map<String, List<UnifiedAsset>> _groupedGallery = {};

  bool _isLoading = true;
  String _status = "Ready";

  bool _pinIsSet = false;
  String _lockerPath = "";
  bool _isLockerMode = false;

  final Set<String> _selectedIds = {};
  bool _isSelectionMode = false;
  final bool _isMobile = Platform.isAndroid || Platform.isIOS;

  bool? _androidMoveToTrashSupported;

  Future<bool> _tryAndroidMoveToTrash(AssetEntity asset) async {
    if (!Platform.isAndroid) return false;
    if (_androidMoveToTrashSupported == false) return false;

    try {
      final dynamic editor = PhotoManager.editor;
      final dynamic result = await (editor as dynamic).moveToTrash([asset]);

      final ok = result is bool ? result : result != null;
      if (ok) _androidMoveToTrashSupported = true;
      return ok;
    } catch (e, st) {
      if (e is NoSuchMethodError || e is MissingPluginException) {
        _androidMoveToTrashSupported = false;
      }
      debugPrintStack(
        label: 'Android moveToTrash unavailable: $e',
        stackTrace: st,
      );
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _galleryService = widget.galleryService;
    _bootSystem();
  }

  Future<void> _bootSystem() async {
    _pinIsSet = await _secureStorage.hasPinSet();

    final docDir = await getApplicationDocumentsDirectory();
    final lockerDir = Directory(
      '${docDir.path}${Platform.pathSeparator}.anas_locker',
    );
    if (!await lockerDir.exists()) await lockerDir.create();
    _lockerPath = lockerDir.path;

    // Initialize trash on Windows
    if (Platform.isWindows) {
      final trashDir = Directory(
        '${docDir.path}${Platform.pathSeparator}.anas_trash',
      );
      _galleryService.initTrash(trashDir.path);
      await _galleryService.trashService?.init();
    }

    await _refreshGallery();
  }

  Future<void> _refreshGallery() async {
    if (!mounted) return;

    List<UnifiedAsset> newAssets = [];
    await Future.microtask(() async {
      if (_isLockerMode) {
        newAssets = await _galleryService.scanLocker(_lockerPath);
      } else {
        if (_isMobile) {
          newAssets = await _galleryService.scanMobileGallery();
        } else {
          newAssets = await _galleryService.scanDesktopGallery();
        }
      }
    });

    _updateMasterGallery(local: newAssets);
  }

  void _updateMasterGallery({List<UnifiedAsset>? local}) {
    if (local != null) _gallery = local;

    _gallery.sort((a, b) => b.dateModified.compareTo(a.dateModified));
    _groupedGallery = _groupAssets(_gallery);

    if (mounted) {
      setState(() {
        _isLoading = false;
        _status = _isLockerMode
            ? "Locker Mode"
            : "Ready (${_gallery.length} Items)";
      });
    }
  }

  Map<String, List<UnifiedAsset>> _groupAssets(List<UnifiedAsset> assets) {
    Map<String, List<UnifiedAsset>> groups = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (var asset in assets) {
      final date = asset.dateModified;
      final assetDate = DateTime(date.year, date.month, date.day);

      String header;
      if (assetDate == today) {
        header = "Today";
      } else if (assetDate == yesterday) {
        header = "Yesterday";
      } else if (date.year == now.year) {
        // Same year: "October", "September"
        header = DateFormat('MMMM').format(date);
      } else {
        // Older: "2023", "2022"
        header = DateFormat('y').format(date);
      }

      if (!groups.containsKey(header)) {
        groups[header] = [];
      }
      groups[header]!.add(asset);
    }
    return groups;
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
      _isSelectionMode = _selectedIds.isNotEmpty;
    });
  }

  Future<void> _handleLockerAccess() async {
    if (!_pinIsSet) {
      await _showPinDialog(isSetup: true);
    } else {
      await _showPinDialog(isSetup: false);
    }
  }

  Future<void> _showPinDialog({required bool isSetup}) async {
    String input = "";
    await showDialog(
      context: context,
      barrierColor: CyberpunkTheme.darkBg.withValues(alpha: 0.8),
      builder: (ctx) => AlertDialog(
        backgroundColor: CyberpunkTheme.darkBgSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: CyberpunkTheme.neonMagenta.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        title: ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [CyberpunkTheme.neonCyan, CyberpunkTheme.neonMagenta],
            ).createShader(bounds);
          },
          child: Text(
            isSetup ? "SET PIN" : "ENTER PIN",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
            ),
          ),
        ),
        content: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                CyberpunkTheme.neonMagenta.withValues(alpha: 0.1),
                Colors.transparent,
              ],
            ),
            border: Border.all(
              color: CyberpunkTheme.neonMagenta.withValues(alpha: 0.5),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            autofocus: true,
            obscureText: true,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: CyberpunkTheme.neonMagenta,
              fontSize: UIConstants.pinInputFontSize,
              letterSpacing: UIConstants.pinInputLetterSpacing,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: "••••",
              hintStyle: TextStyle(
                color: CyberpunkTheme.neonMagenta.withValues(alpha: 0.3),
              ),
            ),
            onChanged: (v) => input = v,
            onSubmitted: (_) {
              Navigator.pop(ctx);
              _processPin(input, isSetup);
            },
          ),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: CyberpunkTheme.neonCyan,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _processPin(input, isSetup);
            },
            child: const Text(
              "OK",
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0),
            ),
          ),
        ],
      ),
    );
  }

  void _processPin(String input, bool isSetup) async {
    // Validate PIN length (minimum 4 digits, maximum 10)
    if (input.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("PIN cannot be empty")));
      return;
    }

    if (input.length < UIConstants.pinMinLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "PIN must be at least ${UIConstants.pinMinLength} characters",
          ),
        ),
      );
      return;
    }

    if (input.length > UIConstants.pinMaxLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "PIN must not exceed ${UIConstants.pinMaxLength} characters",
          ),
        ),
      );
      return;
    }

    if (isSetup) {
      final success = await _secureStorage.setPin(input);
      if (success) {
        setState(() => _pinIsSet = true);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("PIN set successfully")));
        _toggleLockerMode();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error setting PIN. Try again.")),
        );
      }
    } else {
      final isValid = await _secureStorage.verifyPin(input);
      if (isValid) {
        _toggleLockerMode();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Incorrect PIN")));
      }
    }
  }

  void _toggleLockerMode() {
    setState(() {
      _isLockerMode = !_isLockerMode;
      _selectedIds.clear();
      _isSelectionMode = false;
    });
    setState(() => _isLoading = true);
    _refreshGallery();
  }

  Future<void> _deleteSelected() async {
    final count = _selectedIds.length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: UIConstants.dialogSecondaryBackgroundColor,
        title: const Text("Delete?", style: TextStyle(color: Colors.white)),
        content: Text(
          Platform.isWindows || Platform.isAndroid
              ? "Move $count items to Trash?"
              : "Delete $count items permanently?",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final Map<String, UnifiedAsset> assetsById = {
        for (final a in _gallery) a.id: a,
      };
      int deletedCount = 0;
      for (final id in _selectedIds.toList()) {
        try {
          final asset = assetsById[id];

          final localPath = asset?.localFile?.path;
          if (localPath != null) {
            final f = File(localPath);
            if (!await f.exists()) continue;

            if (Platform.isWindows && _galleryService.trashService != null) {
              final trashedPath = await _galleryService.trashService!
                  .moveToTrash(localPath);
              if (trashedPath != null) deletedCount++;
            } else {
              await f.delete();
              deletedCount++;
            }
            continue;
          }

          final deviceAsset = asset?.deviceAsset;
          if (deviceAsset != null) {
            final permission = await PhotoManager.requestPermissionExtend();
            if (!permission.isAuth) continue;

            final movedToTrash = await _tryAndroidMoveToTrash(deviceAsset);
            if (movedToTrash) {
              deletedCount++;
              continue;
            }

            try {
              final deletedIds = await PhotoManager.editor.deleteWithIds([
                deviceAsset.id,
              ]);
              if (deletedIds.contains(deviceAsset.id)) deletedCount++;
            } catch (e, st) {
              debugPrintStack(
                label: 'Error deleting device asset ${deviceAsset.id}: $e',
                stackTrace: st,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting item: $e')),
                );
              }
            }
            continue;
          }

          // Fallback: try treating id as a path
          final fallback = File(id);
          if (await fallback.exists()) {
            if (Platform.isWindows && _galleryService.trashService != null) {
              final trashedPath = await _galleryService.trashService!
                  .moveToTrash(id);
              if (trashedPath != null) deletedCount++;
            } else {
              await fallback.delete();
              deletedCount++;
            }
          }
        } catch (e, stackTrace) {
          debugPrintStack(
            label: "Error deleting file $id: $e",
            stackTrace: stackTrace,
          );
        }
      }
      _selectedIds.clear();
      _isSelectionMode = false;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Platform.isWindows || Platform.isAndroid
                  ? "Moved $deletedCount items to Trash"
                  : "Deleted $deletedCount items",
            ),
          ),
        );
      }

      await _refreshGallery();
    }
  }

  Future<void> _moveSelectedFiles() async {
    if (!_isLockerMode && !_pinIsSet) {
      await _showPinDialog(isSetup: true);
      if (!_pinIsSet) return;
    }

    final isHiding = !_isLockerMode;
    String dest = isHiding
        ? _lockerPath
        : (_isMobile
              ? ""
              : '${Platform.environment['USERPROFILE']}${Platform.pathSeparator}Downloads');
    if (!isHiding && _isMobile) return;

    int count = 0;
    for (String id in _selectedIds) {
      if (!_isMobile && File(id).existsSync()) {
        try {
          final f = File(id);
          final name = f.path.split(Platform.pathSeparator).last;
          final newPath = '$dest${Platform.pathSeparator}$name';
          await f.copy(newPath);
          if (await File(newPath).exists()) {
            await f.delete();
            count++;
            debugPrint("Moved file: $id -> $newPath");
          }
        } catch (e, stackTrace) {
          debugPrintStack(
            label: "Error moving file $id: $e",
            stackTrace: stackTrace,
          );
        }
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isHiding
                ? "Hidden $count items"
                : "Restored $count items to Downloads",
          ),
        ),
      );
    }
    _selectedIds.clear();
    _isSelectionMode = false;
    await _refreshGallery();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      body: CinematicBackground(
        child: Stack(
          children: [
            Column(
              children: [
                GlassAppBar(
                  title: _isLockerMode ? "PRIVATE LOCKER" : "ANAS SPACE",
                  subtitle: _status,
                  leading: _isLockerMode
                      ? IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: _toggleLockerMode,
                        )
                      : null,
                  actions: _isSelectionMode
                      ? [
                          const StoneThemeSwitch(),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _selectedIds.clear();
                                _isSelectionMode = false;
                              });
                            },
                            child: const Text(
                              "CANCEL",
                              style: TextStyle(color: Colors.redAccent),
                            ),
                          ),
                        ]
                      : [
                          const StoneThemeSwitch(),
                          _NavBarIcon(
                            icon: Icons.album_outlined,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    AlbumsPage(galleryService: _galleryService),
                              ),
                            ),
                          ),
                          _NavBarIcon(
                            icon: Icons.delete_outline,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    TrashPage(galleryService: _galleryService),
                              ),
                            ),
                          ),
                          _NavBarIcon(
                            icon: Icons.wifi_tethering,
                            color: Colors.blueAccent,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SyncPage(),
                              ),
                            ),
                          ),
                          _NavBarIcon(
                            icon: _isLockerMode
                                ? Icons.lock_open
                                : Icons.lock_outline,
                            color: Colors.purpleAccent,
                            onTap: _handleLockerAccess,
                          ),
                        ],
                ),

                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                          onRefresh: _refreshGallery,
                          color: Theme.of(context).colorScheme.onSurface,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surface,
                          child: CustomScrollView(
                            physics: const BouncingScrollPhysics(),
                            slivers: [
                              for (var entry in _groupedGallery.entries) ...[
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: UIConstants.sectionPadding,
                                    child: Text(
                                      entry.key.toUpperCase(),
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.8),
                                        fontSize:
                                            UIConstants.sectionHeaderFontSize,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                SliverPadding(
                                  padding: UIConstants.gridPadding,
                                  sliver: SliverGrid(
                                    delegate: SliverChildBuilderDelegate((
                                      ctx,
                                      i,
                                    ) {
                                      final asset = entry.value[i];
                                      return AssetTile(
                                        asset: asset,
                                        isSelected: _selectedIds.contains(
                                          asset.id,
                                        ),
                                        isSelectionMode: _isSelectionMode,
                                        onSelect: () =>
                                            _toggleSelection(asset.id),
                                      );
                                    }, childCount: entry.value.length),
                                    gridDelegate:
                                        SliverGridDelegateWithMaxCrossAxisExtent(
                                          maxCrossAxisExtent: _isMobile
                                              ? UIConstants
                                                    .mobileGridMaxCrossAxisExtent
                                              : UIConstants
                                                    .desktopGridMaxCrossAxisExtent,
                                          mainAxisSpacing:
                                              UIConstants.gridMainAxisSpacing,
                                          crossAxisSpacing:
                                              UIConstants.gridCrossAxisSpacing,
                                          childAspectRatio:
                                              UIConstants.gridChildAspectRatio,
                                        ),
                                  ),
                                ),
                              ],
                              const SliverToBoxAdapter(
                                child: SizedBox(
                                  height: UIConstants.bottomSliverSpacing,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),

            if (_isSelectionMode)
              Positioned(
                bottom: UIConstants.bottomActionBarBottomMargin,
                left: UIConstants.bottomActionBarSideMargin,
                right: UIConstants.bottomActionBarSideMargin,
                child: ExtrudedSurface(
                  radius: UIConstants.bottomActionBarBorderRadius,
                  depth: 10,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: SizedBox(
                    height: UIConstants.bottomActionBarHeight,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ExtrudedIconButton(
                          icon: Icons.delete_forever,
                          onTap: _deleteSelected,
                          iconColor: Theme.of(context).colorScheme.error,
                        ),
                        Container(
                          width: 1.5,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.outlineVariant.withValues(alpha: 0.8),
                          ),
                        ),
                        ExtrudedIconButton(
                          icon: _isLockerMode ? Icons.public : Icons.security,
                          onTap: _moveSelectedFiles,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavBarIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const _NavBarIcon({required this.icon, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final iconColor = (color ?? cs.onSurface).withValues(alpha: 0.85);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: ExtrudedIconButton(
        icon: icon,
        onTap: onTap,
        size: 40,
        radius: 14,
        depth: Theme.of(context).brightness == Brightness.light ? 8 : 6,
        iconColor: iconColor,
      ),
    );
  }
}

class GrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    paint.color = Colors.white.withValues(alpha: 0.02);
    for (int i = 0; i < 1000; i++) {
      final dx = (i * 13.0) % size.width;
      final dy = (i * 7.0) % size.height;
      canvas.drawCircle(Offset(dx, dy), 1, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
