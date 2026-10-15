import 'dart:typed_data';

class TryOnResult {
  final String id;
  final String title;
  final String designer;
  final Uint8List? resultImageBytes;
  final String? resultAssetPath;
  final Uint8List? originalPersonBytes;
  final String? originalPersonAsset;
  final Uint8List? garmentBytes;
  final String? garmentAsset;
  final double fitScore; // e.g. 98.4
  final double renderTimeSec; // e.g. 3.4
  final String fitType;
  final DateTime createdAt;

  TryOnResult({
    required this.id,
    required this.title,
    this.designer = 'Maison K.',
    this.resultImageBytes,
    this.resultAssetPath,
    this.originalPersonBytes,
    this.originalPersonAsset,
    this.garmentBytes,
    this.garmentAsset,
    this.fitScore = 98.4,
    this.renderTimeSec = 3.6,
    this.fitType = 'Tailored',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get hasResultImage =>
      resultImageBytes != null || resultAssetPath != null;
}
