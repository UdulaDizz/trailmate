import 'dart:io';
import 'package:flutter/material.dart';
import '../models/app_colors.dart';
import '../database/database_helper.dart';
import 'album_detail_screen.dart';

class AlbumsScreen extends StatefulWidget {
  const AlbumsScreen({super.key});

  @override
  State<AlbumsScreen> createState() => _AlbumsScreenState();
}

class _AlbumsScreenState extends State<AlbumsScreen> {
  List<Map<String, dynamic>> _albums = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlbums();
  }

  Future<void> _loadAlbums() async {
    final albumsData = await DatabaseHelper.instance.getAlbumsSummary();
    if(mounted) {
      setState(() {
        _albums = albumsData;
        _isLoading = false;
      });
    }
  }

  void _confirmDelete(int hikeId, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text("Delete Hike?", style: TextStyle(color: Colors.redAccent)),
        content: Text("Are you sure you want to delete '$title'? This removes the route and all wayfinding photos.", style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(context);
              await DatabaseHelper.instance.deleteHike(hikeId);
              _loadAlbums(); 
            },
            child: const Text("DELETE"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Visual Wayfinding", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                IconButton(
                  icon: const Icon(Icons.refresh, color: AppColors.primary),
                  onPressed: _loadAlbums,
                )
              ],
            ),
            const Text("Your captured landmarks and anchors", style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _albums.isEmpty
                  ? const Center(child: Text("No hikes saved yet.\nGo track a route to create an album!", textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)))
                  : GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: _albums.length,
                      itemBuilder: (context, index) {
                        final album = _albums[index];
                        final bool hasCover = album['cover_image'] != null;

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AlbumDetailScreen(hikeId: album['hike_id'], albumTitle: album['title']),
                              ),
                            ).then((_) => _loadAlbums());
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                            ),
                            child: Stack(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                        child: hasCover 
                                          ? Image.file(
                                              File(album['cover_image']),
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.white54, size: 50),
                                            )
                                          : Container(
                                              color: Colors.black26,
                                              child: const Icon(Icons.landscape, size: 50, color: AppColors.textSecondary),
                                            ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(album['title'], maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                          const SizedBox(height: 4),
                                          Text("${album['photo_count']} Anchors", style: const TextStyle(fontSize: 12, color: AppColors.primary)),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                                Positioned(
                                  top: 4, right: 4,
                                  child: PopupMenuButton<String>(
                                    icon: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(20)),
                                      child: const Icon(Icons.more_vert, color: Colors.white, size: 20),
                                    ),
                                    color: AppColors.surface,
                                    onSelected: (value) {
                                      if (value == 'delete') _confirmDelete(album['hike_id'], album['title']);
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                            SizedBox(width: 8),
                                            Text('Delete Hike', style: TextStyle(color: Colors.redAccent)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            )
          ],
        ),
      ),
    );
  }
}