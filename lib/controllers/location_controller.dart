import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import '../models/hike_model.dart';

class LocationController extends ChangeNotifier {
  final MapController mapController = MapController();
  
  bool isTracking = false;
  bool isLoadingLocation = true; 
  String navInstruction = "GPS Ready";
  
  LatLng currentPos = const LatLng(6.9271, 79.8612); 
  List<LatLng> pathHistory = [];
  List<Marker> waypoints = [];
  
  double distance = 0.0;
  double altitude = 0.0;
  int durationSeconds = 0;

  int? activeHikeId;
  String activeHikeName = "";
  double distanceSinceLastPhoto = 0.0;
  VoidCallback? onPhotoAlert;

  bool hasReachedDestination = false;
  bool isReturning = false;
  
  bool isOffRouteWarning = false;

  StreamSubscription<Position>? _positionStream;
  Timer? _stopwatchTimer;

  LocationController() {
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        navInstruction = "Location Services Disabled";
        isLoadingLocation = false;
        notifyListeners();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          navInstruction = "Permissions Denied";
          isLoadingLocation = false;
          notifyListeners();
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5) 
      );
      
      currentPos = LatLng(position.latitude, position.longitude);
      altitude = position.altitude;
    } catch (e) {
      navInstruction = "Using Default Map (GPS Timeout)";
    }

    isLoadingLocation = false;
    notifyListeners();
    mapController.move(currentPos, 16.0);
  }

  Future<void> startNewHike(String hikeName) async {
    activeHikeName = hikeName;
    distance = 0; durationSeconds = 0; distanceSinceLastPhoto = 0;
    hasReachedDestination = false;
    isReturning = false;
    isOffRouteWarning = false;
    pathHistory.clear(); waypoints.clear();
    
    addWaypoint(currentPos, const Icon(Icons.flag_circle, color: Colors.greenAccent, size: 40));

    final initialHike = HikeModel(
      title: activeHikeName,
      distance: 0.0, elevation: 0.0, duration: "00:00",
      date: DateTime.now().toIso8601String(),
    );
    
    activeHikeId = await DatabaseHelper.instance.insertHike(initialHike);
    resumeTracking();
  }

  void resumeTracking() async {
    isTracking = true;
    navInstruction = isReturning ? "Returning: Stay on the blue line!" : "Tracking Active...";
    
    _stopwatchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      durationSeconds++;
      notifyListeners();
    });

    final prefs = await SharedPreferences.getInstance();
    bool highAccuracy = prefs.getBool('highAccuracyGps') ?? true;
    LocationAccuracy accuracy = highAccuracy ? LocationAccuracy.high : LocationAccuracy.medium;

    _positionStream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(accuracy: accuracy, distanceFilter: 3)
    ).listen((Position position) {
      LatLng newPos = LatLng(position.latitude, position.longitude);
      
      if (!isReturning) {
        if (pathHistory.isNotEmpty) {
          double incrementalDist = const Distance().as(LengthUnit.Meter, pathHistory.last, newPos);
          distance += (incrementalDist / 1000); 
          distanceSinceLastPhoto += incrementalDist;

          if (distanceSinceLastPhoto >= 200.0) {
            distanceSinceLastPhoto = 0.0; 
            
            SharedPreferences.getInstance().then((prefs) {
              bool autoPrompts = prefs.getBool('autoWayfindingPrompts') ?? true;
              if (autoPrompts) {
                onPhotoAlert?.call();
              }
            });
          }
        }
        pathHistory.add(newPos);
      } else {
        _checkOffRouteStatus(newPos);
      }
      
      currentPos = newPos;
      altitude = position.altitude;
      mapController.move(currentPos, mapController.camera.zoom);
      notifyListeners();
    });
    notifyListeners();
  }

  void _checkOffRouteStatus(LatLng userLocation) {
    if (pathHistory.isEmpty) return;

    double shortestDistanceToTrail = double.infinity;
    const distanceCalc = Distance();

    for (var breadcrumb in pathHistory) {
      double dist = distanceCalc.as(LengthUnit.Meter, userLocation, breadcrumb);
      if (dist < shortestDistanceToTrail) {
        shortestDistanceToTrail = dist;
      }
    }

    if (shortestDistanceToTrail > 25.0) {
      SharedPreferences.getInstance().then((prefs) {
        bool alertsEnabled = prefs.getBool('offRouteAlerts') ?? true;
        if (alertsEnabled) {
          isOffRouteWarning = true;
          navInstruction = "⚠️ OFF TRAIL! Turn back! ⚠️";
          notifyListeners();
        }
      });
    } else {
      isOffRouteWarning = false;
      navInstruction = "Returning: You are on the right path.";
      notifyListeners();
    }
  }

  void pauseTracking() {
    isTracking = false;
    navInstruction = "Hike Paused";
    _positionStream?.cancel();
    _stopwatchTimer?.cancel();
    notifyListeners();
  }

  void reachDestination() {
    pauseTracking(); 
    hasReachedDestination = true;
    navInstruction = "Destination Reached! Resting...";
    addWaypoint(currentPos, const Icon(Icons.emoji_events, color: Colors.amber, size: 40)); 
    notifyListeners();
  }

  void startReturnJourney() {
    isReturning = true;
    resumeTracking(); 
    notifyListeners();
  }

  Future<void> savePhotoToAlbum(String path, String caption) async {
    if (activeHikeId != null) {
      await DatabaseHelper.instance.insertPhoto({
        'hike_id': activeHikeId,
        'image_path': path,
        'caption': caption,
        'latitude': currentPos.latitude,
        'longitude': currentPos.longitude,
        'is_synced': 0
      });
    }
  }

  Future<void> endHike() async {
    _positionStream?.cancel();
    _stopwatchTimer?.cancel();
    
    if (activeHikeId != null) {
      final finalHike = HikeModel(
        id: activeHikeId,
        title: activeHikeName,
        distance: distance,
        elevation: altitude,
        duration: formatTime(durationSeconds),
        date: DateTime.now().toIso8601String(),
      );
      await DatabaseHelper.instance.updateHike(finalHike);
    }

    isTracking = false;
    navInstruction = "Hike Saved and Synced!";
    activeHikeId = null;
    hasReachedDestination = false;
    isReturning = false;
    isOffRouteWarning = false;
    distance = 0; durationSeconds = 0; distanceSinceLastPhoto = 0;
    pathHistory.clear(); waypoints.clear();
    notifyListeners();
  }

  void addWaypoint(LatLng point, Widget markerIcon) {
    waypoints.add(Marker(point: point, width: 40, height: 40, child: markerIcon));
    notifyListeners();
  }

  String formatTime(int seconds) {
    final min = seconds ~/ 60;
    final sec = seconds % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _stopwatchTimer?.cancel();
    super.dispose();
  }
}