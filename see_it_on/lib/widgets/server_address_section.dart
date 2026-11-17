import 'package:flutter/material.dart';

import '../core/design/widgets.dart';
import '../core/l10n_ext.dart';
import '../services/api_service.dart';

/// Ayarlar'da sunucu adresi: telefon uygulaması (APK) yapay zeka sunucusunu bu adreste arar.
/// Kaydedince adres hemen kullanılır, cihazda saklanır ve bağlantı denenir.
class ServerAddressSection extends StatefulWidget {
  const ServerAddressSection({super.key, this.api});

  /// Verilmezse uygulamanın ApiService'i kullanılır; testlerde sahte servis verilir.
  final ApiService? api;

  @override
  State<ServerAddressSection> createState() => _ServerAddressSectionState();
}

class _ServerAddressSectionState extends State<ServerAddressSection> {
  late final ApiService _api = widget.api ?? ApiService();
  late final _controller = TextEditingController(text: _api.baseUrl);
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveAndTest() async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final url = ApiService.normalizeServerUrl(_controller.text);
    if (url == null) {
      messenger.showSnackBar(SnackBar(content: Text(l.settingsServerInvalid)));
      return;
    }
    setState(() => _busy = true);
    _controller.text = url;
    await _api.saveBaseUrl(url);
    final ok = await _api.checkBackendHealth();
    if (!mounted) return;
    setState(() => _busy = false);
    messenger.showSnackBar(SnackBar(
      content: Text(ok ? l.settingsServerOk : l.settingsServerFail),
      backgroundColor: ok ? null : context.tokens.danger,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EditorialOverline(l.settingsServer),
        const SizedBox(height: 10),
        TextField(
          key: const Key('serverAddress'),
          controller: _controller,
          keyboardType: TextInputType.url,
          autocorrect: false,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _saveAndTest(),
          decoration: const InputDecoration(prefixIcon: Icon(Icons.dns_outlined)),
        ),
        const SizedBox(height: 8),
        Caption(l.settingsServerHint),
        const SizedBox(height: 12),
        PillButton(
          label: l.settingsServerSave,
          icon: Icons.wifi_tethering,
          expand: true,
          busy: _busy,
          onPressed: _saveAndTest,
        ),
      ],
    );
  }
}
