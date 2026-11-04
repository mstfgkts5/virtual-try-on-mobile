import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'loading_screen.dart';
import 'wardrobe_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Uint8List? _personImageBytes;
  Uint8List? _garmentImageBytes;
  final ImagePicker _picker = ImagePicker();

  // Denenecek kıyafet bölgesi: backend'e 'upper' / 'lower' / 'overall' olarak gider
  String _category = 'upper';
  static const _categories = [
    {
      'id': 'upper',
      'label': 'Üst Giyim',
      'icon': Icons.checkroom,
      'hint': 'Tişört, gömlek, kazak, ceket\nveya hırka fotoğrafı',
    },
    {
      'id': 'lower',
      'label': 'Alt Giyim',
      'icon': Icons.straighten,
      'hint':
          'Pantolon, etek veya şort\nfotoğrafı (tam boy kişi fotoğrafı önerilir)',
    },
    {
      'id': 'overall',
      'label': 'Tam Kıyafet',
      'icon': Icons.accessibility_new,
      'hint': 'Elbise veya tulum\nfotoğrafı (tam boy kişi fotoğrafı önerilir)',
    },
  ];
  Map<String, Object> get _selectedCategory =>
      _categories.firstWhere((c) => c['id'] == _category);

  int _currentNavigationIndex = 0;
  late PageController _rackController;
  int _currentRackIndex = 1;

  final List<Map<String, dynamic>> _rackItems = [
    {'name': 'Vintage Leather', 'type': 'Jacket', 'color': 0xFF2C2C2C},
    {'name': 'Crimson Memory', 'type': 'LS Shirt', 'color': 0xFF8B0000},
    {'name': 'Silk Button-up', 'type': 'Shirt', 'color': 0xFFFDF5E6},
    {'name': 'Denim Over-shirt', 'type': 'Jacket', 'color': 0xFF4682B4},
  ];

  @override
  void initState() {
    super.initState();
    _rackController = PageController(
      viewportFraction: 0.35,
      initialPage: _currentRackIndex,
    );
  }

  @override
  void dispose() {
    _rackController.dispose();
    super.dispose();
  }

  // tools/generate_mannequins.py ile üretilen hazır mankenler (gerçek kişi fotoğrafı değildir)
  static const _mannequins = [
    {'id': 'w-s', 'label': 'Kadın S', 'info': '160 cm • 50 kg'},
    {'id': 'w-m', 'label': 'Kadın M', 'info': '160 cm • 58 kg'},
    {'id': 'w-l', 'label': 'Kadın L', 'info': '160 cm • 67 kg'},
    {'id': 'w-xl', 'label': 'Kadın XL', 'info': '160 cm • 76 kg'},
    {'id': 'm-s', 'label': 'Erkek S', 'info': '185 cm • 72 kg'},
    {'id': 'm-m', 'label': 'Erkek M', 'info': '185 cm • 80 kg'},
    {'id': 'm-l', 'label': 'Erkek L', 'info': '185 cm • 90 kg'},
    {'id': 'm-xl', 'label': 'Erkek XL', 'info': '185 cm • 100 kg'},
  ];
  static const _sampleGarmentAsset = 'assets/images/sample_garment_blazer.png';

  Future<void> _loadAsset(bool isPerson, String assetPath) async {
    final data = await rootBundle.load(assetPath);
    setState(() {
      if (isPerson) {
        _personImageBytes = data.buffer.asUint8List();
      } else {
        _garmentImageBytes = data.buffer.asUint8List();
      }
    });
  }

  void _showMannequinPicker() {
    const textColor = Color(0xFF1E1C1A);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      backgroundColor: const Color(0xFFF6F4EF),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Hazır Manken Seç', style: TextStyle(color: textColor, fontSize: 20, fontFamily: 'Georgia', fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Kendi fotoğrafın yerine bir bedeni seçerek dene.', style: TextStyle(color: textColor.withValues(alpha: 0.6), fontSize: 12)),
              const SizedBox(height: 16),
              // Kart genişliği sabit tutulur; geniş ekranda (web/tablet) kartlar büyüyüp taşmaz
              GridView(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 110,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.52,
                ),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: _mannequins.map((m) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      _loadAsset(true, 'assets/images/mannequins/${m['id']}.jpg');
                    },
                    child: Column(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.asset('assets/images/mannequins/${m['id']}.jpg', fit: BoxFit.cover, width: double.infinity),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(m['label']!, style: const TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold)),
                        Text(m['info']!, style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 9)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(bool isPerson, ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        if (isPerson) {
          _personImageBytes = bytes;
        } else {
          _garmentImageBytes = bytes;
        }
      });
    }
  }

  void _onTryOnPressed(BuildContext context) {
    if (_personImageBytes == null || _garmentImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _personImageBytes == null
                      ? 'Lütfen önce kendi fotoğrafınızı (Adım 1) yükleyin!'
                      : 'Lütfen denemek istediğiniz kıyafeti (Adım 2) seçin!',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFE11D48),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoadingScreen(
          personImageBytes: _personImageBytes!,
          garmentImageBytes: _garmentImageBytes!,
          category: _category,
        ),
      ),
    );
  }

  void _selectRecommendedGarment(int index) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Kombin seçildi!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFFF6F4EF);
    const textColor = Color(0xFF1E1C1A);

    return Scaffold(
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: textColor.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.blur_on, color: textColor, size: 16),
            ),
            const SizedBox(width: 10),
            const Text(
              'SeeItOn',
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.checkroom, color: textColor),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WardrobeScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: textColor),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: textColor),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                const Text(
                  'Studio Fitting Room',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 32,
                    fontFamily: 'Georgia',
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Kendi stilini saniyeler içinde oluştur.',
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 24),

                _buildCategorySelector(textColor),
                const SizedBox(height: 20),

                Stack(
                  alignment: Alignment.center,
                  children: [
                    Column(
                      children: [
                        _buildUploadCard(
                          title: "ADIM 1  •  Kendi Fotoğrafın",
                          isPerson: true,
                          imageBytes: _personImageBytes,
                          icon: Icons.add_a_photo_outlined,
                          mainText: "Fotoğraf Yükle",
                          subText:
                              "Net bir boy aynası selfie'si\nveya düz durduğunuz bir fotoğraf",
                          buttons: [
                            _buildCardButton(
                              Icons.photo_library_outlined,
                              "Galeri",
                              () => _pickImage(true, ImageSource.gallery),
                            ),
                            _buildCardButton(
                              Icons.camera_alt_outlined,
                              "Kamera",
                              () => _pickImage(true, ImageSource.camera),
                            ),
                            _buildCardButton(
                              Icons.accessibility_new,
                              "Manken",
                              _showMannequinPicker,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        _buildUploadCard(
                          title: "ADIM 2  •  ${_selectedCategory['label']}",
                          isPerson: false,
                          imageBytes: _garmentImageBytes,
                          icon: _selectedCategory['icon'] as IconData,
                          mainText: "Kıyafet Yükle",
                          subText: _selectedCategory['hint'] as String,
                          buttons: [
                            _buildCardButton(
                              Icons.photo_library_outlined,
                              "Galeri",
                              () => _pickImage(false, ImageSource.gallery),
                            ),
                            _buildCardButton(
                              Icons.camera_alt_outlined,
                              "Kamera",
                              () => _pickImage(false, ImageSource.camera),
                            ),
                            if (_category == 'upper')
                              _buildCardButton(
                                Icons.style_outlined,
                                "Örnek",
                                () => _loadAsset(false, _sampleGarmentAsset),
                              ),
                          ],
                        ),
                      ],
                    ),

                    IgnorePointer(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFF0EBE1),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.link,
                          color: textColor,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _onTryOnPressed(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF221F1E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Üzerimde Gör',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontFamily: 'Georgia',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Try On',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                _buildAnimatedRack(textColor),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(canvasColor: const Color(0xFFF0EBE1)),
        child: BottomNavigationBar(
          currentIndex: _currentNavigationIndex,
          onTap: (index) {
            if (index == 1) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WardrobeScreen()),
              );
            } else {
              setState(() {
                _currentNavigationIndex = index;
              });
            }
          },
          selectedItemColor: textColor,
          unselectedItemColor: textColor.withValues(alpha: 0.4),
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 10, letterSpacing: 1),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.auto_awesome),
              label: 'TRY ON',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.checkroom),
              label: 'WARDROBE',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.tune), label: 'PROFILE'),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector(Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'NE DENEMEK İSTİYORSUN?',
          style: TextStyle(
            color: textColor.withValues(alpha: 0.6),
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Row(
            children: _categories.map((c) {
              final isActive = c['id'] == _category;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _category = c['id'] as String),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFF221F1E)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          c['icon'] as IconData,
                          size: 15,
                          color: isActive
                              ? Colors.white
                              : textColor.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            c['label'] as String,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isActive ? Colors.white : textColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedRack(Color textColor) {
    return Column(
      children: [
        Text(
          "GÜNÜN KOMBİN ÖNERİLERİ",
          style: TextStyle(
            color: textColor.withValues(alpha: 0.5),
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 220,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              Positioned(
                top: 30,
                left: 0,
                right: 0,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 2,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              PageView.builder(
                controller: _rackController,
                onPageChanged: (int index) {
                  setState(() {
                    _currentRackIndex = index;
                  });
                },
                itemCount: _rackItems.length,
                itemBuilder: (context, index) {
                  return AnimatedBuilder(
                    animation: _rackController,
                    builder: (context, child) {
                      double value = 1.0;
                      if (_rackController.position.haveDimensions) {
                        value = _rackController.page! - index;
                        value = (1 - (value.abs() * 0.4)).clamp(0.0, 1.0);
                      } else {
                        value = (index == _currentRackIndex) ? 1.0 : 0.6;
                      }

                      return Center(
                        child: Transform.scale(
                          scale: Curves.easeOut.transform(value),
                          child: Opacity(
                            opacity: value.clamp(0.4, 1.0),
                            child: child,
                          ),
                        ),
                      );
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 15,
                          height: 20,
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: Colors.grey.shade600,
                                width: 2,
                              ),
                              left: BorderSide(
                                color: Colors.grey.shade600,
                                width: 2,
                              ),
                              right: BorderSide(
                                color: Colors.grey.shade600,
                                width: 2,
                              ),
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(10),
                              topRight: Radius.circular(10),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            _rackController.animateToPage(
                              index,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: Container(
                            height: 140,
                            width: 100,
                            decoration: BoxDecoration(
                              color: Color(_rackItems[index]['color'] as int),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.checkroom,
                              color: Colors.white54,
                              size: 40,
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
                _rackItems[_currentRackIndex]['name'] as String,
                style: const TextStyle(
                  color: Color(0xFF1E1C1A),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Georgia',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _rackItems[_currentRackIndex]['type'] as String,
                style: TextStyle(
                  color: const Color(0xFF1E1C1A).withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () => _selectRecommendedGarment(_currentRackIndex),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: textColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'BU PARÇAYI SEÇ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
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
  }) {
    const textColor = Color(0xFF1E1C1A);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: textColor.withValues(alpha: 0.6),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),

          GestureDetector(
            onTap: () => _pickImage(isPerson, ImageSource.gallery),
            child: Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
                image: imageBytes != null
                    ? DecorationImage(
                        image: MemoryImage(imageBytes),
                        fit: BoxFit.contain,
                      )
                    : null,
              ),
              child: imageBytes == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF0EBE1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            icon,
                            color: textColor.withValues(alpha: 0.6),
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          mainText,
                          style: const TextStyle(
                            color: textColor,
                            fontSize: 16,
                            fontFamily: 'Georgia',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subText,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: textColor.withValues(alpha: 0.6),
                            fontSize: 11,
                            height: 1.4,
                          ),
                        ),
                      ],
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: buttons,
          ),
        ],
      ),
    );
  }

  Widget _buildCardButton(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool isRound = false,
  }) {
    const textColor = Color(0xFF1E1C1A);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(isRound ? 30 : 12),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isRound ? 16 : 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(isRound ? 30 : 12),
          border: Border.all(color: textColor.withValues(alpha: 0.15)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: textColor.withValues(alpha: 0.6), size: 14),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
