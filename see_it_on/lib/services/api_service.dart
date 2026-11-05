import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/l10n_ext.dart';
import '../core/constants.dart';
import '../models/spin.dart';
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
  Future<TryOnResult> processVirtualTryOn(TryOnRequest request) async {
    try {

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

      // Yerel GPU'da işlem ~10-40 sn sürer; ilk istek model ısınması nedeniyle daha uzun olabilir
      final streamedResponse = await multipartRequest.send().timeout(
        const Duration(seconds: 180),
        onTimeout: () {
          throw TimeoutException('tryon');
        },
      );

      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('[ApiService] Yanıt durumu: ${response.statusCode}');

      if (response.statusCode == 200) {
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
      title: category,
      category: category,
      resultImageBytes: base64Decode(json['image_base64'] as String),
      // Backend'in 3:4 kırptığı kişi fotoğrafı; yoksa orijinale düş
      originalPersonBytes: json['person_base64'] != null
          ? base64Decode(json['person_base64'] as String)
          : request.personImageBytes,
      garmentBytes: request.garmentImageBytes,
      renderTimeSec: (json['render_time'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// 360° dönüş işini başlatır; iş numarasını döner. Video yüklemesi büyük olabilir.
  Future<String> startSpin(SpinRequest request) async {
    final multipart = http.MultipartRequest('POST', Uri.parse('$_baseUrl/api/v1/spin'))
      ..files.add(http.MultipartFile.fromBytes('video', request.videoBytes, filename: request.videoName))
      ..files.add(http.MultipartFile.fromBytes('garment_front', request.garmentFront, filename: 'front.jpg'))
      ..fields['category'] = request.category.toLowerCase()
      ..fields['frames'] = '${request.frames}';
    if (request.garmentBack != null) {
      multipart.files.add(http.MultipartFile.fromBytes('garment_back', request.garmentBack!, filename: 'back.jpg'));
    }
    final streamed = await multipart.send().timeout(
      const Duration(seconds: 120),
      onTimeout: () => throw TimeoutException('spin'),
    );
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode != 200) throw Exception(_errorMessage(response));
    return (jsonDecode(response.body) as Map<String, dynamic>)['job_id'] as String;
  }

  /// Dönüş işinin durumu; `since` sonrası hazır kareler gelir. Her çağrı işi canlı tutar.
  Future<SpinStatus> spinStatus(String jobId, {int since = 0}) async {
    final response = await http
        .get(Uri.parse('$_baseUrl/api/v1/spin/$jobId?since=$since'))
        .timeout(const Duration(seconds: 15), onTimeout: () => throw TimeoutException('spin'));
    if (response.statusCode != 200) throw Exception(_errorMessage(response));
    return SpinStatus.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  /// İşi iptal eder; ekrandan çıkarken çağrılır, hata olsa da sessizce geçer.
  Future<void> cancelSpin(String jobId) async {
    try {
      await http.delete(Uri.parse('$_baseUrl/api/v1/spin/$jobId')).timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('[ApiService] Dönüş iptali gönderilemedi: $e');
    }
  }

  /// FastAPI hata yanıtındaki `detail` alanını okunur bir mesaja çevirir
  static String _errorMessage(http.Response response) {
    try {
      final detail =
          (jsonDecode(response.body) as Map<String, dynamic>)['detail'];
      if (detail is String) return detail;
    } catch (_) {}
    return '$_httpErrorPrefix${response.statusCode}';
  }

  static const _httpErrorPrefix = 'HTTP ';

  /// Hatayı kullanıcının dilinde gösterilecek metne çevirir.
  /// Bilinen durumlar (zaman aşımı, sunucuya ulaşılamaması, kodlu HTTP hatası) çevrilir;
  /// backend'in `detail` metni olduğu gibi gösterilir (backend mesajları kapsam dışı).
  static String friendlyError(AppLocalizations l, Object error) {
    if (error is TimeoutException) return l.errorTimeout;
    if (error is http.ClientException) return l.errorBackendOffline;
    final message = error.toString().replaceFirst('Exception: ', '');
    if (message.startsWith(_httpErrorPrefix)) {
      return l.errorServer(message.substring(_httpErrorPrefix.length));
    }
    return message;
  }
}
