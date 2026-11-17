import 'package:flutter/material.dart';

import '../core/consent_controller.dart';
import '../core/design/widgets.dart';
import '../core/l10n_ext.dart';

/// KVKK aydınlatma metni ve açık rıza ekranı.
///
/// İlk girişte [AuthGate] bunu ana ekrandan önce gösterir; kullanıcı kutuyu işaretleyip
/// onaylamadan fotoğraf yükleyemez. Ayarlar'dan [readOnly] açılırsa metin yeniden okunur
/// ve rıza geri çekilebilir.
class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key, this.readOnly = false, this.controller});

  final bool readOnly;

  /// Verilmezse uygulama genelindeki [consentController] kullanılır (testlerde dışarıdan verilir).
  final ConsentController? controller;

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool _checked = false;

  ConsentController get _controller => widget.controller ?? consentController;

  Future<void> _withdraw() async {
    await _controller.withdraw();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.consentWithdrawn)));
    // Kök ekran (AuthGate) rıza olmadığı için bu metni yeniden gösterir
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final sections = [
      (l.consentDataTitle, l.consentDataBody),
      (l.consentPurposeTitle, l.consentPurposeBody),
      (l.consentStorageTitle, l.consentStorageBody),
      (l.consentRightsTitle, l.consentRightsBody),
    ];
    return Scaffold(
      backgroundColor: context.tokens.paper,
      appBar: widget.readOnly ? AppBar() : null,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    EditorialOverline(l.consentOverline),
                    const SizedBox(height: 8),
                    EditorialHeading(l.consentTitle),
                    const SizedBox(height: 12),
                    Text(l.consentIntro, style: textTheme.bodyMedium),
                    for (final (title, body) in sections) ...[
                      const HairlineDivider(verticalPadding: 16),
                      EditorialOverline(title),
                      const SizedBox(height: 8),
                      Text(body, style: textTheme.bodyMedium),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: widget.readOnly
                  ? PillButton(
                      label: l.consentWithdraw,
                      icon: Icons.undo,
                      expand: true,
                      onPressed: _controller.value ? _withdraw : null,
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CheckboxListTile(
                          value: _checked,
                          onChanged: (v) => setState(() => _checked = v ?? false),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                          title: Text(l.consentCheckbox, style: textTheme.bodySmall),
                        ),
                        const SizedBox(height: 8),
                        PillButton(
                          label: l.consentAccept,
                          icon: Icons.check,
                          primary: true,
                          expand: true,
                          onPressed: _checked ? _controller.accept : null,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
