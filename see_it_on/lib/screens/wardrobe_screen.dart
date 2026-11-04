import 'package:flutter/material.dart';

import '../core/l10n_ext.dart';
import '../models/wardrobe_item.dart';
import '../services/wardrobe_repository.dart';
import 'login_screen.dart';
import 'wardrobe_detail_screen.dart';

// Ana ekranla aynı görsel dil
const _bg = Color(0xFFF6F4EF);
const _ink = Color(0xFF1E1C1A);
const _dark = Color(0xFF221F1E);

/// Kullanıcının kaydettiği sanal deneme sonuçları.
/// [repository] verilmezse Supabase kullanılır; testlerde sahte depo verilir.
class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen({super.key, this.repository});

  final WardrobeRepository? repository;

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  late final WardrobeRepository _repo =
      widget.repository ?? SupabaseWardrobeRepository();
  late Future<List<WardrobeItem>> _future;
  String _filter = 'all'; // 'all' / 'upper' / 'lower' / 'overall'

  @override
  void initState() {
    super.initState();
    _future = _repo.fetch();
  }

  Future<void> _reload() async {
    final next = _repo.fetch();
    setState(() {
      _future = next;
    });
    await next.catchError((_) => <WardrobeItem>[]);
  }

  Future<void> _openDetail(WardrobeItem item) async {
    final deleted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => WardrobeDetailScreen(item: item, repository: _repo),
      ),
    );
    if (deleted == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = _repo.currentUserEmail != null;
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _ink,
      ),
      body: SafeArea(
        top: false,
        child: !signedIn
            ? _Message(
                icon: Icons.lock_outline,
                title: context.l10n.wardrobeSignInTitle,
                body: context.l10n.wardrobeSignInBody,
                action: context.l10n.loginButton,
                onAction: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
              )
            : FutureBuilder<List<WardrobeItem>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const _SkeletonGrid();
                  }
                  if (snap.hasError) {
                    return _Message(
                      icon: Icons.cloud_off_outlined,
                      title: context.l10n.wardrobeLoadError,
                      action: context.l10n.wardrobeRetry,
                      onAction: _reload,
                    );
                  }
                  final items = snap.data ?? const <WardrobeItem>[];
                  if (items.isEmpty) {
                    return _Message(
                      icon: Icons.checkroom,
                      title: context.l10n.wardrobeEmptyTitle,
                      body: context.l10n.wardrobeEmptyBody,
                      action: context.l10n.wardrobeEmptyCta,
                      onAction: () => Navigator.pop(context),
                    );
                  }
                  return _buildList(items);
                },
              ),
      ),
    );
  }

  Widget _buildList(List<WardrobeItem> items) {
    final l = context.l10n;
    final shown = _filter == 'all'
        ? items
        : items.where((i) => i.category == _filter).toList();
    int count(String c) => items.where((i) => i.category == c).length;

    return RefreshIndicator(
      color: _dark,
      onRefresh: _reload,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.wardrobeTitle,
                    style: TextStyle(
                      color: _ink.withValues(alpha: 0.6),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l.wardrobeHeading,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 32,
                      fontFamily: 'Georgia',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l.wardrobeCount(items.length),
                    style: TextStyle(
                      color: _ink.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 18),
                  // En fazla 4 düğme: yatay kaydırma yerine Wrap; dar ekranda sağdaki düğme kenarda kesilip
                  // fark edilmeden kalmasın diye alt satıra geçer
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _FilterChip(
                        label: l.wardrobeFilterAll,
                        count: items.length,
                        active: _filter == 'all',
                        onTap: () => setState(() => _filter = 'all'),
                      ),
                      for (final c in const ['upper', 'lower', 'overall'])
                        if (count(c) > 0)
                          _FilterChip(
                            label: categoryName(l, c),
                            count: count(c),
                            active: _filter == c,
                            onTap: () => setState(() => _filter = c),
                          ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            sliver: SliverGrid(
              // Sonuç görselleri 3:4 (768x1024); kart da 3:4 olduğu için görsel kırpılmaz
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 3 / 4,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) => _LookCard(
                  item: shown[i],
                  onTap: () => _openDetail(shown[i]),
                ),
                childCount: shown.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.active,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = active ? Colors.white : _ink;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: active ? _dark : Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: active ? _dark : Colors.white, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$count',
              style: TextStyle(color: fg.withValues(alpha: 0.6), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _LookCard extends StatelessWidget {
  const _LookCard({required this.item, required this.onTap});

  final WardrobeItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return GestureDetector(
      key: ValueKey('wardrobe-card-${item.id}'),
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: 'wardrobe-${item.id}',
              child: WardrobeImage(url: item.imageUrl),
            ),
            Positioned(
              top: 10,
              left: 10,
              child: CategoryBadge(category: item.category),
            ),
            if (item.createdAt != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 24, 12, 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.45),
                      ],
                    ),
                  ),
                  child: Text(
                    l.wardrobeDaysAgo(daysAgo(item.createdAt!)),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Kart ve detayda ortak: yüklenirken krem zemin, hata olursa ikon (internet yoksa kırık görsel görünmez).
class WardrobeImage extends StatelessWidget {
  const WardrobeImage({super.key, required this.url, this.fit = BoxFit.cover});

  final String url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: fit,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : Container(color: const Color(0xFFF0EBE1)),
      errorBuilder: (context, error, stack) => Container(
        color: const Color(0xFFF0EBE1),
        child: Icon(
          Icons.image_not_supported_outlined,
          color: _ink.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}

class CategoryBadge extends StatelessWidget {
  const CategoryBadge({super.key, required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final label = switch (category) {
      'lower' => l.categoryBadgeLower,
      'overall' => l.categoryBadgeOverall,
      _ => l.categoryBadgeUpper,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _ink,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _SkeletonGrid extends StatelessWidget {
  const _SkeletonGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 120, 20, 32),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 3 / 4,
      ),
      itemCount: 4,
      itemBuilder: (_, _) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF0EBE1),
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    this.body,
    required this.action,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String? body;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: Color(0xFFF0EBE1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: _ink.withValues(alpha: 0.6), size: 30),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _ink,
                fontSize: 22,
                fontFamily: 'Georgia',
                fontWeight: FontWeight.w500,
              ),
            ),
            if (body != null) ...[
              const SizedBox(height: 10),
              Text(
                body!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _ink.withValues(alpha: 0.6),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: _dark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
              ),
              child: Text(
                action,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
