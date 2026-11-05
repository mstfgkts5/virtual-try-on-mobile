import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../core/design/widgets.dart';
import '../core/l10n_ext.dart';
import '../models/tryon_request.dart';
import '../services/api_service.dart';
import 'result_screen.dart';

class LoadingScreen extends StatefulWidget {
  final Uint8List personImageBytes;
  final Uint8List garmentImageBytes;
  final String category; // 'upper', 'lower', 'overall'

  /// Verilmezse uygulamanın ApiService'i kullanılır; testlerde backend'e gitmeyen sahte servis verilir.
  final ApiService? api;

  const LoadingScreen({
    super.key,
    required this.personImageBytes,
    required this.garmentImageBytes,
    this.category = 'upper',
    this.api,
  });

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  double progress = 0.0;
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();
    _processVirtualTryOn();
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  Future<void> _processVirtualTryOn() async {
    // Tahmini ilerleme: yerel GPU'da işlem ~17 sn (15 adım · 576x768) sürdüğü için %90'a ~20 sn'de ulaşır,
    // backend yanıt verince %100'e tamamlanır
    _progressTimer = Timer.periodic(const Duration(milliseconds: 220), (timer) {
      if (!mounted || progress >= 0.89) {
        timer.cancel();
        return;
      }
      setState(() => progress += 0.01);
    });

    try {
      // Sunucu adresi (web / emülatör / telefon) ve kategori ApiService üzerinden yönetilir
      final result = await (widget.api ?? ApiService()).processVirtualTryOn(
        TryOnRequest(
          personImageBytes: widget.personImageBytes,
          garmentImageBytes: widget.garmentImageBytes,
          category: widget.category,
        ),
      );
      _progressTimer?.cancel();
      if (!mounted) return;

      setState(() => progress = 1.0);
      await Future.delayed(const Duration(milliseconds: 400));

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ResultScreen(
              // Backend'in kırptığı fotoğraf: sonuçla aynı kadraj, karşılaştırma hizalı olur
              originalImageBytes: result.originalPersonBytes ?? widget.personImageBytes,
              generatedImageBytes: result.resultImageBytes!,
              category: result.category,
              renderTimeSec: result.renderTimeSec,
            ),
          ),
        );
      }
    } catch (e) {
      _progressTimer?.cancel();
      debugPrint('[LoadingScreen] Hata: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.loadingFailed(ApiService.friendlyError(context.l10n, e))),
          backgroundColor: context.tokens.danger,
          duration: const Duration(seconds: 5),
        ),
      );
      Navigator.pop(context);
    }
  }

  String get _categoryBadge {
    final l = context.l10n;
    return switch (widget.category) {
      'lower' => l.categoryBadgeLower,
      'overall' => l.categoryBadgeOverall,
      _ => l.categoryBadgeUpper,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final percent = (progress * 100).toInt();

    final steps = [
      (l.loadingStepMask, l.loadingStepMaskDesc, progress > 0.3, progress <= 0.3),
      (l.loadingStepDiffusion, l.loadingStepDiffusionDesc, progress > 0.7, progress > 0.3 && progress <= 0.7),
      (l.loadingStepBlend, l.loadingStepBlendDesc, progress == 1.0, progress > 0.7 && progress < 1.0),
    ];

    return Scaffold(
      backgroundColor: t.paper,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: EditorialOverline(l.loadingEngine)),
                  IconButton(
                    tooltip: l.loadingCancel,
                    icon: Icon(Icons.close, color: t.ink, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Kişi fotoğrafı: yumuşak örtü altında, ortada ince ilerleme halkası
              ClipRRect(
                borderRadius: BorderRadius.circular(SeeItOnTokens.radiusLg),
                child: SizedBox(
                  height: 300,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.memory(widget.personImageBytes, fit: BoxFit.cover),
                      ColoredBox(color: t.paper.withValues(alpha: 0.45)),
                      Center(
                        child: SizedBox(
                          width: 72,
                          height: 72,
                          child: CircularProgressIndicator(strokeWidth: 1.5, color: t.accent),
                        ),
                      ),
                      Positioned(
                        top: 14,
                        left: 14,
                        child: _PhotoLabel(_categoryBadge),
                      ),
                      Positioned(
                        bottom: 14,
                        left: 0,
                        right: 0,
                        child: Center(child: _PhotoLabel(l.loadingModelRunning)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: EditorialHeading(l.loadingTitle, size: 26)),
                  const SizedBox(width: 12),
                  Text('$percent%', style: text.displaySmall!.copyWith(fontSize: 34)),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: t.line,
                color: t.accent,
                minHeight: 2,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: Caption(l.loadingEta)),
                  Caption(progress > 0.8 ? l.loadingFinalTouches : l.loadingProcessing, italic: true),
                ],
              ),
              const SizedBox(height: 24),

              // Adımlar: derginin içindekiler sayfası gibi numaralı liste
              for (var i = 0; i < steps.length; i++) ...[
                const HairlineDivider(),
                _StepRow(
                  number: i + 1,
                  title: steps[i].$1,
                  subtitle: steps[i].$2,
                  isDone: steps[i].$3,
                  isActive: steps[i].$4,
                ),
              ],
              const HairlineDivider(),
              const SizedBox(height: 24),

              Center(
                child: PillButton(
                  label: l.loadingCancel,
                  icon: Icons.stop_circle_outlined,
                  primary: false,
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fotoğraf üstü etiket: her iki temada fotoğrafın üstünde okunması için sabit koyu zemin.
class _PhotoLabel extends StatelessWidget {
  const _PhotoLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(SeeItOnTokens.radiusPill),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall!.copyWith(color: Colors.white, letterSpacing: 1.2),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.isDone,
    required this.isActive,
  });

  final int number;
  final String title;
  final String subtitle;
  final bool isDone;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final status = isDone ? l.statusDone : (isActive ? l.statusProcessing : l.statusQueued);
    final statusColor = isDone ? t.ink : (isActive ? t.accent : t.muted);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Text('0$number', style: text.labelSmall!.copyWith(color: t.accent)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: text.headlineSmall!.copyWith(
                    fontSize: 17,
                    color: isDone || isActive ? t.ink : t.muted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: text.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isDone)
            Icon(Icons.check, size: 16, color: statusColor)
          else
            Text(status, style: text.labelSmall!.copyWith(color: statusColor)),
        ],
      ),
    );
  }
}
