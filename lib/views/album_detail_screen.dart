import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../database/database_helper.dart';
import '../models/app_colors.dart';

class AlbumDetailScreen extends StatefulWidget {
  final int hikeId;
  final String albumTitle;

  const AlbumDetailScreen({super.key, required this.hikeId, required this.albumTitle});

  @override
  State<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends State<AlbumDetailScreen> {
  List<Map<String, dynamic>> _photos = [];
  bool _isLoading = true;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    final photos = await DatabaseHelper.instance.getPhotosForHike(widget.hikeId);
    if (mounted) {
      setState(() {
        _photos = photos;
        _isLoading = false;
      });
    }
  }

  void _showPhotoSourceSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Add Visual Anchor",
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('Take a Photo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(context);
                _addPhotoManually(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.primary),
              title: const Text('Choose from Gallery', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(context);
                _addPhotoManually(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<void> _addPhotoManually(ImageSource source) async {
    final XFile? photo = await _picker.pickImage(source: source);
    
    if (photo != null) {
      setState(() => _isLoading = true);
      
      final directory = await getApplicationDocumentsDirectory();
      final String fileName = 'manual_photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String savedPath = path.join(directory.path, fileName);
      
      await File(photo.path).copy(savedPath);

      await DatabaseHelper.instance.insertPhoto({
        'hike_id': widget.hikeId,
        'image_path': savedPath,
        'caption': 'Added post-hike',
        'latitude': 0.0,
        'longitude': 0.0,
        'is_synced': 0 
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Photo added!"), backgroundColor: AppColors.primary)
        );
      }
      _loadPhotos(); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(widget.albumTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        foregroundColor: Colors.white,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : _photos.isEmpty
          ? const Center(child: Text("No visual anchors captured.\nNext time, take photos when prompted!", textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _photos.length,
              itemBuilder: (context, index) {
                final photo = _photos[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: Image.file(
                          File(photo['image_path']),
                          width: double.infinity,
                          height: 250,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 250,
                            color: Colors.black26,
                            child: const Icon(Icons.broken_image, color: Colors.white54, size: 50),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on, color: AppColors.primary, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                photo['caption'], 
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.black,
        onPressed: _showPhotoSourceSelector, 
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }
}