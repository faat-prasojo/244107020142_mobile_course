import 'package:flutter/material.dart';

const double kWideBreakpoint = 600.0; // Disesuaikan agar responsif di bawah batas ConstrainedBox

void main() => runApp(const ProfileApp());

class ProfileApp extends StatefulWidget {
  const ProfileApp({super.key});

  @override
  State<ProfileApp> createState() => _ProfileAppState();
}

class _ProfileAppState extends State<ProfileApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme(bool isDark) {
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Profil Mahasiswa',
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Colors.grey[100],
        cardColor: Colors.white,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Colors.grey[900],
        cardColor: Colors.grey[800],
      ),
      themeMode: _themeMode,
      home: ProfileScreen(
        themeMode: _themeMode,
        onThemeChanged: _toggleTheme,
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  final ThemeMode themeMode;
  final ValueChanged<bool> onThemeChanged;

  const ProfileScreen({
    super.key,
    required this.themeMode,
    required this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Mahasiswa'),
        actions: [
          Semantics(
            label: 'Tombol pengalih tema gelap dan terang',
            child: Row(
              children: [
                Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode),
                Switch.adaptive(
                  value: isDarkMode,
                  onChanged: onThemeChanged,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            // Card ini yang jadi target find.byType(Card) di widget_test.dart.
            // Widthnya otomatis ngikutin ConstrainedBox: dibatasi maxWidth 700 saat layar
            // lebar, dan menyusut sesuai physicalSize saat layar sempit.
            child: const Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ProfileHeader(),
                    SizedBox(height: 20),
                    InfoCardsGrid(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Semantics(
      label: 'Header profil mahasiswa: Faatihurrizki Prasojo',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4)
              : theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 30,
              child: Icon(Icons.person, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nama Mahasiswa',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Faatihurrizki Prasojo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
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

class InfoCardsGrid extends StatelessWidget {
  const InfoCardsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> infoList = [
      {'label': 'NIM', 'value': '244107020142'},
      {'label': 'Kelas', 'value': 'TI_3D'},
      {'label': 'Program Studi', 'value': 'Teknik Informatika'},
      {'label': 'Angkatan', 'value': '2024'},
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Pakai kWideBreakpoint sebagai satu-satunya sumber kebenaran untuk breakpoint,
        // biar nggak ada inkonsistensi antara konstanta yang dideklarasikan dan logic aktual
        bool isWideScreen = constraints.maxWidth >= kWideBreakpoint;

        if (isWideScreen) {
          List<Widget> rows = [];
          for (int i = 0; i < infoList.length; i += 2) {
            rows.add(
              Row(
                key: Key('info_row_${i ~/ 2}'),
                children: [
                  Expanded(
                    child: InfoCard(
                      key: Key('info_card_$i'),
                      label: infoList[i]['label']!,
                      value: infoList[i]['value']!,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: i + 1 < infoList.length
                        ? InfoCard(
                            key: Key('info_card_${i + 1}'),
                            label: infoList[i + 1]['label']!,
                            value: infoList[i + 1]['value']!,
                          )
                        : const SizedBox(),
                  ),
                ],
              ),
            );
            if (i + 2 < infoList.length) {
              rows.add(const SizedBox(height: 12));
            }
          }
          return Column(key: const Key('info_grid_wide'), children: rows);
        } else {
          return Column(
            key: const Key('info_grid_narrow'),
            children: infoList.asMap().entries.map((entry) {
              final i = entry.key;
              final info = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InfoCard(
                  key: Key('info_card_$i'),
                  label: info['label']!,
                  value: info['value']!,
                ),
              );
            }).toList(),
          );
        }
      },
    );
  }
}

class InfoCard extends StatelessWidget {
  final String label;
  final String value;

  const InfoCard({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: 'Informasi $label: $value',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                maxLines: 1,
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}