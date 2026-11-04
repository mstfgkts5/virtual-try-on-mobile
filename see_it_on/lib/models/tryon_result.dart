import 'dart:typed_data';

class TryOnResult {
  final String id;
  final String title;
  final String category; // 'upper', 'lower', 'overall'
  final Uint8List? resultImageBytes;
  final Uint8List? originalPersonBytes; // Backend'in 3:4 kırptığı kişi fotoğrafı
  final Uint8List? garmentBytes;
  final double renderTimeSec; // Backend'in ölçtüğü gerçek işlem süresi
  final DateTime createdAt;

  TryOnResult({
    required this.id,
    required this.title,
    this.category = 'upper',
    this.resultImageBytes,
    this.originalPersonBytes,
    this.garmentBytes,
    this.renderTimeSec = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}
