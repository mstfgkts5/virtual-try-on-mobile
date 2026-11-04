import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/api_service.dart';

class ResultScreen extends StatefulWidget {
  final Uint8List
  originalImageBytes; // Modele giren (3:4 kırpılmış) kişi fotoğrafı
  final Uint8List generatedImageBytes; // AI'dan dönen giydirilmiş fotoğraf
  final String category; // 'upper', 'lower', 'overall'
  final double renderTimeSec;

  const ResultScreen({
    super.key,
    required this.originalImageBytes,
    required this.generatedImageBytes,
    this.category = 'upper',
    this.renderTimeSec = 0,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _isSaving = false;
  double _sliderValue = 0.5; // Split mode sürgüsü için
  double _fadeValue = 0.5; // Fade mode şeffaflığı için
  String _activeTab = "Split Slider";

  // 1. Supabase'e Kaydetme Fonksiyonu
  Future<void> _saveToWardrobe() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        throw Exception("Lütfen önce giriş yapın.");
      }

      final fileName =
          '${user.id}_${DateTime.now().millisecondsSinceEpoch}.png';

      await supabase.storage
          .from('wardrobe_images')
          .uploadBinary(fileName, widget.generatedImageBytes);

      final imageUrl = supabase.storage
          .from('wardrobe_images')
          .getPublicUrl(fileName);

      await supabase.from('wardrobe').insert({
        'user_id': user.id,
        'image_url': imageUrl,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✨ Kombin gardırobuna başarıyla eklendi!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kaydedilirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // 2. Tam ekran görüntüleme modalı
  void _openFullScreenView(Uint8List imageBytes, String title) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          fit: StackFit.expand,
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.memory(imageBytes, fit: BoxFit.contain),
            ),
            Positioned(
              top: 40,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageComparisonArea() {
    if (_activeTab == "Side by Side") {
      return Stack(
        fit: StackFit.expand,
        children: [
          Row(
            children: [
              Expanded(
                child: Image.memory(
                  widget.originalImageBytes,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                ),
              ),
              Container(width: 2, color: Colors.white24),
              Expanded(
                child: Image.memory(
                  widget.generatedImageBytes,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ],
          ),
          _buildFullScreenButton(),
        ],
      );
    } else if (_activeTab == "Fade") {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.memory(
            widget.originalImageBytes,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
          ),
          Opacity(
            opacity: _fadeValue,
            child: Image.memory(
              widget.generatedImageBytes,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
            ),
          ),
          _buildFullScreenButton(),
        ],
      );
    } else {
      // Varsayılan: Split Slider. Konum ekran genişliğine değil kartın kendi genişliğine göre
      // hesaplanır; aksi halde kenar boşlukları yüzünden tutamaç ile kesim çizgisi kayıyor
      return LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          return GestureDetector(
            onHorizontalDragUpdate: (details) {
              setState(() {
                _sliderValue = (details.localPosition.dx / width).clamp(
                  0.0,
                  1.0,
                );
              });
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.memory(
                  widget.originalImageBytes,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                ),
                const Positioned(
                  top: 16,
                  left: 16,
                  child: _LabelBadge(text: '• ÖNCE', color: Colors.black54),
                ),
                ClipRect(
                  clipper: _SplitImageClipper(_sliderValue),
                  child: Image.memory(
                    widget.generatedImageBytes,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: ClipRect(
                    clipper: _SplitImageClipper(1.0 - _sliderValue),
                    child: const _LabelBadge(
                      text: '✨ SONRA',
                      color: Colors.white12,
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  bottom: 0,
                  // Tutamaç kesim çizgisinin tam ortasına oturur (çizgi + daire aynı merkezde)
                  left: width * _sliderValue - 16,
                  width: 32,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(width: 2, color: Colors.white),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.unfold_more_outlined,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildFullScreenButton(),
              ],
            ),
          );
        },
      );
    }
  }

  Widget _buildFullScreenButton() {
    return Positioned(
      bottom: 16,
      left: 0,
      right: 0,
      child: Center(
        child: GestureDetector(
          onTap: () => _openFullScreenView(
            widget.generatedImageBytes,
            "✨ ${ApiService.categoryLabel(widget.category)}",
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white24),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.fullscreen, color: Colors.white, size: 16),
                SizedBox(width: 6),
                Text(
                  'Tam Ekran',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text(
          'SeeItOn',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          IconButton(icon: const Icon(Icons.person_outline), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 10,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'STUDIO COMPARISON',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Kombin Sonucu',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Sanal giydirme sonucunu inceleyin ve detayları karşılaştırın.',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white10,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Sonuç 3:4 (768x1024) olduğu için kutu da 3:4; geniş ekranda görsel kırpılmaz
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: AspectRatio(
                  aspectRatio: 3 / 4,
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: Colors.grey.shade900, width: 2),
                    ),
                    child: _buildImageComparisonArea(),
                  ),
                ),
              ),
            ),

            if (_activeTab == "Fade")
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      color: Colors.grey,
                      size: 18,
                    ),
                    Expanded(
                      child: Slider(
                        value: _fadeValue,
                        min: 0.0,
                        max: 1.0,
                        activeColor: Colors.white,
                        inactiveColor: Colors.grey.shade800,
                        onChanged: (val) {
                          setState(() {
                            _fadeValue = val;
                          });
                        },
                      ),
                    ),
                    const Icon(Icons.checkroom, color: Colors.white, size: 18),
                  ],
                ),
              ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    _buildTabButton("Split Slider", Icons.splitscreen_outlined),
                    _buildTabButton("Side by Side", Icons.grid_view_outlined),
                    _buildTabButton("Fade", Icons.blur_on_outlined),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'İşlem Detayları',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'CatVTON • Yerel GPU',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Gösterilen değerler backend'in ölçtüğü gerçek değerlerdir
                  Row(
                    children: [
                      _buildInfoCard(
                        "İşlem Süresi",
                        "${widget.renderTimeSec.toStringAsFixed(1)} sn",
                        "Yerel ekran kartında ölçülen süre",
                      ),
                      const SizedBox(width: 12),
                      _buildInfoCard(
                        "Kategori",
                        ApiService.categoryLabel(
                          widget.category,
                        ).replaceAll(' Sonucu', ''),
                        "Modelin giydirdiği bölge",
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade900),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.share_outlined,
                        color: Colors.white,
                      ),
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveToWardrobe,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : const Icon(Icons.check, color: Colors.black),
                      label: Text(
                        _isSaving
                            ? 'Kaydediliyor...'
                            : 'Onayla ve Gardıroba Ekle',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String text, IconData icon) {
    bool isActive = _activeTab == text;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = text),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF2C2C2C) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isActive ? Colors.white : Colors.grey,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                text,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.grey,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, String desc) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF191919),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade900),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              desc,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 10,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplitImageClipper extends CustomClipper<Rect> {
  final double value;
  _SplitImageClipper(this.value);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(size.width * value, 0.0, size.width, size.height);
  }

  @override
  bool shouldReclip(_SplitImageClipper oldClipper) => oldClipper.value != value;
}

class _LabelBadge extends StatelessWidget {
  final String text;
  final Color color;
  const _LabelBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
