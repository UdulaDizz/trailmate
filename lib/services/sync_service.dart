import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';

class SyncService {
  static final SyncService instance = SyncService._internal();
  SyncService._internal();

  StreamSubscription? _connectivitySubscription;
  bool _isSyncing = false;

  // --- CLOUDINARY CONFIGURATION ---
  // Replace these with the actual values from your Cloudinary Dashboard!
  final String cloudName = 'dglls21dk';
  final String uploadPreset = 'trailmate_hikes';

  void startListening() {
    _syncUnsyncedData();

    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) async {
      final prefs = await SharedPreferences.getInstance();
      bool wifiOnly = prefs.getBool('syncWifiOnly') ?? false;

      if (wifiOnly && !results.contains(ConnectivityResult.wifi)) {
        print("Sync Paused: Waiting for Wi-Fi connection...");
        return;
      }

      if (results.contains(ConnectivityResult.mobile) ||
          results.contains(ConnectivityResult.wifi)) {
        _syncUnsyncedData();
      }
    });
  }

  void stopListening() {
    _connectivitySubscription?.cancel();
  }

  // Helper method to push the image to Cloudinary
  Future<String?> _uploadImageToCloudinary(File imageFile) async {
    try {
      final url =
          Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonMap = json.decode(responseData);
        return jsonMap[
            'secure_url']; //  public link to the image!
      } else {
        print("Cloudinary Upload Failed: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Cloudinary Exception: $e");
      return null;
    }
  }

  Future<void> _syncUnsyncedData() async {
    if (_isSyncing) return;
    _isSyncing = true;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _isSyncing = false;
      return;
    }

    try {
      final unsyncedHikes = await DatabaseHelper.instance.getUnsyncedHikes();
      final firestore = FirebaseFirestore.instance;

      for (var hike in unsyncedHikes) {
        // 1. Create the text document for the Hike in Firestore
        DocumentReference hikeDocRef = await firestore
            .collection('users')
            .doc(user.uid)
            .collection('hikes')
            .add({
          'title': hike['title'],
          'distance': hike['distance'],
          'elevation': hike['elevation'],
          'duration': hike['duration'],
          'date': hike['date'],
          'synced_at': FieldValue.serverTimestamp(),
        });

        // 2. Fetch all local photos attached to this specific hike
        final localPhotos =
            await DatabaseHelper.instance.getPhotosForHike(hike['id']);

        // 3. Loop through each photo, upload to Cloudinary, and save link to Firestore
        for (var photo in localPhotos) {
          File imageFile = File(photo['image_path']);

          if (await imageFile.exists()) {
            print("Uploading photo to Cloudinary...");
            String? cloudUrl = await _uploadImageToCloudinary(imageFile);

            if (cloudUrl != null) {
              await hikeDocRef.collection('photos').add({
                'caption': photo['caption'],
                'latitude': photo['latitude'],
                'longitude': photo['longitude'],
                'image_url': cloudUrl,
                'synced_at': FieldValue.serverTimestamp(),
              });
            }
          }
        }

        // 4. Mark the hike as fully synced locally so it never uploads twice
        await DatabaseHelper.instance.markHikeSynced(hike['id'], hikeDocRef.id);
        print("Successfully synced hike and photos: ${hike['title']}");
      }
    } catch (e) {
      print("Sync Error: $e");
    } finally {
      _isSyncing = false;
    }
  }
}
