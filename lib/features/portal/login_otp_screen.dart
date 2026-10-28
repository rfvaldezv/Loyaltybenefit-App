import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import 'guest_portal_screen.dart';

class LoginOtpScreen extends ConsumerStatefulWidget {
  const LoginOtpScreen({super.key});

  @override
  ConsumerState<LoginOtpScreen> createState() => _LoginOtpScreenState();
}

class _LoginOtpScreenState extends ConsumerState<LoginOtpScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _codeFocusNode = FocusNode(); // Para forzar el teclado
  
  bool _isLoading = false;
  bool _isCodeSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _codeFocusNode.dispose();
    super.dispose();
  }

  Future<void> _solicitarOtp() async {
    if (_emailController.text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.requestOtp(_emailController.text.trim());
      
      if (response.statusCode == 200) {
        setState(() => _isCodeSent = true);
        
        // Forzamos a que el teclado se active en el campo del código
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) _codeFocusNode.requestFocus();
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Código enviado. (Simulado: ${response.data['debug_otp']})'), 
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } on DioException catch (e) {
      String mensaje = 'Error de conexión';
      if (e.response?.statusCode == 404) mensaje = 'El correo no está registrado.';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensaje), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verificarOtp() async {
    if (_codeController.text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.verifyOtp(_emailController.text.trim(), _codeController.text.trim());
      
      if (response.statusCode == 200) {
        final firstName = response.data['firstName'] as String?;
        final email = response.data['email'] as String?;
        
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => GuestPortalScreen(
                initialEmail: email ?? _emailController.text.trim(),
                initialName: firstName ?? '',
              ),
            ),
          );
        }
      }
    } on DioException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Código inválido o expirado.'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(32.0),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isCodeSent ? Icons.sms_outlined : Icons.lock_person_outlined, 
                  size: 80, 
                  color: Colors.indigoAccent
                ),
                const SizedBox(height: 24),
                Text(
                  _isCodeSent ? 'Ingresa el código' : 'Bienvenido',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  _isCodeSent ? 'Enviamos un código de 6 dígitos a tu correo' : 'Ingresa sin contraseñas',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.white54),
                ),
                const SizedBox(height: 32),
                
                // PASO 1: CORREO
                if (!_isCodeSent) ...[
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Tu correo electrónico',
                      labelStyle: const TextStyle(color: Colors.white54),
                      prefixIcon: const Icon(Icons.email, color: Colors.white54),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _solicitarOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigoAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Enviar Código', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                
                // PASO 2: CÓDIGO
                ] else ...[
                  TextField(
                    controller: _codeController,
                    focusNode: _codeFocusNode,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: '------',
                      hintStyle: const TextStyle(color: Colors.white24, letterSpacing: 8),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    maxLength: 6,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _verificarOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Ingresar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isCodeSent = false;
                        _codeController.clear();
                      });
                    },
                    child: const Text('Usar otro correo', style: TextStyle(color: Colors.white54)),
                  )
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
