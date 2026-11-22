import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../ai/ai_config.dart';
import '../ai/ai_providers.dart';
import '../router/app_router.dart';

class AiSettingsPage extends ConsumerStatefulWidget {
  const AiSettingsPage({super.key});

  @override
  ConsumerState<AiSettingsPage> createState() => _AiSettingsPageState();
}

class _AiSettingsPageState extends ConsumerState<AiSettingsPage> {
  final _keyCtrl = TextEditingController();

  bool? _hasKey;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  @override
  void dispose() {
    _keyCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStatus() async {
    final hasKey = await ref.read(aiKeyStoreProvider).hasKey();
    if (!mounted) return;
    setState(() => _hasKey = hasKey);
  }

  Future<void> _save() async {
    final validation = AiConfig.validateApiKey(_keyCtrl.text);
    if (validation != null) {
      setState(() => _error = validation);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await ref.read(aiKeyStoreProvider).saveKey(_keyCtrl.text);
      ref.invalidate(aiKeyStatusProvider);
      if (!mounted) return;
      _keyCtrl.clear();
      setState(() {
        _hasKey = true;
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API key berhasil disimpan.')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Gagal menyimpan API key. Coba lagi.';
      });
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus API key?'),
        content: const Text(
          'Fitur Campus Assistant tidak dapat digunakan sampai kamu '
          'menambahkan API key lagi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await ref.read(aiKeyStoreProvider).deleteKey();
    ref.invalidate(aiKeyStatusProvider);
    if (!mounted) return;
    setState(() => _hasKey = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('API key dihapus.')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasKey = _hasKey;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Kembali',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
        title: const Text('Pengaturan AI'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withAlpha(22),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.key_rounded, color: colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Status API Key',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hasKey == null
                              ? 'Memeriksa...'
                              : hasKey
                              ? 'Tersimpan di secure storage perangkat.'
                              : 'Belum diatur. Campus Assistant belum aktif.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text(hasKey == true ? 'Aktif' : 'Belum'),
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: hasKey == true
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                    backgroundColor: hasKey == true
                        ? colorScheme.primary.withAlpha(20)
                        : colorScheme.surfaceContainerHighest,
                    side: BorderSide.none,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'API Key Gemini',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Masukkan API key dari Google AI Studio. Key disimpan di '
                    'secure storage dan tidak ditampilkan kembali.',
                    style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _keyCtrl,
                    obscureText: true,
                    autocorrect: false,
                    enableSuggestions: false,
                    keyboardType: TextInputType.visiblePassword,
                    decoration: InputDecoration(
                      hintText: 'Tempel API key di sini',
                      errorText: _error,
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                    ),
                    onChanged: (_) {
                      if (_error != null) setState(() => _error = null);
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _saving ? null : _save,
                          icon: _saving
                              ? const SizedBox(
                                  width: 17,
                                  height: 17,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save_outlined),
                          label: Text(
                            hasKey == true ? 'Ganti API Key' : 'Simpan API Key',
                          ),
                        ),
                      ),
                      if (hasKey == true) ...[
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: _saving ? null : _delete,
                          child: const Text('Hapus'),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.help_outline_rounded,
                        size: 20,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Cara mendapatkan API key',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const _Step(
                    number: '1',
                    text: 'Buka Google AI Studio dan masuk dengan akun Google.',
                  ),
                  const _Step(
                    number: '2',
                    text: 'Pilih menu API Keys, lalu buat API key baru.',
                  ),
                  const _Step(
                    number: '3',
                    text: 'Salin key, tempel di kolom di atas, lalu simpan.',
                  ),
                  const SizedBox(height: 6),
                  SelectableText(
                    'https://aistudio.google.com/apikey',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Provider & model',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(label: 'Provider', value: 'Google Gemini API'),
                  _InfoRow(label: 'Model', value: AiConfig.model),
                  const _InfoRow(label: 'Respons', value: 'Streaming (SSE)'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer.withAlpha(80),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_outlined, size: 20, color: colorScheme.error),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'API key di aplikasi client tetap berisiko diekstrak. Untuk '
                    'produksi, gunakan backend proxy agar key tidak berada di '
                    'perangkat pengguna.',
                    style: TextStyle(fontSize: 12, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colorScheme.primary.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12.5))),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 78,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
