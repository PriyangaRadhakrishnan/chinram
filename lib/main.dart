import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/authentication/screens/splash_screen.dart';

void main() {
  runApp(const ChinramApp());
}

class ChinramApp extends StatelessWidget {
  const ChinramApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chinram',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
