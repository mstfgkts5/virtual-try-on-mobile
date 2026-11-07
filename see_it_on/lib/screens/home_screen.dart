import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../core/design/widgets.dart';
import '../core/l10n_ext.dart';
import '../models/spin.dart';
import '../models/spin_preset.dart';
import '../services/media_picker.dart';
import 'camera_capture_screen.dart';
import 'loading_screen.dart';
import 'settings_screen.dart';
import 'spin_screen.dart';
import 'wardrobe_screen.dart';

class HomeScreen extends StatefulWidget {
  /// [picker] verilmezse cihazın galeri/kamera seçicisi kullanılır; testlerde sahte seçici verilir.
  const HomeScreen({super.key, this.picker});

  final MediaPicker? picker;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Uint8List? _personImageBytes;
  Uint8List? _garmentImageBytes;
  late final MediaPicker _picker = widget.picker ?? ImagePickerMediaPicker();

  // 360° dönüş: kişi fotoğrafı yerine dönüş videosu; ikisi birden seçili olmaz
  Uint8List? _videoBytes;
  String _videoName = 'turn.mp4';
  Uint8List? _garmentBackBytes;
  SpinPreset? _preset;
  bool _presetLoaded = false;

  // Denenecek kıyafet bölgesi: backend'e 'upper' / 'lower' / 'overall' olarak gider.
  // Metinler (ad, ipucu) çeviri dosyalarında: categoryName / categoryHint.
  // Alt giyim ipucu, CatVTON'un kısa kıyafeti uzun kıyafetin üstüne uzatma sınırını anlatır.
  String _category = 'upper';
  static const _categoryIcons = {
    'upper': Icons.checkroom,
    'lower': Icons.straighten,
    'overall': Icons.accessibility_new,
  };

  int _currentNavigationIndex = 0;
  late PageController _rackController;
  int _currentRackIndex = 1; // Raf, _sampleGarments listesini gösterir

