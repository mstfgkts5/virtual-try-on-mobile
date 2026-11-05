import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../core/design/widgets.dart';
import '../core/l10n_ext.dart';
import '../models/wardrobe_item.dart';
import '../services/storage_service.dart';
import '../services/wardrobe_repository.dart';
import 'wardrobe_screen.dart';

/// Tek bir kayıtlı kombin: büyük görsel, paylaş ve sil.
/// Silinirse `Navigator.pop(context, true)` ile döner; gardırop listeyi yeniler.
class WardrobeDetailScreen extends StatefulWidget {
  const WardrobeDetailScreen({
    super.key,
    required this.item,
    required this.repository,
  });

  final WardrobeItem item;
  final WardrobeRepository repository;

  @override
  State<WardrobeDetailScreen> createState() => _WardrobeDetailScreenState();
}

class _WardrobeDetailScreenState extends State<WardrobeDetailScreen> {
  bool _busy = false;

  Future<void> _delete() async {
    final l = context.l10n;
    final t = context.tokens;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.wardrobeDeleteTitle),
        content: Text(l.wardrobeDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.wardrobeCancel, style: TextStyle(color: t.ink)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l.wardrobeDeleteConfirm,
              style: TextStyle(color: t.danger, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await widget.repository.delete(widget.item);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.wardrobeDeleted)));
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('[WardrobeDetail] Silme hatası: $e');
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.wardrobeDeleteFailed),
          backgroundColor: context.tokens.danger,
        ),
      );
    }
  }

  // Paylaşım baytlar ister; kayıt yalnızca URL tuttuğu için görsel indirilir
  Future<void> _share() async {
    final l = context.l10n;
    setState(() => _busy = true);
    try {
      final res = await http
          .get(Uri.parse(widget.item.imageUrl))
          .timeout(const Duration(seconds: 20));
      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
      await StorageService().shareOutfit(
        res.bodyBytes,
        message: l.resultShareText,
      );
    } catch (e) {
      debugPrint('[WardrobeDetail] Paylaşım hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.wardrobeShareFailed)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final item = widget.item;
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: t.paper,
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: l.wardrobeShare,
            icon: const Icon(Icons.share_outlined),
            onPressed: _busy ? null : _share,
          ),
          IconButton(
            tooltip: l.wardrobeDelete,
            icon: const Icon(Icons.delete_outline),
            onPressed: _busy ? null : _delete,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: AspectRatio(
                    aspectRatio: 3 / 4,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(SeeItOnTokens.radiusLg),
                      child: InteractiveViewer(
                        maxScale: 4,
                        child: Hero(
                          tag: 'wardrobe-${item.id}',
                          child: WardrobeImage(
                            url: item.imageUrl,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Row(
                children: [
                  CategoryBadge(category: item.category),
                  const SizedBox(width: 10),
                  // Dar ekranda uzun kategori adı kısaltılır, tarih sağda kalır
                  Expanded(
                    child: Text(
                      categoryName(l, item.category),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.headlineSmall!.copyWith(fontSize: 18),
                    ),
                  ),
                  if (item.createdAt != null) ...[
                    const SizedBox(width: 8),
                    Caption(l.wardrobeDaysAgo(daysAgo(item.createdAt!)), italic: true),
                  ],
                ],
              ),
            ),
            if (_busy)
              LinearProgressIndicator(minHeight: 2, color: t.accent, backgroundColor: t.line),
          ],
        ),
      ),
    );
  }
}
