import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/app_colors.dart';
import '../models/hike_model.dart';
import 'widgets/trailmate_logo.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onNavigateToMap;
  const HomeScreen({super.key, required this.onNavigateToMap});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<HikeModel> _hikes = [];
  double _totalDistance = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    final hikes = await DatabaseHelper.instance.getAllHikes();
    double totalDist = 0;
    for (var hike in hikes) {
      totalDist += hike.distance;
    }
    
    if(mounted) {
      setState(() {
        _hikes = hikes;
        _totalDistance = totalDist;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadDashboardData,
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const TrailMateLogo(size: 40),
                CircleAvatar(
                  backgroundColor: AppColors.surface,
                  child: IconButton(icon: const Icon(Icons.notifications_none, color: AppColors.textPrimary), onPressed: () {}),
                )
              ],
            ),
            const SizedBox(height: 30),
            const Text("Stats", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildStatCard("Distance Traveled", "${_totalDistance.toStringAsFixed(1)} KM", Icons.directions_walk)),
                const SizedBox(width: 16),
                Expanded(child: _buildStatCard("Total Hikes", "${_hikes.length}", Icons.terrain)),
              ],
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("My Hikes", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                TextButton(
                  onPressed: _loadDashboardData, 
                  child: const Text("Refresh", style: TextStyle(color: AppColors.primary))
                )
              ],
            ),
            const SizedBox(height: 10),
            
            if (_isLoading)
              const Center(child: CircularProgressIndicator(color: AppColors.primary))
            else if (_hikes.isEmpty)
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    const Icon(Icons.terrain_outlined, size: 60, color: AppColors.textSecondary),
                    const SizedBox(height: 16),
                    const Text("No hikes recorded yet.", style: TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black),
                      onPressed: widget.onNavigateToMap,
                      child: const Text("START YOUR FIRST HIKE"),
                    )
                  ],
                ),
              )
            else
              ..._hikes.map((hike) {
                return _buildHikeCard(
                  hike.title,
                  "${hike.distance.toStringAsFixed(2)}KM",
                  "${hike.elevation.toStringAsFixed(0)}m",
                  hike.duration,
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 28),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildHikeCard(String title, String dist, String elev, String dur) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 70, height: 70,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.landscape, color: AppColors.primary, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildMiniStat(Icons.straighten, dist),
                    const SizedBox(width: 12),
                    _buildMiniStat(Icons.trending_up, elev),
                    const SizedBox(width: 12),
                    _buildMiniStat(Icons.timer, dur),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String val) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(val, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}