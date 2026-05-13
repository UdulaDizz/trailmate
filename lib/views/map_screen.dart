import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../controllers/location_controller.dart';
import '../models/app_colors.dart';
import 'widgets/trailmate_logo.dart';

class TrailMapScreen extends StatefulWidget {
  const TrailMapScreen({super.key});

  @override
  State<TrailMapScreen> createState() => _TrailMapScreenState();
}

class _TrailMapScreenState extends State<TrailMapScreen> {
  final LocationController _controller = LocationController();
  final ImagePicker _picker = ImagePicker();

  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _controller.onPhotoAlert = _showWayfindingAlert;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showStartHikeDialog() {
    TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text("Start New Hike",
            style: TextStyle(color: AppColors.primary)),
        content: TextField(
          controller: nameController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Enter hike name (e.g., Ella Rock)",
            hintStyle: TextStyle(color: Colors.white54),
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.primary)),
            focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.primary)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCEL",
                  style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black),
            onPressed: () async {
              Navigator.pop(context);
              String hikeName = nameController.text.trim().isEmpty
                  ? "New Trail Hike"
                  : nameController.text.trim();
              await _controller.startNewHike(hikeName);
            },
            child: const Text("START"),
          )
        ],
      ),
    );
  }

  void _showWayfindingAlert() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text("Visual Wayfinding",
            style: TextStyle(color: AppColors.primary)),
        content: const Text(
            "You have traveled 100 meters. Capture a landmark to secure your return route.",
            style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("SKIP",
                  style: TextStyle(color: AppColors.textSecondary))),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black),
            onPressed: () {
              Navigator.pop(context);
              _captureWayfindingPhoto();
            },
            icon: const Icon(Icons.camera_alt),
            label: const Text("TAKE PHOTO"),
          )
        ],
      ),
    );
  }

  Future<void> _captureWayfindingPhoto() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      final directory = await getApplicationDocumentsDirectory();
      final String fileName =
          'waypoint_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String savedPath = path.join(directory.path, fileName);
      await File(photo.path).copy(savedPath);

      await _controller.savePhotoToAlbum(savedPath,
          'Wayfinding anchor at ${_controller.distance.toStringAsFixed(2)}km');
      _controller.addWaypoint(_controller.currentPos,
          const Icon(Icons.linked_camera, color: Colors.amber, size: 30));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Visual anchor saved!"),
            backgroundColor: AppColors.primary));
      }
    }
  }

  void _startDownloadSimulation() {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        _downloadProgress += 0.05;
        if (_downloadProgress >= 1.0) {
          timer.cancel();
          _isDownloading = false;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Map Region cached for offline use."),
                backgroundColor: AppColors.primary),
          );
        }
      });
    });
  }

  // --- NEW: DYNAMIC BUTTON BUILDER ---
  Widget _buildDynamicHikeButton() {
    if (_controller.isLoadingLocation) {
      return ElevatedButton.icon(
        onPressed: null,
        icon: const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2)),
        label: const Text("WAITING FOR GPS"),
      );
    }

    // Phase 1: Not Started
    if (_controller.activeHikeId == null) {
      return ElevatedButton.icon(
        onPressed: _showStartHikeDialog,
        style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 16)),
        icon: const Icon(Icons.play_arrow),
        label: const Text("START HIKE",
            style: TextStyle(fontWeight: FontWeight.bold)),
      );
    }
    // Phase 2: Hiking Forward
    else if (!_controller.hasReachedDestination) {
      return ElevatedButton.icon(
        onPressed: _controller.reachDestination,
        style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 16)),
        icon: const Icon(Icons.flag),
        label: const Text("DESTINATION REACHED",
            style: TextStyle(fontWeight: FontWeight.bold)),
      );
    }
    // Phase 3: Resting at Destination
    else if (!_controller.isReturning) {
      return ElevatedButton.icon(
        onPressed: _controller.startReturnJourney,
        style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16)),
        icon: const Icon(Icons.directions_walk),
        label: const Text("RETURN TO START",
            style: TextStyle(fontWeight: FontWeight.bold)),
      );
    }
    // Phase 4: Walking Back
    else {
      return ElevatedButton.icon(
        onPressed: () async {
          await _controller.endHike();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text("Hike saved and synced to cloud!"),
                backgroundColor: AppColors.primary));
          }
        },
        style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16)),
        icon: const Icon(Icons.stop),
        label: const Text("END HIKE & SAVE",
            style: TextStyle(fontWeight: FontWeight.bold)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          return Scaffold(
            body: Stack(
              children: [
                if (_controller.isLoadingLocation)
                  const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary))
                else
                  FlutterMap(
                    mapController: _controller.mapController,
                    options: MapOptions(
                      initialCenter: _controller.currentPos,
                      initialZoom: 16.0,
                      onTap: (_, point) => _controller.addWaypoint(
                          point,
                          const Icon(Icons.location_on,
                              color: AppColors.primary, size: 30)),
                    ),
                    children: [
                      TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.trailmate.app'),
                      PolylineLayer(polylines: [
                        Polyline(
                            points: _controller.pathHistory,
                            strokeWidth: 5.0,
                            color: AppColors.primary)
                      ]),
                      MarkerLayer(markers: [
                        Marker(
                          point: _controller.currentPos,
                          width: 40,
                          height: 40,
                          child: Container(
                            decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 3)),
                            child: const Icon(Icons.navigation,
                                color: Colors.white, size: 20),
                          ),
                        ),
                        ..._controller.waypoints,
                      ]),
                    ],
                  ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
                    decoration: const BoxDecoration(
                        gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.black87, Colors.transparent])),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const TrailMateLogo(size: 35),
                        IconButton(
                            icon: const Icon(Icons.cloud_download_outlined,
                                color: AppColors.primary, size: 30),
                            onPressed: _startDownloadSimulation)
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 110,
                  left: 16,
                  right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildHUDCard("DIST",
                          "${_controller.distance.toStringAsFixed(2)} km"),
                      _buildHUDCard("ELEV",
                          "${_controller.altitude.toStringAsFixed(0)} m"),
                      _buildHUDCard("TIME",
                          _controller.formatTime(_controller.durationSeconds)),
                    ],
                  ),
                ),
                if (_isDownloading)
                  Center(
                    child: Container(
                      width: 200,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text("Caching Region...",
                              style: TextStyle(color: Colors.white)),
                          const SizedBox(height: 15),
                          LinearProgressIndicator(
                              value: _downloadProgress,
                              color: AppColors.primary),
                        ],
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      // NEW: Changes to bright red if they wander off the trail!
                      color: _controller.isOffRouteWarning
                          ? Colors.redAccent.withValues(alpha: 0.95)
                          : AppColors.surface.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(20),
                      border: _controller.isOffRouteWarning
                          ? Border.all(color: Colors.white, width: 2)
                          : null,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_controller.isOffRouteWarning)
                              const Padding(
                                padding: EdgeInsets.only(right: 8.0),
                                child: Icon(Icons.warning_amber_rounded,
                                    color: Colors.white, size: 24),
                              ),
                            Text(_controller.navInstruction,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.5)),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.my_location,
                                    color: Colors.white),
                                onPressed: () => _controller.mapController
                                    .move(_controller.currentPos, 16.0),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(child: _buildDynamicHikeButton()),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        });
  }

  Widget _buildHUDCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3))),
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
