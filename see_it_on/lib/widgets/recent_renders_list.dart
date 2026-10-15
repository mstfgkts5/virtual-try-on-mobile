import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../models/tryon_result.dart';
import '../providers/tryon_provider.dart';

class RecentRendersList extends StatelessWidget {
  final void Function(TryOnResult result) onRenderTap;
  final VoidCallback onHistoryTap;

  const RecentRendersList({
    super.key,
    required this.onRenderTap,
    required this.onHistoryTap,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TryOnProvider>();
    final items = provider.recentRenders;

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
                'RECENT RENDERS',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.9,
                ),
              ),
              InkWell(
                onTap: onHistoryTap,
                child: const Row(
                  children: [
                    Text(
                      'Wardrobe History',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(Icons.chevron_right, size: 16, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Cards list
        SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final render = items[index];

              return GestureDetector(
                onTap: () => onRenderTap(render),
                child: Container(
                  width: 165,
                  decoration: BoxDecoration(
                    color: const Color(0xFF131620),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFF222838), width: 1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Stack(
                      children: [
                        // Background image
                        Positioned.fill(
                          child: render.resultImageBytes != null
                              ? Image.memory(
                                  render.resultImageBytes!,
                                  fit: BoxFit.cover,
                                )
                              : (render.resultAssetPath != null
                                  ? Image.asset(
                                      render.resultAssetPath!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => const Center(
                                        child: Icon(Icons.broken_image, color: Colors.white24),
                                      ),
                                    )
                                  : Container(color: const Color(0xFF1B202D))),
                        ),

                        // Gradient protection
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.3),
                                  Colors.black.withOpacity(0.85),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Bottom info overlay
                        Positioned(
                          left: 12,
                          right: 12,
                          bottom: 12,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      render.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Fit: ${render.fitScore.toStringAsFixed(0)}% Match',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.75),
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white24, width: 0.8),
                                ),
                                child: const Icon(
                                  Icons.visibility_outlined,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
