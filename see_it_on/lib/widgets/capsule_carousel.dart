import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/tryon_provider.dart';

class CapsuleCarousel extends StatelessWidget {
  final VoidCallback onViewAllTap;

  const CapsuleCarousel({
    super.key,
    required this.onViewAllTap,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TryOnProvider>();
    final items = provider.capsuleItems;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'INSTANT TRY CAPSULE',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.9,
                ),
              ),
              InkWell(
                onTap: onViewAllTap,
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Horizontal List
        SizedBox(
          height: 58,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final item = items[index];
              final isSelected = provider.selectedGarmentItem?.id == item.id;

              return InkWell(
                onTap: () => provider.loadGarmentPreset(item),
                borderRadius: BorderRadius.circular(100),
                child: Container(
                  padding: const EdgeInsets.only(left: 6, right: 16, top: 6, bottom: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF262E40)
                        : const Color(0xFF151924),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : const Color(0xFF262E40),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Thumbnail
                      ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: Container(
                          width: 44,
                          height: 44,
                          color: const Color(0xFF232A3B),
                          child: Image.asset(
                            item.assetPath,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.checkroom,
                              size: 20,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Text info
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.designer,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