  @override
  void initState() {
    super.initState();
    _rackController = PageController(viewportFraction: 0.35, initialPage: _currentRackIndex);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_presetLoaded) {
      _presetLoaded = true;
      SpinPreset.load(DefaultAssetBundle.of(context)).then((p) {
        if (mounted) setState(() => _preset = p);
      });
    }
  }

  @override
  void dispose() {
    _rackController.dispose();
    super.dispose();
  }

  // tools/generate_mannequins.py ile üretilen hazır mankenler (gerçek kişi fotoğrafı değildir)
  static const _mannequins = [
    {'id': 'w-s', 'info': '160 cm • 50 kg'},
    {'id': 'w-m', 'info': '160 cm • 58 kg'},
    {'id': 'w-l', 'info': '160 cm • 67 kg'},
    {'id': 'w-xl', 'info': '160 cm • 76 kg'},
    {'id': 'm-s', 'info': '185 cm • 72 kg'},
    {'id': 'm-m', 'info': '185 cm • 80 kg'},
    {'id': 'm-l', 'info': '185 cm • 90 kg'},
    {'id': 'm-xl', 'info': '185 cm • 100 kg'},
  ];
  // tools/generate_garments.py ile üretilen örnek ürün fotoğrafları (gerçek marka ürünü değildir)
  static const _sampleGarments = [
    {'id': 'blazer', 'category': 'upper'},
    {'id': 'jeans-w', 'category': 'lower'},
    {'id': 'chino-m', 'category': 'lower'},
    {'id': 'trousers-m', 'category': 'lower'},
    {'id': 'skirt-w', 'category': 'lower'},
    {'id': 'shorts-w', 'category': 'lower'},
  ];
  List<Map<String, String>> get _garmentsForCategory =>
      _sampleGarments.where((g) => g['category'] == _category).toList();

  /// Manken ve örnek kıyafet seçicilerinin ortak alt sayfası
  void _showPickerSheet({
    required String title,
    String? hint,
    Widget Function(BuildContext sheetContext)? header,
    required double maxHeightFactor,
    required double maxCrossAxisExtent,
    required double childAspectRatio,
    required List<({String asset, String name, String? info, VoidCallback onTap})> items,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * maxHeightFactor),
      backgroundColor: context.tokens.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(SeeItOnTokens.radiusLg)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EditorialHeading(title, size: 22),
              if (hint != null) ...[const SizedBox(height: 4), Caption(hint)],
              const HairlineDivider(verticalPadding: 14),
              if (header != null) ...[header(ctx), const SizedBox(height: 14)],
              // Kart genişliği sabit tutulur; geniş ekranda (web/tablet) kartlar büyüyüp taşmaz
              GridView(
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: maxCrossAxisExtent,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 10,
                  childAspectRatio: childAspectRatio,
                ),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  for (final item in items)
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        item.onTap();
                      },
                      child: Column(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(SeeItOnTokens.radiusSm),
                              child: Image.asset(item.asset, fit: BoxFit.cover, width: double.infinity),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(ctx).textTheme.labelLarge!.copyWith(fontSize: 12),
                          ),
                          if (item.info != null) Text(item.info!, style: Theme.of(ctx).textTheme.bodySmall!.copyWith(fontSize: 9)),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showGarmentPicker() {
    final l = context.l10n;
    _showPickerSheet(
      title: l.homeSamplePickerTitle(categoryName(l, _category)),
      maxHeightFactor: 0.7,
      maxCrossAxisExtent: 130,
      childAspectRatio: 0.8,
      items: [
        for (final g in _garmentsForCategory)
          (
            asset: 'assets/images/garments/${g['id']}.jpg',
            name: garmentName(l, g['id']!),
            info: null,
            onTap: () => _loadAsset(false, 'assets/images/garments/${g['id']}.jpg'),
          ),
      ],
    );
  }

  void _showMannequinPicker() {
    final l = context.l10n;
    _showPickerSheet(
      title: l.homeMannequinPickerTitle,
      hint: l.homeMannequinPickerHint,
      header: _preset == null ? null : _buildPresetCard,
      maxHeightFactor: 0.85,
      maxCrossAxisExtent: 110,
      childAspectRatio: 0.52,
      items: [
        for (final m in _mannequins)
          (
            asset: 'assets/images/mannequins/${m['id']}.jpg',
            name: mannequinName(l, m['id']!),
            info: m['info'],
            onTap: () => _loadAsset(true, 'assets/images/mannequins/${m['id']}.jpg'),
          ),
      ],
    );
  }

  void _openSettings() => pushEditorial(context, const SettingsScreen());
  void _openWardrobe() => pushEditorial(context, const WardrobeScreen());

  Future<void> _loadAsset(bool isPerson, String assetPath) async {
    final data = await rootBundle.load(assetPath);
    setState(() {
      if (isPerson) {
        _videoBytes = null;
        _personImageBytes = data.buffer.asUint8List();
      } else {
        _garmentImageBytes = data.buffer.asUint8List();
      }
    });
  }

  Future<void> _pickImage(bool isPerson, ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        if (isPerson) {
          _videoBytes = null;
          _personImageBytes = bytes;
        } else {
          _garmentImageBytes = bytes;
        }
      });
    }
  }

  // Uygulama içi kamera: silüet rehberli tam boy çekim; galeriye geçilirse galeri seçici açılır
  Future<void> _openCamera() async {
    final result = await pushEditorial<Object>(context, const CameraCaptureScreen());
    if (!mounted) return;
    if (result is Uint8List) {
      setState(() {
        _videoBytes = null;
        _personImageBytes = result;
      });
    } else if (result == CameraResult.gallery) {
      await _pickImage(true, ImageSource.gallery);
    }
  }

  // Backend sınırı (spin_frames.MAX_VIDEO_BYTES); büyük video boşuna yüklenmesin
  static const _maxVideoBytes = 60 * 1024 * 1024;

  Future<void> _pickVideo() async {
    final file = await _picker.pickVideo(ImageSource.gallery);
    if (file == null) return;
    if (await file.length() > _maxVideoBytes) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.homeSpinTooLarge), backgroundColor: context.tokens.danger),
      );
      return;
    }
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _personImageBytes = null;
      _videoBytes = bytes;
      _videoName = file.name.isEmpty ? 'turn.mp4' : file.name;
    });
  }

  Future<void> _pickGarmentBack() async {
    final file = await _picker.pickImage(ImageSource.gallery);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (mounted) setState(() => _garmentBackBytes = bytes);
  }

  void _openPreset(BuildContext sheetContext) {
    final preset = _preset!;
    Navigator.pop(sheetContext);
    final bundle = DefaultAssetBundle.of(context);
    pushEditorial(
      context,
      SpinScreen.preset(
        frames: [for (final path in preset.framePaths) AssetImage(path, bundle: bundle)],
        title: preset.title(Localizations.localeOf(context).languageCode),
      ),
    );
  }

  Widget _buildPresetCard(BuildContext sheetContext) {
    final t = context.tokens;
    final preset = _preset!;
    return Material(
      color: t.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SeeItOnTokens.radiusMd),
        side: BorderSide(color: t.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openPreset(sheetContext),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(SeeItOnTokens.radiusSm),
                child: Image(
                  image: AssetImage(preset.framePaths.first, bundle: DefaultAssetBundle.of(context)),
                  width: 54,
                  height: 72,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.l10n.homeSpinPreset, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Caption(preset.title(Localizations.localeOf(context).languageCode), italic: true),
                  ],
                ),
              ),
              Icon(Icons.threesixty, color: t.accent),
            ],
          ),
        ),
      ),
    );
  }

  // 2. adım: dönüşte arka kareler için kıyafetin arka görseli (isteğe bağlı)
  Widget _buildGarmentBackRow() {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: InkWell(
        onTap: _pickGarmentBack,
        borderRadius: BorderRadius.circular(SeeItOnTokens.radiusSm),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 56,
              decoration: BoxDecoration(
                color: t.paper,
                borderRadius: BorderRadius.circular(SeeItOnTokens.radiusSm),
                border: Border.all(color: t.line),
                image: _garmentBackBytes == null
                    ? null
                    : DecorationImage(image: MemoryImage(_garmentBackBytes!), fit: BoxFit.cover),
              ),
              child: _garmentBackBytes == null ? Icon(Icons.flip, color: t.muted, size: 18) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                context.l10n.homeGarmentBack,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge!.copyWith(fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onTryOnPressed(BuildContext context) {
    if (_videoBytes != null && _garmentImageBytes != null) {
      pushEditorial(
        context,
        SpinScreen.live(
          request: SpinRequest(
            videoBytes: _videoBytes!,
            videoName: _videoName,
            garmentFront: _garmentImageBytes!,
            garmentBack: _garmentBackBytes,
            category: _category,
          ),
        ),
      );
      return;
    }
    if ((_personImageBytes == null && _videoBytes == null) || _garmentImageBytes == null) {
      final t = context.tokens;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: t.danger,
          margin: const EdgeInsets.all(16),
          content: Row(
            children: [
              Icon(Icons.info_outline, color: t.paper, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _personImageBytes == null && _videoBytes == null ? context.l10n.homeNeedPerson : context.l10n.homeNeedGarment,
                  style: TextStyle(color: t.paper, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }

    pushEditorial(
      context,
      LoadingScreen(
        personImageBytes: _personImageBytes!,
        garmentImageBytes: _garmentImageBytes!,
        category: _category,
      ),
    );
  }

  // Raftaki kıyafeti 2. adıma yükler ve kategoriyi kıyafete göre değiştirir
  Future<void> _selectRackGarment(int index) async {
    final garment = _sampleGarments[index];
    setState(() => _category = garment['category']!);
    await _loadAsset(false, 'assets/images/garments/${garment['id']}.jpg');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.homeRackSelected(garmentName(context.l10n, garment['id']!))),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;

    return Scaffold(
      backgroundColor: t.paper,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('SeeItOn'),
        actions: [
          IconButton(tooltip: l.navWardrobe, icon: const Icon(Icons.checkroom_outlined), onPressed: _openWardrobe),
          IconButton(tooltip: l.navProfile, icon: const Icon(Icons.person_outline), onPressed: _openSettings),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              EditorialHeading(l.homeTitle),
              const SizedBox(height: 4),
              Caption(l.homeSubtitle, italic: true),
              const HairlineDivider(verticalPadding: 18),

              EditorialOverline(l.homeWhatToTry),
              const SizedBox(height: 10),
              SegmentedPills<String>(
                options: [for (final id in _categoryIcons.keys) (id, categoryName(l, id))],
                icons: _categoryIcons,
                value: _category,
                onChanged: (id) => setState(() => _category = id),
              ),
              const SizedBox(height: 20),

              Stack(
                alignment: Alignment.center,
                children: [
                  Column(
                    children: [
                      _buildUploadCard(
                        title: l.homeStepPerson,
                        isPerson: true,
                        imageBytes: _personImageBytes,
                        icon: _videoBytes != null ? Icons.threesixty : Icons.add_a_photo_outlined,
                        mainText: _videoBytes != null ? l.homeSpinSelected : l.homeUploadPhoto,
                        subText: _videoBytes != null ? l.homeSpinHint : l.homeUploadPhotoHint,
                        buttons: [
                          _buildCardButton(Icons.photo_library_outlined, l.homeGallery, () => _pickImage(true, ImageSource.gallery)),
                          _buildCardButton(Icons.camera_alt_outlined, l.homeCamera, _openCamera),
                          _buildCardButton(Icons.accessibility_new, l.homeMannequin, _showMannequinPicker),
                          _buildCardButton(Icons.threesixty, l.homeSpinVideo, _pickVideo),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildUploadCard(
                        title: l.homeStepGarment(categoryName(l, _category)),
                        isPerson: false,
                        imageBytes: _garmentImageBytes,
                        icon: _categoryIcons[_category]!,
                        mainText: l.homeUploadGarment,
                        subText: categoryHint(l, _category),
                        buttons: [
                          _buildCardButton(Icons.photo_library_outlined, l.homeGallery, () => _pickImage(false, ImageSource.gallery)),
                          _buildCardButton(Icons.camera_alt_outlined, l.homeCamera, () => _pickImage(false, ImageSource.camera)),
                          if (_garmentsForCategory.isNotEmpty)
                            _buildCardButton(Icons.style_outlined, l.homeSample, _showGarmentPicker),
                        ],
                        footer: _videoBytes == null ? null : _buildGarmentBackRow(),
                      ),
                    ],
                  ),
                  // İki adımı birbirine bağlayan küçük düğüm
                  IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: t.paper,
                        shape: BoxShape.circle,
                        border: Border.all(color: t.line),
                      ),
                      child: Icon(Icons.link, color: t.ink, size: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              PillButton(
                label: l.homeTryOn,
                icon: Icons.auto_awesome,
                expand: true,
                onPressed: () => _onTryOnPressed(context),
              ),
              const HairlineDivider(verticalPadding: 28),

              _buildAnimatedRack(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(border: Border(top: BorderSide(color: t.line))),
        child: BottomNavigationBar(
          currentIndex: _currentNavigationIndex,
          onTap: (index) {
            if (index == 1) {
              _openWardrobe();
            } else if (index == 2) {
              _openSettings();
            } else {
              setState(() => _currentNavigationIndex = index);
            }
          },
          items: [
            BottomNavigationBarItem(icon: const Icon(Icons.auto_awesome), label: l.navTryOn),
            BottomNavigationBarItem(icon: const Icon(Icons.checkroom), label: l.navWardrobe),
            BottomNavigationBarItem(icon: const Icon(Icons.tune), label: l.navProfile),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedRack() {
    final l = context.l10n;
    final t = context.tokens;
    final current = _sampleGarments[_currentRackIndex];
    return Column(
      children: [
        EditorialOverline(l.homeRackTitle),
        const SizedBox(height: 20),
        SizedBox(
          height: 220,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              // Askı çubuğu
              Positioned(
                top: 30,
                left: 0,
                right: 0,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(color: t.muted, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              PageView.builder(
                controller: _rackController,
                onPageChanged: (index) => setState(() => _currentRackIndex = index),
                itemCount: _sampleGarments.length,
                itemBuilder: (context, index) {
                  return AnimatedBuilder(
                    animation: _rackController,
                    builder: (context, child) {
                      double value;
                      if (_rackController.position.haveDimensions) {
                        value = _rackController.page! - index;
                        value = (1 - (value.abs() * 0.4)).clamp(0.0, 1.0);
                      } else {
                        value = (index == _currentRackIndex) ? 1.0 : 0.6;
                      }
                      return Center(
                        child: Transform.scale(
                          scale: Curves.easeOut.transform(value),
                          child: Opacity(opacity: value.clamp(0.4, 1.0), child: child),
                        ),
                      );
                    },
                    child: Column(
                      children: [
                        // Askı kancası
                        Container(
                          width: 15,
                          height: 20,
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(color: t.muted, width: 2),
                              left: BorderSide(color: t.muted, width: 2),
                              right: BorderSide(color: t.muted, width: 2),
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(10),
                              topRight: Radius.circular(10),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _rackController.animateToPage(
                            index,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          ),
                          child: Container(
                            height: 140,
                            width: 100,
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              color: t.surface,
                              borderRadius: BorderRadius.circular(SeeItOnTokens.radiusSm),
                              border: Border.all(color: t.line),
                            ),
                            child: Image.asset(
                              'assets/images/garments/${_sampleGarments[index]['id']}.jpg',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Column(
            key: ValueKey<int>(_currentRackIndex),
            children: [
              Text(
                garmentName(l, current['id']!),
                style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 2),
              Caption(categoryName(l, current['category']!), italic: true),
              const SizedBox(height: 12),
              PillButton(
                label: l.homeRackSelect,
                onPressed: () => _selectRackGarment(_currentRackIndex),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUploadCard({
    required String title,
    required bool isPerson,
    required Uint8List? imageBytes,
    required IconData icon,
    required String mainText,
    required String subText,
    required List<Widget> buttons,
    Widget? footer,
  }) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    return EditorialCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EditorialOverline(title),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => _pickImage(isPerson, ImageSource.gallery),
            child: Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                color: t.paper,
                borderRadius: BorderRadius.circular(SeeItOnTokens.radiusMd),
                border: Border.all(color: t.line),
                image: imageBytes != null
                    ? DecorationImage(image: MemoryImage(imageBytes), fit: BoxFit.contain)
                    : null,
              ),
              child: imageBytes == null
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icon, color: t.muted, size: 26),
                          const SizedBox(height: 10),
                          Text(mainText, style: text.headlineSmall!.copyWith(fontSize: 17)),
                          const SizedBox(height: 6),
                          Text(
                            subText,
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: text.bodySmall!.copyWith(height: 1.4),
                          ),
                        ],
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: buttons),
          ),
          ?footer,
        ],
      ),
    );
  }

  Widget _buildCardButton(IconData icon, String label, VoidCallback onTap) {
    final t = context.tokens;
    return Material(
      color: Colors.transparent,
      shape: StadiumBorder(side: BorderSide(color: t.line)),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: t.muted, size: 14),
              const SizedBox(width: 6),
              Text(label, style: Theme.of(context).textTheme.labelLarge!.copyWith(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
