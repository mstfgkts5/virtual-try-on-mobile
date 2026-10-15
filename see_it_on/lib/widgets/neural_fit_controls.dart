import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/tryon_provider.dart';

class NeuralFitControls extends StatelessWidget {
  const NeuralFitControls({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TryOnProvider>();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF131620),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF222838), width: 1.2),
      ),
      child: Column(
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.tune_rounded,
                    size: 18,
                    color: AppColors.textPrimary,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Neural Fit Controls',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Text(
                    'Lock Pose',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: provider.lockPose,
                      onChanged: (val) => provider.toggleLockPose(val),
                      activeColor: Colors.white,
                      activeTrackColor: const Color(0xFF38435C),
                      inactiveThumbColor: AppColors.textSecondary,
                      inactiveTrackColor: const Color(0xFF1C2230),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 3-Option Segmented Control
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF0C0E14),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: const Color(0xFF1E2433), width: 1),
            ),
            child: Row(
              children: [
                _buildSegmentButton(
                  context,
                  label: 'Tailored',
                  isSelected: provider.selectedFit == 'Tailored',
                  onTap: () => provider.setSelectedFit('Tailored'),
                ),
                _buildSegmentButton(
                  context,
                  label: 'Regular',
                  isSelected: provider.selectedFit == 'Regular',
                  onTap: () => provider.setSelectedFit('Regular'),
                ),
                _buildSegmentButton(
                  context,
                  label: 'Oversized',
                  isSelected: provider.selectedFit == 'Oversized',
                  onTap: () => provider.setSelectedFit('Oversized'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(100),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
