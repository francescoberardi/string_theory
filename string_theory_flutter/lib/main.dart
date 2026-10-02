import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'client.dart';
import 'screens/greetings_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeClient();
  runApp(const MyApp());
}

/// Builds the Court Midnight theme.
ThemeData _buildCourtMidnightTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFF121516),
    colorScheme: const ColorScheme.dark(
      surface: Color(0xFF1A1E20),
      primary: Color(0xFFC6F10E),
      onPrimary: Colors.black,
      onSurface: Colors.white,
      outline: Color(0xFF2A3034),
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF121516),
      foregroundColor: Colors.white,
      elevation: 0,
      titleTextStyle: GoogleFonts.barlowCondensed(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: 0.5,
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'String Theory',
      theme: _buildCourtMidnightTheme(),
      home: const MyHomePage(title: 'STRING THEORY'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
    // If not authenticated after launch (e.g. offline on first boot), notify user
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!authService.isAuthenticated) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Offline on first launch: unable to provision guest session.',
            ),
            backgroundColor: const Color(0xFFFF9F0A),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.black,
              onPressed: () async {
                try {
                  await authService.loginAsGuest();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Retry failed: $e')),
                    );
                  }
                }
              },
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          ValueListenableBuilder(
            valueListenable: authService.authInfoListenable,
            builder: (context, authInfo, _) {
              final isAuthed = authService.isAuthenticated;
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isAuthed
                      ? const Color(0xFFC6F10E).withValues(alpha: 0.15)
                      : const Color(0xFFFF9F0A).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isAuthed
                        ? const Color(0xFFC6F10E).withValues(alpha: 0.4)
                        : const Color(0xFFFF9F0A).withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.circle,
                      size: 8,
                      color: isAuthed
                          ? const Color(0xFFC6F10E)
                          : const Color(0xFFFF9F0A),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isAuthed ? 'GUEST' : 'OFFLINE',
                      style: GoogleFonts.barlowCondensed(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isAuthed
                            ? const Color(0xFFC6F10E)
                            : const Color(0xFFFF9F0A),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: const GreetingsScreen(),
    );
  }
}
