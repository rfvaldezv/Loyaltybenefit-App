import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/portal/guest_portal_screen.dart'; // <-- Ruta correcta

void main() {
  runApp(
    const ProviderScope(
      child: LoyaltyApp(),
    ),
  );
}

class LoyaltyApp extends StatelessWidget {
  const LoyaltyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Loyalty Benefit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const GuestPortalScreen(), // <-- Ahora sí lo encuentra
    );
  }
}
