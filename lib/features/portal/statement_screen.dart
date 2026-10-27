import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/network/api_client.dart';

class StatementScreen extends ConsumerStatefulWidget {
  final String email;
  final String tenantId;

  const StatementScreen({super.key, required this.email, required this.tenantId});

  @override
  ConsumerState<StatementScreen> createState() => _StatementScreenState();
}

class _StatementScreenState extends ConsumerState<StatementScreen> {
  bool _isLoading = true;
  List<dynamic> _movimientos = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
  }

  Future<void> _cargarHistorial() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final api = ref.read(apiClientProvider);
      final response = await api.getStatement(widget.email, widget.tenantId);

      if (response.statusCode == 200) {
        setState(() {
          _movimientos = response.data['movimientos'] ?? [];
        });
      } else {
        setState(() => _error = 'Error al cargar el historial');
      }
    } catch (e) {
      setState(() => _error = 'Error de conexión: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Fondo oscuro Fintech
      appBar: AppBar(
        title: const Text('Mi Historial'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.indigoAccent))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.redAccent, size: 60),
                      const SizedBox(height: 16),
                      Text(_error!, style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _cargarHistorial, child: const Text('Reintentar')),
                    ],
                  ),
                )
              : _movimientos.isEmpty
                  ? const Center(
                      child: Text(
                        'Aún no tienes movimientos.\n¡Empieza a acumular puntos!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white54, fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _movimientos.length,
                      itemBuilder: (context, index) {
                        final mov = _movimientos[index];
                        final points = mov['points'] as int;
                        final isEarn = points > 0;
                        final date = DateTime.parse(mov['date']).toLocal();
                        final formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(date);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B), // Tarjeta oscura
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                            backgroundColor: isEarn ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
                              child: Icon(
                                isEarn ? Icons.add : Icons.remove,
                                color: isEarn ? Colors.greenAccent : Colors.redAccent,
                              ),
                            ),
                            title: Text(
                              mov['description'] ?? (isEarn ? 'Puntos ganados' : 'Canje de premio'),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              formattedDate,
                              style: const TextStyle(color: Colors.white54, fontSize: 12),
                            ),
                            trailing: Text(
                              '${isEarn ? '+' : ''}$points pts',
                              style: TextStyle(
                                color: isEarn ? Colors.greenAccent : Colors.redAccent,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
