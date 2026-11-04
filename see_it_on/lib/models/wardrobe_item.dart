/// Gardıroba kaydedilmiş tek bir sanal deneme sonucu (Supabase `wardrobe` satırı).
class WardrobeItem {
  final String id;
  final String imageUrl;
  final String category; // 'upper', 'lower', 'overall'
  final DateTime? createdAt;

  /// `wardrobe_images` deposundaki dosya yolu (silmek için), URL'den çıkarılır.
  final String? storagePath;

  const WardrobeItem({
    required this.id,
    required this.imageUrl,
    this.category = 'upper',
    this.createdAt,
    this.storagePath,
  });

  static const bucket = 'wardrobe_images';

  /// `category` sütunu henüz eklenmemiş tablolarda da çalışır (varsayılan üst giyim).
  factory WardrobeItem.fromRow(Map<String, dynamic> row) {
    final url = row['image_url'] as String? ?? '';
    final created = row['created_at'];
    return WardrobeItem(
      id: '${row['id']}',
      imageUrl: url,
      category: row['category'] as String? ?? 'upper',
      createdAt: created is String ? DateTime.tryParse(created) : null,
      storagePath: _pathFromPublicUrl(url),
    );
  }

  static String? _pathFromPublicUrl(String url) {
    const marker = '/$bucket/';
    final i = url.indexOf(marker);
    return i < 0 ? null : Uri.decodeComponent(url.substring(i + marker.length));
  }
}

/// Takvim günü farkı (saatten bağımsız): bugün 0, dün 1.
int daysAgo(DateTime date, [DateTime? now]) {
  final n = now ?? DateTime.now();
  final local = date.toLocal();
  final today = DateTime(n.year, n.month, n.day);
  final day = DateTime(local.year, local.month, local.day);
  return today.difference(day).inDays.clamp(0, 100000);
}
