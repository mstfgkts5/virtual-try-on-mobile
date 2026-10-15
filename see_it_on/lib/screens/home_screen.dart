import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'loading_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Uint8List? _personImageBytes;
  Uint8List? _garmentImageBytes;
  final ImagePicker _picker = ImagePicker();

  bool _lockPose = false;
  String _selectedFit = "Tailored";
  int _currentNavigationIndex = 0;

  Future<void> _pickImage(bool isPerson) async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
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
                      ? 'Please upload your photo (Step 1) first!'
                      : 'Please select a garment (Step 2) to try on!',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFE11D48),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }
    
    // BURASI GÜNCELLENDİ: Sadece insan resmini değil, tüm ayarları LoadingScreen'e yolluyoruz
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoadingScreen(
          personImageBytes: _personImageBytes!,
          garmentImageBytes: _garmentImageBytes!,
          fitType: _selectedFit,
          lockPose: _lockPose,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Görseldeki zarif açık arka plan rengi
    const backgroundColor = Color(0xFFF6F4EF); 
    const textColor = Color(0xFF1E1C1A); // Koyu kahve/siyah metin rengi

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: textColor.withValues(alpha: 0.05), shape: BoxShape.circle),
              child: const Icon(Icons.blur_on, color: textColor, size: 16),
            ),
            const SizedBox(width: 10),
            const Text('SeeItOn', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_outlined, color: textColor), onPressed: () {}),
          IconButton(icon: const Icon(Icons.person_outline, color: textColor), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // BAŞLIKLAR
              const SizedBox(height: 10),
              const Text(
                'Studio Fitting Room', 
                style: TextStyle(
                  color: textColor, 
                  fontSize: 32, 
                  fontFamily: 'Georgia', // Serif font ile lüks görünüm
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.5
                )
              ),
              const SizedBox(height: 4),
              Text(
                'Fuse your silhouette with any luxury piece in real time.', 
                style: TextStyle(color: textColor.withValues(alpha: 0.6), fontSize: 13)
              ),
              const SizedBox(height: 24),

              // STEP 1 & STEP 2 ARASI ORTAK BAĞLANTI ALANI (KARTLAR VE ZİNCİR)
              Stack(
                alignment: Alignment.center,
                children: [
                  Column(
                    children: [
                      // STEP 1: YOUR SILHOUETTE
                      _buildUploadCard(
                        title: "STEP 1  •  Your Silhouette",
                        isPerson: true,
                        imageBytes: _personImageBytes,
                        icon: Icons.add_a_photo_outlined,
                        mainText: "Upload Your Photo",
                        subText: "Full-length editorial pose or clear front\nmirror selfie",
                        buttons: [
                          _buildCardButton(Icons.photo_library_outlined, "Gallery", () => _pickImage(true)),
                          _buildCardButton(Icons.camera_alt_outlined, "Camera", () {}),
                          _buildCardButton(Icons.history, "Past Look", () {}, isRound: true),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // STEP 2: GARMENT TO TRY
                      _buildUploadCard(
                        title: "STEP 2  •  Garment to Try",
                        isPerson: false,
                        imageBytes: _garmentImageBytes,
                        icon: Icons.checkroom,
                        mainText: "Upload Garment",
                        subText: "Screenshot e-commerce catalog, flat-\nlay, or snap in-store",
                        buttons: [
                          _buildCardButton(Icons.link, "Paste URL", () {}),
                          _buildCardButton(Icons.person_outline, "From Wardrobe", () => _pickImage(false)),
                          _buildCardButton(Icons.check_circle_outline, "Curated Picks", () {}),
                        ],
                      ),
                    ],
                  ),
                  
                  // ORTADAKİ ZİNCİR / BAĞLANTI İKONU
                  IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFF0EBE1), width: 1),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, spreadRadius: 2)
                        ]
                      ),
                      child: const Icon(Icons.link, color: textColor, size: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // NEURAL FIT CONTROLS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.tune, color: textColor, size: 18),
                      SizedBox(width: 8),
                      Text('Neural Fit\nControls', style: TextStyle(color: textColor, fontSize: 13, height: 1.2)),
                    ],
                  ),
                  Row(
                    children: [
                      Text('Lock Pose', style: TextStyle(color: textColor.withValues(alpha: 0.6), fontSize: 12)),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 24,
                        child: Switch(
                          value: _lockPose,
                          activeColor: Colors.white,
                          activeTrackColor: textColor,
                          inactiveThumbColor: Colors.white,
                          inactiveTrackColor: Colors.grey.shade400,
                          onChanged: (val) {
                            setState(() {
                              _lockPose = val;
                            });
                          },
                        ),
                      ),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 12),
              
              // FIT SEÇENEKLERİ (Tailored, Regular, Oversized)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: textColor.withValues(alpha: 0.05), 
                  borderRadius: BorderRadius.circular(30)
                ),
                child: Row(
                  children: [
                    _buildFitOption("Tailored", textColor),
                    _buildFitOption("Regular", textColor),
                    _buildFitOption("Oversized", textColor),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // MAIN TRY ON BUTTON (Koyu Kahve/Siyah Buton)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _onTryOnPressed(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF221F1E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
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
                          fontFamily: 'Georgia', // Butondaki Serif Font
                          fontWeight: FontWeight.bold
                        )
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15), 
                          borderRadius: BorderRadius.circular(12)
                        ),
                        child: const Text('Try On', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              // İşlem süresi metinleri
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.access_time, color: textColor.withValues(alpha: 0.5), size: 12),
                  const SizedBox(width: 4),
                  Text('~3.8s Processing', style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 12)),
                  const SizedBox(width: 12),
                  Text('•', style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 12)),
                  const SizedBox(width: 12),
                  Icon(Icons.layers, color: textColor.withValues(alpha: 0.5), size: 12),
                  const SizedBox(width: 4),
                  Text('4K Micro-Drape', style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 12)),
                ],
              ),
              const SizedBox(height: 32),

              // RECENT RENDERS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('RECENT RENDERS', style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  TextButton(
                    onPressed: () {},
                    child: Row(
                      children: [
                        Text('Wardrobe History', style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios, color: textColor, size: 10),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  // Sahte render sonuçları (Buraya kendi uygulamanın geçmiş fotoları gelecek)
                  _buildRenderCard("Wool Trench", "Fit: 98% Match"),
                  const SizedBox(width: 16),
                  _buildRenderCard("Ivory Silk Shirt", "Fit: 95% Match"),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      // ALT NAVİGASYON BARI (Açık Tema Uyarlaması)
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(canvasColor: const Color(0xFFF0EBE1)),
        child: BottomNavigationBar(
          currentIndex: _currentNavigationIndex,
          onTap: (index) {
            setState(() {
              _currentNavigationIndex = index;
            });
          },
          selectedItemColor: textColor,
          unselectedItemColor: textColor.withValues(alpha: 0.4),
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
          unselectedLabelStyle: const TextStyle(fontSize: 10, letterSpacing: 1),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.auto_awesome), label: 'TRY ON'),
            BottomNavigationBarItem(icon: Icon(Icons.checkroom), label: 'WARDROBE'),
            BottomNavigationBarItem(icon: Icon(Icons.tune), label: 'PROFILE'),
          ],
        ),
      ),
    );
  }

  // YARDIMCI WIDGET'LAR AŞAĞIDADIR

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
        color: Colors.white.withValues(alpha: 0.4), // Hafif saydam beyaz
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 2), // Beyaz çerçeve
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: textColor.withValues(alpha: 0.6), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 16),
          
          // Beyaz Yuvarlak İçindeki Fotoğraf/İkon Alanı
          GestureDetector(
            onTap: () => _pickImage(isPerson),
            child: Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, spreadRadius: 2)
                ],
                image: imageBytes != null
                    ? DecorationImage(image: MemoryImage(imageBytes), fit: BoxFit.contain)
                    : null,
              ),
              child: imageBytes == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // İkonun olduğu küçük yuvarlak
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(color: Color(0xFFF0EBE1), shape: BoxShape.circle),
                          child: Icon(icon, color: textColor.withValues(alpha: 0.6), size: 24),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          mainText, 
                          style: const TextStyle(color: textColor, fontSize: 16, fontFamily: 'Georgia', fontWeight: FontWeight.bold)
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subText, 
                          textAlign: TextAlign.center, 
                          style: TextStyle(color: textColor.withValues(alpha: 0.6), fontSize: 11, height: 1.4)
                        ),
                      ],
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          // Butonları wrap ile diziyoruz (Taşma yapmasın diye)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: buttons,
          )
        ],
      ),
    );
  }

  Widget _buildCardButton(IconData icon, String label, VoidCallback onTap, {bool isRound = false}) {
    const textColor = Color(0xFF1E1C1A);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(isRound ? 30 : 12),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: isRound ? 16 : 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.transparent, 
          borderRadius: BorderRadius.circular(isRound ? 30 : 12), 
          border: Border.all(color: textColor.withValues(alpha: 0.15))
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: textColor.withValues(alpha: 0.6), size: 14),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildFitOption(String label, Color textColor) {
    bool isSelected = _selectedFit == label;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFit = label;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF221F1E) : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : textColor.withValues(alpha: 0.6), 
                fontSize: 12, 
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Sonuç geçmişi kartı
  Widget _buildRenderCard(String title, String match) {
    return Expanded(
      child: Container(
        height: 240,
        decoration: BoxDecoration(
          color: Colors.black, // Orijinal fotoda içi karanlık
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Buraya normalde network'ten veya assets'den resim gelecek.
            // Şimdilik boş gri bir kutu koyduk.
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.image, color: Colors.white24, size: 50),
            ),
            
            // Alt Kısım Metinleri
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(match, style: const TextStyle(color: Colors.white70, fontSize: 10)),
                ],
              ),
            ),
            
            // Göz İkonu
            Positioned(
              bottom: 14,
              right: 14,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                child: const Icon(Icons.remove_red_eye, color: Colors.white, size: 12),
              ),
            )
          ],
        ),
      ),
    );
  }
}