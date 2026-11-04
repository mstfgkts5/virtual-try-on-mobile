import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../core/l10n_ext.dart';
import '../models/wardrobe_item.dart';
import '../services/storage_service.dart';
import '../services/wardrobe_repository.dart';
import 'wardrobe_screen.dart';

const _ink = Color(0xFF1E1C1A);

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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFF6F4EF),
        title: Text(
          l.wardrobeDeleteTitle,
          style: const TextStyle(fontFamily: 'Georgia', color: _ink),
        ),
        content: Text(l.wardrobeDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.wardrobeCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFE11D48),
            ),
            child: Text(l.wardrobeDeleteConfirm),
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
          backgroundColor: const Color(0xFFE11D48),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF6F4EF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _ink,
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
                      borderRadius: BorderRadius.circular(28),
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
                  Text(
                    categoryName(l, item.category),
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 16,
                      fontFamily: 'Georgia',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (item.createdAt != null)
                    Text(
                      l.wardrobeDaysAgo(daysAgo(item.createdAt!)),
                      style: TextStyle(
                        color: _ink.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            if (_busy)
              const LinearProgressIndicator(
                minHeight: 2,
                color: Color(0xFF221F1E),
              ),
          ],
        ),
      ),
    );
  }
}
