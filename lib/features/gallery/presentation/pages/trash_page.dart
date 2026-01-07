import 'package:flutter/material.dart';
import 'package:anas_space/ui/widgets/extruded_surface.dart';
import '../../data/gallery_service.dart';
import '../../../../core/services/trash_service.dart';
import '../../../../ui/widgets/stone_theme_switch.dart';
import '../../../../ui/helpers/shadow_helpers.dart';

class TrashPage extends StatefulWidget {
  final GalleryService galleryService;
  const TrashPage({super.key, required this.galleryService});

  @override
  State<TrashPage> createState() => _TrashPageState();
}

class _TrashPageState extends State<TrashPage> {
  late Future<List<TrashItem>> _trashItems;

  @override
  void initState() {
    super.initState();
    _loadTrash();
  }

  void _loadTrash() {
    _trashItems =
        widget.galleryService.trashService?.listTrash() ?? Future.value([]);
  }

  Future<void> _restoreItem(TrashItem item) async {
    try {
      await widget.galleryService.trashService?.restore(item.trashedPath);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Restored: ${item.fileName}")));
        setState(() => _loadTrash());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error restoring: $e")));
      }
    }
  }

  Future<void> _deleteItem(TrashItem item) async {
    final cs = Theme.of(context).colorScheme;
    final confirm = await showDialog<bool>(
      context: context,
      barrierColor: cs.scrim.withValues(alpha: 0.55),
      builder: (ctx) => AlertDialog(
        backgroundColor: cs.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: cs.outlineVariant, width: 1),
        ),
        title: Text(
          "PERMANENTLY DELETE?",
          style: TextStyle(
            color: cs.onSurface,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        content: Text(
          "Delete ${item.fileName} permanently? This cannot be undone.",
          style: TextStyle(color: cs.onSurface.withValues(alpha: 0.75)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: cs.errorContainer,
              foregroundColor: cs.onErrorContainer,
            ),
            child: const Text(
              "Delete",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await widget.galleryService.trashService?.permanentlyDelete(
          item.trashedPath,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Permanently deleted: ${item.fileName}")),
          );
          setState(() => _loadTrash());
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Error deleting: $e")));
        }
      }
    }
  }

  Future<void> _emptyTrash() async {
    final cs = Theme.of(context).colorScheme;
    final confirm = await showDialog<bool>(
      context: context,
      barrierColor: cs.scrim.withValues(alpha: 0.55),
      builder: (ctx) => AlertDialog(
        backgroundColor: cs.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: cs.outlineVariant, width: 1),
        ),
        title: Text(
          "EMPTY TRASH?",
          style: TextStyle(
            color: cs.onSurface,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        content: Text(
          "Permanently delete all items in trash? This cannot be undone.",
          style: TextStyle(color: cs.onSurface.withValues(alpha: 0.75)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: cs.errorContainer,
              foregroundColor: cs.onErrorContainer,
            ),
            child: const Text(
              "Empty",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final count =
            await widget.galleryService.trashService?.emptyTrash() ?? 0;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Permanently deleted $count items")),
          );
          setState(() => _loadTrash());
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Error emptying trash: $e")));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bool isDesktop = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        actions: const [StoneThemeSwitch()],
        title: Text(
          "TRASH BIN",
          style: TextStyle(
            color: cs.onSurface,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            thickness: 1,
            color: cs.outlineVariant.withValues(alpha: 0.8),
          ),
        ),
      ),
      body: FutureBuilder<List<TrashItem>>(
        future: _trashItems,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: cs.error),
                  const SizedBox(height: 16),
                  Text(
                    "Error loading trash: ${snapshot.error}",
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.75),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.delete_outline,
                    size: 80,
                    color: cs.onSurface.withValues(alpha: 0.35),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "TRASH IS EMPTY",
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.6),
                      fontSize: 16,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.surface,
                  border: Border(
                    bottom: BorderSide(
                      color: cs.outlineVariant.withValues(alpha: 0.8),
                      width: 1.5,
                    ),
                  ),
                ),
                child: FutureBuilder<String>(
                  future: _getTrashSize(),
                  builder: (context, snapshot) {
                    final size = snapshot.data ?? "Calculating...";
                    return Row(
                      children: [
                        Icon(
                          Icons.storage,
                          color: cs.onSurface.withValues(alpha: 0.8),
                          size: isDesktop ? 20 : 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "TOTAL SIZE: $size",
                          style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.8),
                            fontSize: isDesktop ? 14 : 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            fontFamily: 'Courier',
                          ),
                        ),
                        const Spacer(),
                        Text(
                          "${items.length} ITEMS",
                          style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.75),
                            fontSize: isDesktop ? 14 : 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            fontFamily: 'Courier',
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 16 : 8,
                    vertical: 8,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 8 : 4,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        border: Border.all(
                          color: cs.outlineVariant.withValues(alpha: 0.75),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          subtleBoxShadow(
                            context,
                            color: cs.shadow,
                            lightAlpha: 0.15,
                            darkAlpha: 0.06,
                            lightBlur: 12,
                            darkBlur: 5,
                            lightOffset: const Offset(0, 8),
                            darkOffset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: isDesktop ? 16 : 12,
                          vertical: isDesktop ? 8 : 4,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: cs.outlineVariant.withValues(alpha: 0.85),
                              width: 1,
                            ),
                            color: cs.surfaceContainerHighest,
                          ),
                          child: Icon(
                            Icons.insert_drive_file,
                            color: cs.onSurface.withValues(alpha: 0.8),
                            size: isDesktop ? 24 : 20,
                          ),
                        ),
                        title: Text(
                          item.fileName,
                          style: TextStyle(
                            color: cs.onSurface,
                            fontSize: isDesktop ? 16 : 14,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          "${item.fileSizeDisplay} • ${_formatDate(item.trashedAt)}",
                          style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.65),
                            fontSize: isDesktop ? 12 : 11,
                            fontFamily: 'Courier',
                          ),
                        ),
                        trailing: PopupMenuButton(
                          color: cs.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: cs.outlineVariant.withValues(alpha: 0.85),
                              width: 1.5,
                            ),
                          ),
                          icon: Icon(
                            Icons.more_vert,
                            color: cs.onSurface.withValues(alpha: 0.8),
                            size: isDesktop ? 24 : 20,
                          ),
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.restore,
                                    color: cs.onSurface.withValues(alpha: 0.8),
                                    size: isDesktop ? 20 : 18,
                                  ),
                                  SizedBox(width: isDesktop ? 12 : 8),
                                  Text(
                                    "Restore",
                                    style: TextStyle(
                                      color: cs.onSurface,
                                      fontSize: isDesktop ? 14 : 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () => _restoreItem(item),
                            ),
                            PopupMenuItem(
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete_forever,
                                    color: cs.error,
                                    size: isDesktop ? 20 : 18,
                                  ),
                                  SizedBox(width: isDesktop ? 12 : 8),
                                  Text(
                                    "Delete",
                                    style: TextStyle(
                                      color: cs.error,
                                      fontSize: isDesktop ? 14 : 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () => _deleteItem(item),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (items.isNotEmpty)
                Container(
                  padding: EdgeInsets.all(isDesktop ? 20 : 16),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: cs.outlineVariant.withValues(alpha: 0.8),
                        width: 1.5,
                      ),
                    ),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ExtrudedSurface(
                      onTap: _emptyTrash,
                      radius: 12,
                      depth: 10,
                      padding: EdgeInsets.symmetric(
                        vertical: isDesktop ? 16 : 12,
                        horizontal: isDesktop ? 24 : 16,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.delete_forever,
                            size: isDesktop ? 24 : 20,
                            color: cs.error,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "EMPTY TRASH",
                            style: TextStyle(
                              color: cs.error,
                              fontSize: isDesktop ? 16 : 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    if (diff.inDays < 30) return "${diff.inDays}d ago";
    return "${date.month}/${date.day}/${date.year}";
  }

  Future<String> _getTrashSize() async {
    final bytes = await widget.galleryService.trashService?.getTrashSize() ?? 0;
    if (bytes < 1024) {
      return "$bytes B";
    }
    if (bytes < 1024 * 1024) {
      return "${(bytes / 1024).toStringAsFixed(2)} KB";
    }
    if (bytes < 1024 * 1024 * 1024) {
      return "${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB";
    }
    return "${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB";
  }
}
