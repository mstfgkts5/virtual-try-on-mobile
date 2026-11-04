import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../models/tryon_request.dart';
import '../services/api_service.dart';
import 'result_screen.dart';

class LoadingScreen extends StatefulWidget {
  final Uint8List personImageBytes;
  final Uint8List garmentImageBytes;
  final String category; // 'upper', 'lower', 'overall'

  const LoadingScreen({
    super.key,
    required this.personImageBytes,
    required this.garmentImageBytes,
    this.category = 'upper',
  });

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  double progress = 0.0;
  late AnimationController _spinController;
  bool _isProcessing = true;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _processVirtualTryOn();
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  Future<void> _processVirtualTryOn() async {
    try {
      // Sahte ilerlemeyi başlat
      _startFakeProgress();

      // Sunucu adresi (web / emülatör / telefon) ve kategori ApiService üzerinden yönetilir
      final result = await ApiService().processVirtualTryOn(
        TryOnRequest(
          personImageBytes: widget.personImageBytes,
          garmentImageBytes: widget.garmentImageBytes,
          category: widget.category,
        ),
      );

      _isProcessing = false; // İşlem tamamlandı, sahte progress barı durdur

      if (!mounted) return;

      // İlerlemeyi direkt %100 yap
      setState(() => progress = 1.0);
      await Future.delayed(const Duration(milliseconds: 400));

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ResultScreen(
              // Backend'in kırptığı fotoğraf: sonuçla aynı kadraj, karşılaştırma hizalı olur
              originalImageBytes:
                  result.originalPersonBytes ?? widget.personImageBytes,
              generatedImageBytes: result.resultImageBytes!,
              category: result.category,
              renderTimeSec: result.renderTimeSec,
            ),
          ),
        );
      }
    } catch (e) {
      _isProcessing = false;
      debugPrint('[LoadingScreen] Hata: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Giydirme işlemi başarısız: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
      Navigator.pop(context);
    }
  }

  // Tahmini ilerleme: yerel GPU'da işlem ~40 sn sürdüğü için %90'a ~40 sn'de ulaşır,
  // backend yanıt verince %100'e tamamlanır
  void _startFakeProgress() async {
    int i = 0;
    while (_isProcessing && i < 90) {
      await Future.delayed(const Duration(milliseconds: 450));
      if (mounted && _isProcessing) {
        setState(() => progress = i / 100);
        i += 1;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 10.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'CATVTON • YEREL GPU',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1E1E1E),
                        shape: BoxShape.circle,
                      ),
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(
                          Icons.close,
                          color: Colors.grey,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  height: 280,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF141414),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.grey.shade900),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: ColorFiltered(
                          colorFilter: ColorFilter.mode(
                            Colors.black.withValues(alpha: 0.7),
                            BlendMode.darken,
                          ),
                          child: Image.memory(
                            widget.personImageBytes,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(top: 16, left: 16, child: _buildCornerDot()),
                      Positioned(top: 16, right: 16, child: _buildCornerDot()),
                      Positioned(
                        bottom: 16,
                        left: 16,
                        child: _buildCornerDot(),
                      ),
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: _buildCornerDot(),
                      ),
                      Positioned(
                        top: 40,
                        right: 30,
                        child: _buildFloatingLabel(_categoryBadge),
                      ),
                      Positioned(
                        bottom: 50,
                        left: 30,
                        child: _buildFloatingLabel(
                          'İLERLEME: ${(progress * 100).toStringAsFixed(1)}%',
                        ),
                      ),
                      const Positioned(
                        bottom: 16,
                        child: Text(
                          'DİFÜZYON MODELİ ÇALIŞIYOR',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 160,
                        height: 160,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            RotationTransition(
                              turns: _spinController,
                              child: Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    width: 1,
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    Positioned(
                                      top: 0,
                                      left: 65,
                                      child: _buildSpinningDot(8),
                                    ),
                                    Positioned(
                                      bottom: 20,
                                      right: 10,
                                      child: _buildSpinningDot(4),
                                    ),
                                    Positioned(
                                      bottom: 40,
                                      left: 5,
                                      child: _buildSpinningDot(6),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            RotationTransition(
                              turns: Tween(
                                begin: 1.0,
                                end: 0.0,
                              ).animate(_spinController),
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    width: 1,
                                  ),
                                ),
                                child: const Stack(
                                  children: [
                                    Positioned(
                                      top: 15,
                                      right: 10,
                                      child: SizedBox(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                shape: BoxShape.circle,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.checkroom,
                                    color: Colors.white70,
                                    size: 28,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 4,
                                        height: 4,
                                        decoration: const BoxDecoration(
                                          color: Colors.white54,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Text(
                                        'AI',
                                        style: TextStyle(
                                          color: Colors.white54,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Kıyafet giydiriliyor •',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${(progress * 100).toInt()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          '%',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey.shade900,
                  color: Colors.white,
                  minHeight: 3,
                  borderRadius: BorderRadius.circular(10),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tahmini süre ~40 sn',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          color: Colors.white54,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          progress > 0.8
                              ? 'Son rötuşlar...'
                              : 'İşleniyor...',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141414),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade900),
                  ),
                  child: Column(
                    children: [
                      _buildTaskRow(
                        Icons.person_outline,
                        "Vücut Maskesi",
                        "DensePose + SCHP ile giydirilecek bölge bulunur",
                        progress > 0.3 ? "DONE" : "PROCESSING",
                        progress > 0.3,
                        progress <= 0.3,
                      ),
                      Divider(color: Colors.grey.shade900, height: 1),
                      _buildTaskRow(
                        Icons.layers_outlined,
                        "Difüzyon (30 adım)",
                        "CatVTON kıyafeti kişinin üzerine çizer",
                        progress > 0.7
                            ? "DONE"
                            : (progress > 0.3 ? "PROCESSING" : "QUEUED"),
                        progress > 0.7,
                        progress > 0.3 && progress <= 0.7,
                      ),
                      Divider(color: Colors.grey.shade900, height: 1),
                      _buildTaskRow(
                        Icons.wb_sunny_outlined,
                        "Birleştirme",
                        "Yüz ve arka plan orijinal fotoğraftan korunur",
                        progress == 1.0
                            ? "DONE"
                            : (progress > 0.7 ? "PROCESSING" : "QUEUED"),
                        progress == 1.0,
                        progress > 0.7,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.stop_circle_outlined,
                      color: Colors.white54,
                      size: 18,
                    ),
                    label: const Text(
                      'İptal',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String get _categoryBadge {
    switch (widget.category) {
      case 'lower':
        return 'LOWER BODY';
      case 'overall':
        return 'FULL OUTFIT';
      default:
        return 'UPPER BODY';
    }
  }

  Widget _buildSpinningDot(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.white, blurRadius: size)],
      ),
    );
  }

  Widget _buildCornerDot() {
    return Container(width: 6, height: 6, color: Colors.white24);
  }

  Widget _buildFloatingLabel(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskRow(
    IconData icon,
    String title,
    String subtitle,
    String status,
    bool isDone,
    bool isProcessing,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDone
                  ? Colors.white
                  : (isProcessing ? Colors.grey.shade800 : Colors.transparent),
              shape: BoxShape.circle,
              border: Border.all(
                color: isDone ? Colors.white : Colors.grey.shade800,
              ),
            ),
            child: Icon(
              isDone ? Icons.check : Icons.circle,
              color: isDone
                  ? Colors.black
                  : (isProcessing ? Colors.white : Colors.grey.shade800),
              size: 14,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isDone || isProcessing
                        ? Colors.white
                        : Colors.white38,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDone ? Colors.white12 : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                if (isProcessing) ...[
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  status,
                  style: TextStyle(
                    color: isDone || isProcessing
                        ? Colors.white
                        : Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
