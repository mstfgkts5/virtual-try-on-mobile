import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/tryon_provider.dart';
import '../services/api_service.dart';

class AppModals {
  /// Opens dialog to paste an e-commerce image URL
  static void showPasteUrlDialog(BuildContext context) {
    final controller = TextEditingController(text: 'https://images.unsplash.com/photo-1539109136881-3be0616acf4b');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131722),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF283042)),
        ),
        title: const Row(
          children: [
            Icon(Icons.link_rounded, color: AppColors.accentBlue, size: 22),
            SizedBox(width: 8),
            Text('Paste Garment URL', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter an image URL from Zara, ASOS, or any online store:',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF0C0E14),
                hintText: 'https://...',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF222838)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              children: [
                ActionChip(
                  label: const Text('Zara Blazer', style: TextStyle(fontSize: 11, color: Colors.white)),
                  backgroundColor: const Color(0xFF1B202D),
                  onPressed: () {
                    final provider = context.read<TryOnProvider>();
                    provider.loadGarmentPreset(provider.capsuleItems[2]);
                    Navigator.pop(ctx);
                  },
                ),
                ActionChip(
                  label: const Text('Silk Dress', style: TextStyle(fontSize: 11, color: Colors.white)),
                  backgroundColor: const Color(0xFF1B202D),
                  onPressed: () {
                    final provider = context.read<TryOnProvider>();
                    provider.loadGarmentPreset(provider.capsuleItems[1]);
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: () {
              // Load the default capsule blazer as URL sample
              final provider = context.read<TryOnProvider>();
              provider.loadGarmentPreset(provider.capsuleItems[2]);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Garment loaded from URL successfully!'),
                  backgroundColor: Color(0xFF10B981),
                ),
              );
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  /// Opens bottom sheet to pick from past looks
  static void showPastLooksSheet(BuildContext context) {
    final provider = context.read<TryOnProvider>();
    final renders = provider.recentRenders;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF12151E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Past Silhouette',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF1F2535),
                child: Icon(Icons.face, color: Colors.white),
              ),
              title: const Text('Muse Elena (Studio Preset)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              subtitle: const Text('Neutral studio background, 4K fit', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              onTap: () {
                provider.loadMuseElenaPreset();
                Navigator.pop(ctx);
              },
            ),
            const Divider(color: Color(0xFF222838)),
            ...renders.map((render) => ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: render.resultAssetPath != null
                          ? Image.asset(render.resultAssetPath!, fit: BoxFit.cover)
                          : const Icon(Icons.person, color: Colors.white),
                    ),
                  ),
                  title: Text(render.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  subtitle: Text('Rendered ${render.fitScore}% fit', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  onTap: () {
                    provider.loadMuseElenaPreset();
                    Navigator.pop(ctx);
                  },
                )),
          ],
        ),
      ),
    );
  }

  /// Opens Curated Picks designer catalog
  static void showCuratedPicksModal(BuildContext context) {
    final provider = context.read<TryOnProvider>();
    final items = provider.capsuleItems;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF10131B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Curated Designer Capsule',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Select any runway garment to drape onto your silhouette:',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    onTap: () {
                      provider.loadGarmentPreset(item);
                      Navigator.pop(ctx);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161B26),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF242C3D)),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(item.assetPath, width: 50, height: 50, fit: BoxFit.cover),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                const SizedBox(height: 2),
                                Text('${item.designer} • ${item.category}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                              ],
                            ),
                          ),
                          Text(item.price, style: const TextStyle(color: AppColors.accentGold, fontWeight: FontWeight.w600, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  /// Opens Backend Settings and Config Dialog
  static void showSettingsDialog(BuildContext context) {
    final apiService = ApiService();
    final urlController = TextEditingController(text: apiService.baseUrl);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF131722),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFF283042)),
          ),
          title: const Row(
            children: [
              Icon(Icons.tune_rounded, color: Colors.white, size: 22),
              SizedBox(width: 8),
              Text('API Configuration', style: TextStyle(color: Colors.white, fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Python FastAPI Backend Base URL:',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: urlController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF0C0E14),
                  hintText: 'http://10.0.2.2:8000',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF222838)),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Simulated Mock Fallback:', style: TextStyle(color: Colors.white, fontSize: 13)),
                  Switch(
                    value: apiService.useMockMode,
                    activeColor: Colors.white,
                    onChanged: (val) {
                      setState(() {
                        apiService.useMockMode = val;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'If your FastAPI IDM-VTON server is offline, fallback mode ensures full interactive simulation without errors.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                apiService.baseUrl = urlController.text;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('API Configuration updated successfully!'),
                    backgroundColor: Color(0xFF10B981),
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  /// Opens Notifications Sheet
  static void showNotificationsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF12151E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Notifications', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close, color: AppColors.textSecondary), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFF21283B), child: Icon(Icons.bolt, color: AppColors.accentBlue)),
              title: const Text('IDM-VTON Engine Online', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text('Diffusion pipeline is ready for unlimited virtual fittings.', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFF21283B), child: Icon(Icons.auto_awesome, color: AppColors.accentBlue)),
              title: const Text('Neural Drape v3.2 Active', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text('4K micro-draping and wrinkle tension updated.', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}
