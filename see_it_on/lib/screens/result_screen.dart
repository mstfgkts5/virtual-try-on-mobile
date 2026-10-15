import 'dart:typed_data';
import 'package:flutter/material.dart';

class ResultScreen extends StatefulWidget {
  final Uint8List originalImageBytes;  // Kullanıcının yüklediği orijinal fotoğraf
  final Uint8List generatedImageBytes; // AI'dan dönen giydirilmiş fotoğraf

  const ResultScreen({
    super.key, 
    required this.originalImageBytes, 
    required this.generatedImageBytes
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  double _sliderValue = 0.5;
  String _activeTab = "Split Slider";

  // Tam ekran görüntüleme modalını açan fonksiyon
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('SeeItOn', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
          IconButton(icon: const Icon(Icons.person_outline), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. ÜST BAŞLIK VE AÇIKLAMA
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('STUDIO COMPARISON', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                        const SizedBox(height: 4),
                        const Text('Before / After Comparison', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text(
                          'Slide to see the AI drape result and compare pattern, fabric, and fit accuracy.',
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 13, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: Colors.white10, shape: BoxShape.circle),
                      child: const Icon(Icons.close, color: Colors.white, size: 20),
                    ),
                  )
                ],
              ),
            ),

            // 2. INTERAKTİF SÜRGÜLÜ FOTOĞRAF ALANI (SPLIT SLIDER)
            Container(
              height: 450,
              margin: const EdgeInsets.all(16),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.grey.shade900, width: 2),
              ),
              child: GestureDetector(
                onHorizontalDragUpdate: (details) {
                  setState(() {
                    _sliderValue = (details.localPosition.dx / MediaQuery.of(context).size.width).clamp(0.0, 1.0);
                  });
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // ARKA PLAN: Orijinal Fotoğraf (BEFORE)
                    Image.memory(
                      widget.originalImageBytes, 
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.high,
                    ),
                    const Positioned(
                      top: 16, left: 16,
                      child: _LabelBadge(text: '• BEFORE • ORIGINAL', color: Colors.black54),
                    ),

                    // ÖN PLAN: AI Giydirilmiş Hali (AFTER)
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
                        child: const _LabelBadge(text: '✨ AFTER • ATELIER DRAPE', color: Colors.white12),
                      ),
                    ),

                    // ORTADAKİ HAREKETLİ BÖLÜCÜ ÇİZGİ
                    Positioned(
                      top: 0, bottom: 0,
                      left: MediaQuery.of(context).size.width * _sliderValue - 14,
                      child: Row(
                        children: [
                          Container(width: 2, color: Colors.white),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(color: Colors.black, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                            child: const Icon(Icons.unfold_more_outlined, color: Colors.white, size: 16),
                          ),
                          Container(width: 2, color: Colors.white),
                        ],
                      ),
                    ),

                    // 🌟 TAM EKRAN GÖRÜNTÜLEME BUTONU
                    Positioned(
                      bottom: 16,
                      left: 0, right: 0,
                      child: Center(
                        child: GestureDetector(
                          onTap: () => _openFullScreenView(widget.generatedImageBytes, "✨ After • AI Drape Result"),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white24)
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.fullscreen, color: Colors.white, size: 16),
                                SizedBox(width: 6),
                                Text('Full Screen View', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),

            // 3. TAB BUTONLARI
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(16)),
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

            // 4. ANALİZ VE DETAY KARTLARI
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      const Text('Fabric Fit & Texture Analysis', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Text('Atelier v4.2', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      _buildInfoCard("Pattern Accuracy", "+99.4%", "Shoulder & Draping Naturalness"),
                      const SizedBox(width: 12),
                      _buildInfoCard("Lighting Integration", "1:1 Studio", "Natural Daylight & Shadows"),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // 5. AKSİYON BUTONLARI
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade900)),
                    child: IconButton(icon: const Icon(Icons.share_outlined, color: Colors.white), onPressed: () {}),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Look confirmed & added to wardrobe!'), backgroundColor: Colors.green));
                      },
                      icon: const Icon(Icons.check, color: Colors.black),
                      label: const Text('Confirm & Add to Wardrobe', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              Icon(icon, color: isActive ? Colors.white : Colors.grey, size: 14),
              const SizedBox(width: 6),
              Text(text, style: TextStyle(color: isActive ? Colors.white : Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
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
        decoration: BoxDecoration(color: const Color(0xFF191919), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade900)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(desc, style: TextStyle(color: Colors.grey.shade600, fontSize: 10, height: 1.3)),
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
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(30)),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
    );
  }
}