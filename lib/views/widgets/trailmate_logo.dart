import 'package:flutter/material.dart';
import '../../models/app_colors.dart';

class TrailMateLogo extends StatelessWidget {
  final double size;
  const TrailMateLogo({super.key, this.size = 100});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.terrain_outlined, size: size, color: AppColors.primary),
            Positioned(
              right: size * 0.1,
              top: size * 0.1,
              child: Icon(Icons.arrow_outward, size: size * 0.4, color: AppColors.primary),
            ),
          ],
        ),
        Text(
          "TrailMate",
          style: TextStyle(
            color: AppColors.primary,
            fontSize: size * 0.35,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}