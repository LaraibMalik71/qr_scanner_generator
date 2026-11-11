import 'package:flutter/material.dart';

import 'screens/home/home_screen.dart';
import 'utils/app_theme.dart';

import 'package:provider/provider.dart';

import 'providers/qr_provider.dart';
import 'providers/theme_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => QRProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()..loadTheme()),
      ],
      child: const QRScannerApp(),
    ),
  );
}

class QRScannerApp extends StatelessWidget {
  const QRScannerApp({super.key});

  @override
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'QR Code Scanner',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          home: const HomeScreen(),
        );
      },
    );
  }
}
