import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/tryon_request.dart';
import '../models/tryon_result.dart';

class ApiService {
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String _baseUrl = AppConstants.defaultBaseUrl;

  String get baseUrl => _baseUrl;
  set baseUrl(String url) {
    _baseUrl = url.trim().replaceAll(RegExp(r'/+$'), '');
  }

  /// Checks if the FastAPI backend is running and reachable
  Future<bool> checkBackendHealth() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/health'))
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Sends multipart/form-data request to Python FastAPI backend
  Future<TryOnResult> processVirtualTryOn(
    TryOnRequest request, {
    void Function(String stepDescription, double progress)? onProgress,
  }) async {
    try {
      onProgress?.call("Sunucuya bağlanılıyor...", 0.15);

      final uri = Uri.parse('$_baseUrl${AppConstants.tryOnEndpoint}');
      final multipartRequest = http.MultipartRequest('POST', uri);

      // Kişi fotoğrafını ekle
      multipartRequest.files.add(
        http.MultipartFile.fromBytes(
          'person_image',
          request.personImageBytes,
          filename: request.personImageName ?? 'person.jpg',
        ),
      );

      // Kıyafet fotoğrafını ekle (üst, alt veya tam kıyafet)
      multipartRequest.files.add(
        http.MultipartFile.fromBytes(
          'garment_image',
          request.garmentImageBytes,
          filename: request.garmentImageName ?? 'garment.jpg',
        ),
      );

      final fieldsMap = request.toFieldsMap();
      multipartRequest.fields.addAll(fieldsMap);

      debugPrint(
        '[ApiService] İstek Gönderiliyor -> Kategori: ${fieldsMap['category']}, BaseUrl: $_baseUrl',
      );

      onProgress?.call("Görseller yükleniyor...", 0.35);

      // Yerel GPU'da işlem ~10-40 sn sürer; ilk istek model ısınması nedeniyle daha uzun olabilir
      final streamedResponse = await multipartRequest.send().timeout(
        const Duration(seconds: 180),
        onTimeout: () {
          throw TimeoutException('İstek 180 saniye sonra zaman aşımına uğradı');
        },
      );

      onProgress?.call("Model işleniyor...", 0.70);

      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('[ApiService] Yanıt durumu: ${response.statusCode}');

      if (response.statusCode == 200) {
        onProgress?.call("İşlem tamamlandı!", 1.0);
        return _parseSuccessResponse(response, request);
      } else {
        throw Exception(_errorMessage(response));
      }
    } catch (e) {
      debugPrint('[ApiService] Kritik Bağlantı veya API Hatası: $e');
      rethrow;
    }
  }

  TryOnResult _parseSuccessResponse(
    http.Response response,
    TryOnRequest request,
  ) {
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final category = json['category'] as String? ?? request.category;

    return TryOnResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: categoryLabel(category),
      designer: 'CatVTON (Local GPU)',
      category: category,
      resultImageBytes: base64Decode(json['image_base64'] as String),
      // Backend'in 3:4 kırptığı kişi fotoğrafı; yoksa orijinale düş
      originalPersonBytes: json['person_base64'] != null
          ? base64Decode(json['person_base64'] as String)
          : request.personImageBytes,
      garmentBytes: request.garmentImageBytes,
      renderTimeSec: (json['render_time'] as num?)?.toDouble() ?? 0.0,
      fitType: request.fitType,
    );
  }

  /// FastAPI hata yanıtındaki `detail` alanını okunur bir mesaja çevirir
  static String _errorMessage(http.Response response) {
    try {
      final detail =
          (jsonDecode(response.body) as Map<String, dynamic>)['detail'];
      if (detail is String) return detail;
    } catch (_) {}
    return 'Sunucu hatası (${response.statusCode})';
  }

  static String categoryLabel(String category) {
    switch (category) {
      case 'lower':
        return 'Alt Giyim Sonucu';
      case 'overall':
        return 'Tam Kıyafet Sonucu';
      default:
        return 'Üst Giyim Sonucu';
    }
  }
}
