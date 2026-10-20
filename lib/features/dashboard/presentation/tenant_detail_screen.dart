import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tenant_model.dart';
import 'customer_form_screen.dart'; // 👈 Importamos la nueva pantalla

class TenantDetailScreen extends ConsumerWidget {
  final TenantModel tenant;

  const TenantDetailScreen({super.key, required this.tenant});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tenant.name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Información de la Empresa', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    _buildInfoRow('Nombre:', tenant.name),
                    _buildInfoRow('Código:', tenant.code),
                    _buildInfoRow('ID:', tenant.id),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Sucursales y Clientes', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const Expanded(
              child: Center(
                child: Text(
                  'Aquí se mostrará la lista de clientes y sucursales.\nPróximamente...',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
      // 👇 BOTÓN FLOTANTE PARA AGREGAR CLIENTE
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CustomerFormScreen()),
          );
        },
        icon: const Icon(Icons.person_add),
        label: const Text('Nuevo Cliente'),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
