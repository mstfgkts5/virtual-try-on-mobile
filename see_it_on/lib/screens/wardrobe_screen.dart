import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/l10n_ext.dart';

/// ============================================================================
/// SEEITON: LUXURY EDITORIAL WARDROBE / ATELIER SCREEN
/// ============================================================================
class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen({super.key});

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen>
    with SingleTickerProviderStateMixin {
  late Future<List<Map<String, dynamic>>> _wardrobeFuture;
  late AnimationController _shimmerController;

  // Set to true to test the luxury empty state
  final bool _simulateEmptyState = false;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _wardrobeFuture = _fetchWardrobeItems();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  /// Supabase fetch simulated with realistic dummy luxury lookbook fallback
  Future<List<Map<String, dynamic>>> _fetchWardrobeItems() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 1600));

    if (_simulateEmptyState) {
      return [];
    }

    // Replace with Supabase fetch:
    // final response = await Supabase.instance.client.from('wardrobe').select();
    // return List<Map<String, dynamic>>.from(response);

    return [
      {
        'id': '1',
        'garment': 'blazer',
        'category': 'upper',
        'days': 1,
        'image_url':
            'https://images.unsplash.com/photo-1539109136881-3be0616acf4b?auto=format&fit=crop&w=800&q=80',
      },
      {
        'id': '2',
        'garment': 'trousers-m',
        'category': 'lower',
        'days': 2,
        'image_url':
            'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?auto=format&fit=crop&w=800&q=80',
      },
      {
        'id': '3',
        'garment': 'jeans-w',
        'category': 'lower',
        'days': 4,
        'image_url':
            'https://images.unsplash.com/photo-1509631179647-0177331693ae?auto=format&fit=crop&w=800&q=80',
      },
      {
        'id': '4',
        'garment': 'skirt-w',
        'category': 'lower',
        'days': 7,
        'image_url':
            'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?auto=format&fit=crop&w=800&q=80',
      },
      {
        'id': '5',
        'garment': 'chino-m',
        'category': 'lower',
        'days': 14,
        'image_url':
            'https://images.unsplash.com/photo-1496747611176-843222e1e57c?auto=format&fit=crop&w=800&q=80',
      },
      {
        'id': '6',
        'garment': 'shorts-w',
        'category': 'lower',
        'days': 21,
        'image_url':
            'https://images.unsplash.com/photo-1485230895905-ec40ba36b9bc?auto=format&fit=crop&w=800&q=80',
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF0F0E0E); // Deepest obsidian black

    return Scaffold(
      backgroundColor: bgColor,
      extendBodyBehindAppBar: true,
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _wardrobeFuture,
        builder: (context, snapshot) {
          final isLoading = snapshot.connectionState == ConnectionState.waiting;
          final items = snapshot.data ?? [];
          final isEmpty = !isLoading && items.isEmpty;

          return Stack(
            children: [
              // Subtle background ambient glows
              Positioned(
                top: -120,
                right: -60,
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFC5A880).withValues(alpha: 0.08),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Main Scrollable Area
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Space for floating Glass AppBar
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 110),
                  ),

                  // State Handling: Loading vs Empty vs Grid
                  if (isLoading)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: _buildShimmerGrid(),
                    )
                  else if (isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEditorialEmptyState(),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      sliver: _buildFashionGrid(items),
                    ),
                ],
              ),

              // Floating Glassmorphism AppBar
              _buildFloatingGlassAppBar(itemCount: items.length, isLoading: isLoading),
            ],
          );
        },
      ),
    );
  }

  // ==========================================================================
  // 1. FLOATING GLASSMORPHISM APPBAR
  // ==========================================================================
  Widget _buildFloatingGlassAppBar({required int itemCount, required bool isLoading}) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              bottom: 14,
              left: 20,
              right: 20,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF141312).withValues(alpha: 0.65),
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.07),
                  width: 0.8,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.l10n.wardrobeTitle,
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 22,
                        letterSpacing: 1.6,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFFFAF7F2),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isLoading
                          ? context.l10n.wardrobeSyncing
                          : context.l10n.wardrobeCount(itemCount),
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 0.6,
                        color: const Color(0xFFDCDAD4).withValues(alpha: 0.6),
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
                // Action Buttons
                Row(
                  children: [
                    _buildGlassIconButton(
                      icon: Icons.filter_list_rounded,
                      onTap: () {
                        // Filter modal trigger
                      },
                    ),
                    const SizedBox(width: 10),
                    _buildGlassIconButton(
                      icon: Icons.add_rounded,
                      isHighlighted: true,
                      onTap: () {
                        // Navigate to studio / upload
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassIconButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isHighlighted = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: isHighlighted
                ? const Color(0xFFF7F2EB).withValues(alpha: 0.14)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isHighlighted
                  ? const Color(0xFFC5A880).withValues(alpha: 0.4)
                  : Colors.white.withValues(alpha: 0.09),
              width: 0.8,
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: isHighlighted ? const Color(0xFFFAF7F2) : Colors.white70,
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // 2. SHIMMER PULSING LOADING SKELETON
  // ==========================================================================
  Widget _buildShimmerGrid() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        final opacity = 0.2 + (_shimmerController.value * 0.45);
        return SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 14,
            childAspectRatio: 0.65, // Editorial Lookbook Aspect Ratio
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: const Color(0xFF1A1918).withValues(alpha: opacity),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                    width: 0.8,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 50,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: opacity * 0.5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 100,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: opacity * 0.8),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            childCount: 6,
          ),
        );
      },
    );
  }

  // ==========================================================================
  // 3. EDITORIAL EMPTY STATE
  // ==========================================================================
  Widget _buildEditorialEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Softly Glowing Translucent Hanger
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1A1817).withValues(alpha: 0.7),
                border: Border.all(
                  color: const Color(0xFFC5A880).withValues(alpha: 0.25),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFC5A880).withValues(alpha: 0.12),
                    blurRadius: 36,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.checkroom_rounded,
                size: 46,
                color: Color(0xFFE8DFD4),
              ),
            ),
            const SizedBox(height: 32),

            // Typography
            Text(
              context.l10n.wardrobeEmptyTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 24,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w400,
                color: Color(0xFFFAF7F2),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              context.l10n.wardrobeEmptyBody,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.55,
                fontWeight: FontWeight.w300,
                color: const Color(0xFFC7C3BB).withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: 36),

            // Editorial CTA Button
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFAF7F2).withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  // Switch to Try On tab or navigate to camera
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFAF7F2),
                  foregroundColor: const Color(0xFF141312),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.l10n.wardrobeEmptyCta,
                      style: TextStyle(
                        fontSize: 14,
                        letterSpacing: 0.6,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // 4. THE EDITORIAL FASHION GRID
  // ==========================================================================
  Widget _buildFashionGrid(List<Map<String, dynamic>> items) {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 14,
        childAspectRatio: 0.65, // Full & upper body portrait ratio
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final item = items[index];
          final imageUrl = item['image_url'] ?? '';
          final title = garmentName(context.l10n, item['garment'] ?? '');
          final category = categoryName(context.l10n, item['category'] ?? 'upper');

          return _buildLookbookCard(
            imageUrl: imageUrl,
            title: title,
            category: category,
            onTap: () => _openLookDetail(item),
            onShare: () => _shareLook(item),
          );
        },
        childCount: items.length,
      ),
    );
  }

  Widget _buildLookbookCard({
    required String imageUrl,
    required String title,
    required String category,
    required VoidCallback onTap,
    required VoidCallback onShare,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Photo Image
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: const Color(0xFF1C1A19),
                  child: const Center(
                    child: Icon(Icons.broken_image_rounded, color: Colors.white24),
                  ),
                ),
              ),

              // Inner Border (white with 0.1 opacity)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                      width: 1,
                    ),
                  ),
                ),
              ),

              // Category Micro-Badge (Top Left)
              Positioned(
                top: 10,
                left: 10,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                          width: 0.6,
                        ),
                      ),
                      child: Text(
                        category.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 8.5,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFFAF7F2),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom Scrim Gradient Overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 120,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.4),
                        Colors.black.withValues(alpha: 0.88),
                      ],
                      stops: const [0.0, 0.4, 1.0],
                    ),
                  ),
                ),
              ),

              // Title and Minimalist Glass Expand/Share Button
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Georgia',
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFFFAF7F2),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            context.l10n.wardrobeAiFit,
                            style: TextStyle(
                              fontSize: 9.5,
                              color: Colors.white.withValues(alpha: 0.55),
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Minimal Glass Expand Button
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: onShare,
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  width: 0.6,
                                ),
                              ),
                              child: const Icon(
                                Icons.north_east_rounded,
                                size: 14,
                                color: Color(0xFFFAF7F2),
                              ),
                            ),
                          ),
                        ),
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
  }

  void _openLookDetail(Map<String, dynamic> item) {
    // Open full resolution split-slider or before/after comparison
  }

  void _shareLook(Map<String, dynamic> item) {
    // Trigger native share sheet or high-res export
  }
} 