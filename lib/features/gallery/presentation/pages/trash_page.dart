import 'package:flutter/material.dart';
import '../../data/gallery_service.dart';
import '../../../../core/services/trash_service.dart';

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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          "Permanently Delete?",
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          "Delete ${item.fileName} permanently? This cannot be undone.",
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          "Empty Trash?",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Permanently delete all items in trash? This cannot be undone.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Empty", style: TextStyle(color: Colors.red)),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Trash"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<TrashItem>>(
        future: _trashItems,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error loading trash: ${snapshot.error}",
                style: const TextStyle(color: Colors.white70),
              ),
            );
          }

          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return const Center(
              child: Text(
                "Trash is empty",
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: FutureBuilder<String>(
                  future: _getTrashSize(),
                  builder: (context, snapshot) {
                    final size = snapshot.data ?? "Calculating...";
                    return Text(
                      "Total: $size",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    );
                  },
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Card(
                      color: Colors.grey[900],
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: ListTile(
                        title: Text(
                          item.fileName,
                          style: const TextStyle(color: Colors.white),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          "${item.fileSizeDisplay} • ${_formatDate(item.trashedAt)}",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        trailing: PopupMenuButton(
                          color: Colors.grey[850],
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.restore,
                                    color: Colors.blue,
                                    size: 18,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "Restore",
                                    style: TextStyle(color: Colors.blue),
                                  ),
                                ],
                              ),
                              onTap: () => _restoreItem(item),
                            ),
                            PopupMenuItem(
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                    size: 18,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "Delete",
                                    style: TextStyle(color: Colors.red),
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
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton.icon(
                    onPressed: _emptyTrash,
                    icon: const Icon(Icons.delete_forever),
                    label: const Text("Empty Trash"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[700],
                      foregroundColor: Colors.white,
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
    if (bytes < 1024) return "$bytes B";
    if (bytes < 1024 * 1024) return "${(bytes / 1024).toStringAsFixed(2)} KB";
    if (bytes < 1024 * 1024 * 1024)
      return "${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB";
    return "${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB";
  }
}
