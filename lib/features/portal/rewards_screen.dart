import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/skeleton_loader.dart';

class RewardsScreen extends ConsumerStatefulWidget {
  final String email;
  final String tenantId;
  final int currentPoints;

  const RewardsScreen({
    super.key,
    required this.email,
    required this.tenantId,
    required this.currentPoints,
  });

  @override
  ConsumerState<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends ConsumerState<RewardsScreen> {
  bool _isLoading = true;
  List<dynamic> _rewards = [];
  String? _error;
  late int _puntosActuales;
  String? _selectedRewardId;

  @override
  void initState() {
    super.initState();
    _puntosActuales = widget.currentPoints;
    _cargarPremios();
  }

  Future<void> _cargarPremios() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _selectedRewardId = null;
    });
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.getRewards(widget.tenantId);

      if (response.statusCode == 200) {
        setState(() => _rewards = response.data);
      } else {
        setState(() => _error = 'Error al cargar premios');
      }
    } catch (e) {
      setState(() => _error = 'Error de conexión: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _ejecutarCanje(dynamic reward, {String? shippingAddress}) async {
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.redeemReward(
        tenantId: widget.tenantId,
        guestEmail: widget.email,
        rewardName: reward['name'],
        pointsToRedeem: reward['pointsCost'],
        isPhysical: reward['isPhysical'],
        shippingAddress: shippingAddress,
        rewardId: reward['id'],
      );

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _puntosActuales -= reward['pointsCost'] as int;
            _selectedRewardId = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🎉 ¡Canje exitoso! Te quedan $_puntosActuales puntos.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al canjear: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      rethrow;
    }
  }

  void _abrirConfirmacion(dynamic reward) {
    final addressController = TextEditingController();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            final isPhysical = reward['isPhysical'] as bool;
            final pointsCost = reward['pointsCost'] as int;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24, right: 24, top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  Icon(
                    isPhysical ? Icons.local_shipping : Icons.card_giftcard,
                    size: 60,
                    color: Colors.indigoAccent,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    reward['name'],
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Costo: $pointsCost puntos',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.greenAccent, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),

                  if (isPhysical) ...[
                    const Text(
                      'Este premio requiere envío físico. Ingresa tu dirección:',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: addressController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Calle, número, colonia, CP...',
                        hintStyle: const TextStyle(color: Colors.white30),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Saldo después del canje:', style: TextStyle(color: Colors.white70)),
                        Text(
                          '${_puntosActuales - pointsCost} pts',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            if (isPhysical && addressController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Por favor, ingresa una dirección de envío.'), backgroundColor: Colors.orange),
                              );
                              return;
                            }

                            setStateModal(() => isSaving = true);
                            
                            try {
                              await _ejecutarCanje(
                                reward,
                                shippingAddress: isPhysical ? addressController.text.trim() : null,
                              );
                              if (modalContext.mounted) Navigator.pop(modalContext);
                            } catch (e) {
                              setStateModal(() => isSaving = false);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigoAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: isSaving
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Confirmar Canje', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: isSaving ? null : () => Navigator.pop(modalContext),
                    child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    dynamic selectedReward;
    if (_selectedRewardId != null) {
      selectedReward = _rewards.firstWhere((r) => r['id'] == _selectedRewardId);
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context, _puntosActuales != widget.currentPoints);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          title: const Text('Catálogo de Recompensas'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _puntosActuales != widget.currentPoints),
          ),
          actions: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Chip(
                  label: Text('$_puntosActuales pts', style: const TextStyle(fontWeight: FontWeight.bold)),
                  backgroundColor: Colors.indigoAccent.withValues(alpha: 0.2),
                  labelStyle: const TextStyle(color: Colors.indigoAccent),
                  side: BorderSide.none,
                ),
              ),
            )
          ],
        ),
        body: _buildBody(),
        bottomNavigationBar: _selectedRewardId != null && selectedReward != null
            ? SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: () => _abrirConfirmacion(selectedReward),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigoAccent,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 10,
                      shadowColor: Colors.indigoAccent.withValues(alpha: 0.5),
                    ),
                    child: Text(
                      'Canjear: ${selectedReward['name']}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.8,
        ),
        itemCount: 6,
        itemBuilder: (context, index) => Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const Expanded(
                flex: 2, 
                child: SkeletonBox(width: double.infinity, height: double.infinity, borderRadius: 16)
              ),
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      SkeletonBox(width: 60, height: 12),
                      SizedBox(height: 8),
                      SkeletonBox(width: 40, height: 10),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 60),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _cargarPremios, child: const Text('Reintentar')),
          ],
        ),
      );
    }

    if (_rewards.isEmpty) {
      return const Center(
        child: Text('No hay premios disponibles.', style: TextStyle(color: Colors.white54)),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: _rewards.length,
      itemBuilder: (context, index) {
        final reward = _rewards[index];
        final pointsCost = reward['pointsCost'] as int;
        final canAfford = _puntosActuales >= pointsCost;
        final pointsMissing = pointsCost - _puntosActuales;
        final isSelected = _selectedRewardId == reward['id'];

        return GestureDetector(
          onTap: canAfford 
              ? () {
                  setState(() {
                    if (isSelected) {
                      _selectedRewardId = null;
                    } else {
                      _selectedRewardId = reward['id'];
                    }
                  });
                }
              : null,
          child: Container(
            decoration: BoxDecoration(
              color: isSelected 
                  ? Colors.indigo.withValues(alpha: 0.2) 
                  : (canAfford ? const Color(0xFF1E293B) : const Color(0xFF0F172A)),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected 
                    ? Colors.indigoAccent
                    : (canAfford ? Colors.indigo.withValues(alpha: 0.2) : Colors.white10),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: (canAfford || isSelected) ? Colors.indigo.withValues(alpha: 0.1) : Colors.transparent,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: Icon(
                      reward['isPhysical'] ? Icons.local_shipping : Icons.card_giftcard,
                      size: 40,
                      color: (canAfford || isSelected) ? Colors.indigoAccent : Colors.white24,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          reward['name'],
                          style: TextStyle(
                            color: canAfford ? Colors.white : Colors.white54,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${reward['pointsCost']} pts',
                              style: TextStyle(
                                color: canAfford ? Colors.greenAccent : Colors.redAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            if (!canAfford)
                              Text(
                                'Faltan $pointsMissing pts',
                                style: const TextStyle(color: Colors.redAccent, fontSize: 10),
                              ),
                          ],
                        ),
                        if (isSelected)
                          const Center(
                            child: Icon(Icons.check_circle, color: Colors.indigoAccent, size: 20),
                          )
                        else if (!canAfford)
                          const Center(
                            child: Icon(Icons.lock, color: Colors.white24, size: 16),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
