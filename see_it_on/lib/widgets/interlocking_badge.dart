import 'package:flutter/material.dart';
import '../core/theme.dart';

class InterlockingBadge extends StatelessWidget {
  const InterlockingBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFF1E2330),
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFF2E3649),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.link_rounded,
            size: 20,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
