import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/app_colors.dart';
import '../database/database_helper.dart';
import '../services/sync_service.dart';
import 'auth_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  SharedPreferences? _prefs;
  final ImagePicker _picker = ImagePicker();

  String? _profileImagePath;
  bool _highAccuracyGps = true;
  bool _offRouteAlerts = true;
  bool _autoWayfindingPrompts = true;
  bool _syncWifiOnly = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _profileImagePath = _prefs?.getString('profileImagePath');
        _highAccuracyGps = _prefs?.getBool('highAccuracyGps') ?? true;
        _offRouteAlerts = _prefs?.getBool('offRouteAlerts') ?? true;
        _autoWayfindingPrompts = _prefs?.getBool('autoWayfindingPrompts') ?? true;
        _syncWifiOnly = _prefs?.getBool('syncWifiOnly') ?? false;
      });
    }
  }

  void _updatePreference(String key, bool value) {
    setState(() {
      if (key == 'highAccuracyGps') _highAccuracyGps = value;
      if (key == 'offRouteAlerts') _offRouteAlerts = value;
      if (key == 'autoWayfindingPrompts') _autoWayfindingPrompts = value;
      if (key == 'syncWifiOnly') _syncWifiOnly = value;
    });
    _prefs?.setBool(key, value);
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
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                "Update Profile Picture",
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('Take a Photo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(context);
                _updateProfilePicture(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.primary),
              title: const Text('Choose from Gallery', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(context);
                _updateProfilePicture(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<void> _updateProfilePicture(ImageSource source) async {
    final XFile? photo = await _picker.pickImage(source: source);
    
    if (photo != null) {
      final directory = await getApplicationDocumentsDirectory();
      final String fileName = 'profile_pic_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String savedPath = path.join(directory.path, fileName);
      
      await File(photo.path).copy(savedPath);

      setState(() {
        _profileImagePath = savedPath;
      });
      
      await _prefs?.setString('profileImagePath', savedPath);
    }
  }

  Future<void> _handleLogout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text("Log Out", style: TextStyle(color: Colors.white)),
        content: const Text("Are you sure you want to log out? Unsynced hikes will remain on your device.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL", style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black),
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AuthScreen()));
              }
            },
            child: const Text("LOG OUT"),
          )
        ],
      ),
    );
  }

  Future<void> _handleClearData() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text("Clear Local Data", style: TextStyle(color: Colors.redAccent)),
        content: const Text("This will permanently delete all offline maps and unsynced hikes from your phone. This cannot be undone.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL", style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(context);
              await DatabaseHelper.instance.clearAllData();
              
              await _prefs?.remove('profileImagePath');
              setState(() => _profileImagePath = null);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("All local storage cleared."), backgroundColor: Colors.redAccent));
              }
            },
            child: const Text("DELETE DATA"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userEmail = user?.email ?? "Not logged in";

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          const Text("Settings", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 24),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.primary.withOpacity(0.2))),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _showPhotoSourceSelector,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.black45,
                        backgroundImage: _profileImagePath != null ? FileImage(File(_profileImagePath!)) : null,
                        child: _profileImagePath == null ? const Icon(Icons.person, size: 35, color: AppColors.primary) : null,
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt, size: 12, color: Colors.black),
                      )
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("TrailMate Hiker", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text(userEmail, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _buildSectionHeader("Navigation & Tracking"),
          _buildSwitchTile(
            "High Accuracy GPS", "Uses more battery but tracks trails precisely", Icons.gps_fixed, _highAccuracyGps, 
            (val) => _updatePreference('highAccuracyGps', val)
          ),
          _buildSwitchTile(
            "Off-Route Warnings", "Vibrates if you wander 25m away from your return path", Icons.warning_amber_rounded, _offRouteAlerts, 
            (val) => _updatePreference('offRouteAlerts', val)
          ),
          _buildSwitchTile(
            "Visual Wayfinding Prompts", 
            "Reminds you to take photos every 200m", Icons.camera_alt_outlined, _autoWayfindingPrompts, 
            (val) => _updatePreference('autoWayfindingPrompts', val)
          ),

          const SizedBox(height: 24),

          _buildSectionHeader("Cloud & Storage"),
          _buildSwitchTile(
            "Sync on Wi-Fi Only", "Pause Firebase uploads while on mobile data", Icons.wifi, _syncWifiOnly, 
            (val) => _updatePreference('syncWifiOnly', val)
          ),
          ListTile(
            leading: const Icon(Icons.cloud_sync_outlined, color: Colors.white),
            title: const Text("Force Cloud Sync", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
            subtitle: const Text("Manually push pending hikes to Firebase", style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Starting manual sync...")));
              SyncService.instance.startListening();
            },
          ),
          ListTile(
            leading: const Icon(Icons.map_outlined, color: Colors.white),
            title: const Text("Manage Offline Maps", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
            subtitle: const Text("142 MB currently downloaded", style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            onTap: () {},
          ),

          const SizedBox(height: 24),

          _buildSectionHeader("Account"),
          ListTile(leading: const Icon(Icons.logout, color: Colors.white70), title: const Text("Log Out", style: TextStyle(color: Colors.white70)), onTap: _handleLogout),
          ListTile(leading: const Icon(Icons.delete_forever, color: Colors.redAccent), title: const Text("Clear Local Storage", style: TextStyle(color: Colors.redAccent)), onTap: _handleClearData),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(padding: const EdgeInsets.only(bottom: 8, left: 8), child: Text(title.toUpperCase(), style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)));
  }

  Widget _buildSwitchTile(String title, String subtitle, IconData icon, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8), secondary: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      value: value, activeColor: Colors.black, activeTrackColor: AppColors.primary,
      inactiveThumbColor: Colors.grey, inactiveTrackColor: AppColors.surface, onChanged: onChanged,
    );
  }
}