import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/design/widgets.dart';
import '../core/l10n_ext.dart';
import '../services/auth_errors.dart';
import '../services/storage_service.dart';
import '../services/wardrobe_repository.dart';

class ResultScreen extends StatefulWidget {
  final Uint8List originalImageBytes; // Modele giren (3:4 kırpılmış) kişi fotoğrafı
  final Uint8List generatedImageBytes; // AI'dan dönen giydirilmiş fotoğraf
  final String category; // 'upper', 'lower', 'overall'
  final double renderTimeSec;

  /// Verilmezse Supabase kullanılır; testlerde sahte depo verilir.
  final WardrobeRepository? wardrobe;

  const ResultScreen({
    super.key,
    required this.originalImageBytes,
    required this.generatedImageBytes,
    this.category = 'upper',
    this.renderTimeSec = 0,
    this.wardrobe,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _isSaving = false;
  double _sliderValue = 0.5; // Split mode sürgüsü için
  double _fadeValue = 0.5; // Fade mode şeffaflığı için
  String _activeTab = 'split'; // 'split' / 'side' / 'fade'

  void _snack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: error ? context.tokens.danger : null),
    );
  }

  // Gardıroba kaydetme: görsel kullanıcının klasörüne yüklenir, kategoriyle birlikte satır eklenir
  Future<void> _saveToWardrobe() async {
    setState(() => _isSaving = true);
    try {
      await (widget.wardrobe ?? SupabaseWardrobeRepository()).add(widget.generatedImageBytes, widget.category);
      if (mounted) _snack(context.l10n.resultWardrobeSaved);
    } catch (e) {
      debugPrint('[ResultScreen] Gardıroba kaydetme hatası: $e');
      if (mounted) {
        final l = context.l10n;
        _snack(
          e is NotSignedInException ? l.resultNeedLogin : l.resultWardrobeError(authErrorMessage(l, e)),
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveToGallery() async {
    final ok = await StorageService().saveToGallery(widget.generatedImageBytes);
    if (!mounted) return;
    final l = context.l10n;
    _snack(
      ok ? l.resultGallerySaved : (kIsWeb ? l.resultGalleryWeb : l.resultGalleryFailed),
      error: !ok,
    );
  }

  // Tam ekran görüntüleme: fotoğraf her iki temada siyah zeminde gösterilir
  void _openFullScreenView(Uint8List imageBytes, String title) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(),
        child: Stack(
          fit: StackFit.expand,
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.memory(imageBytes, fit: BoxFit.contain),
            ),
            Positioned(top: 40, left: 20, child: _LabelBadge(text: title, color: Colors.black54)),
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

  Widget _image(Uint8List bytes) => Image.memory(bytes, fit: BoxFit.cover, filterQuality: FilterQuality.high);

  Widget _buildImageComparisonArea() {
    final l = context.l10n;
    if (_activeTab == 'side') {
      return Stack(
        fit: StackFit.expand,
        children: [
          Row(
            children: [
              Expanded(child: _image(widget.originalImageBytes)),
              Container(width: 2, color: Colors.white24),
              Expanded(child: _image(widget.generatedImageBytes)),
            ],
          ),
          _buildFullScreenButton(),
        ],
      );
    } else if (_activeTab == 'fade') {
      return Stack(
        fit: StackFit.expand,
        children: [
          _image(widget.originalImageBytes),
          Opacity(opacity: _fadeValue, child: _image(widget.generatedImageBytes)),
          _buildFullScreenButton(),
        ],
      );
    }
    // Varsayılan: Split Slider. Konum ekran genişliğine değil kartın kendi genişliğine göre
    // hesaplanır; aksi halde kenar boşlukları yüzünden tutamaç ile kesim çizgisi kayıyor
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return GestureDetector(
          onHorizontalDragUpdate: (details) {
            setState(() => _sliderValue = (details.localPosition.dx / width).clamp(0.0, 1.0));
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              _image(widget.originalImageBytes),
              Positioned(top: 16, left: 16, child: _LabelBadge(text: l.resultBefore, color: Colors.black54)),
              ClipRect(clipper: _SplitImageClipper(_sliderValue), child: _image(widget.generatedImageBytes)),
              Positioned(
                top: 16,
                right: 16,
                child: ClipRect(
                  clipper: _SplitImageClipper(1.0 - _sliderValue),
                  child: _LabelBadge(text: l.resultAfter, color: Colors.black38),
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
                      child: const Icon(Icons.unfold_more_outlined, color: Colors.white, size: 16),
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

  Widget _buildFullScreenButton() {
    final l = context.l10n;
    return Positioned(
      bottom: 16,
      left: 0,
      right: 0,
      child: Center(
        child: GestureDetector(
          onTap: () => _openFullScreenView(widget.generatedImageBytes, l.resultTitle(categoryName(l, widget.category))),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(SeeItOnTokens.radiusPill),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.fullscreen, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                  l.resultFullScreen,
                  style: Theme.of(context).textTheme.labelLarge!.copyWith(color: Colors.white, fontSize: 12),
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
    final l = context.l10n;
    final t = context.tokens;
    final category = categoryName(l, widget.category);
    final seconds = widget.renderTimeSec.toStringAsFixed(1);

    return Scaffold(
      backgroundColor: t.paper,
      appBar: AppBar(
        title: const Text('SeeItOn'),
        actions: [
          IconButton(
            tooltip: l.resultSaveToGallery,
            icon: const Icon(Icons.download_outlined),
            onPressed: _saveToGallery,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EditorialOverline(l.resultOverline),
            const SizedBox(height: 4),
            EditorialHeading(l.resultHeading, size: 28),
            const SizedBox(height: 6),
            Caption(l.resultSubtitle),
            const SizedBox(height: 18),

            // Sonuç 3:4 (768x1024) olduğu için kutu da 3:4; geniş ekranda görsel kırpılmaz
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: AspectRatio(
                  aspectRatio: 3 / 4,
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(SeeItOnTokens.radiusLg),
                      border: Border.all(color: t.line),
                    ),
                    child: _buildImageComparisonArea(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Caption(l.resultCaption(category, seconds), italic: true, textAlign: TextAlign.center),
            const SizedBox(height: 14),

            if (_activeTab == 'fade')
              Row(
                children: [
                  Icon(Icons.person_outline, color: t.muted, size: 18),
                  Expanded(
                    child: Slider(value: _fadeValue, onChanged: (val) => setState(() => _fadeValue = val)),
                  ),
                  Icon(Icons.checkroom, color: t.ink, size: 18),
                ],
              ),

            SegmentedPills<String>(
              options: [('split', l.resultTabSplit), ('side', l.resultTabSide), ('fade', l.resultTabFade)],
              icons: const {
                'split': Icons.splitscreen_outlined,
                'side': Icons.grid_view_outlined,
                'fade': Icons.blur_on_outlined,
              },
              value: _activeTab,
              onChanged: (id) => setState(() => _activeTab = id),
            ),
            const HairlineDivider(verticalPadding: 22),

            Row(
              children: [
                EditorialOverline(l.resultDetails),
                const SizedBox(width: 12),
                // Dar ekranda / büyük yazı ölçeğinde taşmasın: sağa yaslı, gerekirse kısaltılır
                Expanded(
                  child: Text(
                    l.resultEngine,
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Gösterilen değerler backend'in ölçtüğü gerçek değerlerdir
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildInfoCard(l.resultRenderTime, l.resultSeconds(seconds), l.resultRenderTimeDesc),
                  const SizedBox(width: 12),
                  _buildInfoCard(l.resultCategory, category, l.resultCategoryDesc),
                ],
              ),
            ),
            const SizedBox(height: 28),

            Row(
              children: [
                Material(
                  color: Colors.transparent,
                  shape: CircleBorder(side: BorderSide(color: t.line)),
                  child: IconButton(
                    tooltip: l.resultShareText,
                    icon: Icon(Icons.share_outlined, color: t.ink),
                    onPressed: () => StorageService().shareOutfit(widget.generatedImageBytes, message: l.resultShareText),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PillButton(
                    label: _isSaving ? l.resultSaving : l.resultAddToWardrobe,
                    icon: Icons.check,
                    expand: true,
                    busy: _isSaving,
                    onPressed: _saveToWardrobe,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, String desc) {
    final text = Theme.of(context).textTheme;
    return Expanded(
      child: EditorialCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            EditorialOverline(title),
            const SizedBox(height: 6),
            Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.headlineSmall),
            const SizedBox(height: 6),
            Text(desc, style: text.bodySmall!.copyWith(height: 1.3)),
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
  Rect getClip(Size size) => Rect.fromLTRB(size.width * value, 0.0, size.width, size.height);

  @override
  bool shouldReclip(_SplitImageClipper oldClipper) => oldClipper.value != value;
}

/// Fotoğraf üstü etiket; her iki temada fotoğrafın üstünde okunur.
class _LabelBadge extends StatelessWidget {
  final String text;
  final Color color;
  const _LabelBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(SeeItOnTokens.radiusPill)),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall!.copyWith(color: Colors.white, letterSpacing: 1.0),
      ),
    );
  }
}
