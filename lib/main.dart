import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/portal/guest_portal_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: ClientApp(),
    ),
  );
}

class ClientApp extends StatelessWidget {
  const ClientApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Loyalty Benefit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const GuestPortalScreen(), // 👈 Arranca directo en el Portal del Huésped
    );
  }
}
