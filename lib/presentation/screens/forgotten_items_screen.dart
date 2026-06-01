import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants.dart';
import '../../domain/entities/forgotten_item.dart';
import '../providers/trip_history_provider.dart';

/// Ranking de ítems más olvidados al registrar salidas.
class ForgottenItemsScreen extends StatefulWidget {
  const ForgottenItemsScreen({super.key});

  @override
  State<ForgottenItemsScreen> createState() => _ForgottenItemsScreenState();
}

class _ForgottenItemsScreenState extends State<ForgottenItemsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TripHistoryProvider>().loadForgottenItems();
    });
  }

  String _exitTypeLabel(String id) {
    final type = AppConstants.exitTypes.firstWhere(
      (t) => t['id'] == id,
      orElse: () => {'emoji': '📋', 'nombre': id},
    );
    return '${type['emoji']} ${type['nombre']}';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TripHistoryProvider>();
    final colors = Theme.of(context).colorScheme;
    final items = provider.forgottenItems;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Olvidos'),
      ),
      body: items.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline,
                        size: 72, color: Colors.green.withOpacity(0.5)),
                    const SizedBox(height: 16),
                    const Text(
                      '¡Nada olvidado!',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Cuando registres una salida con ítems sin completar, aparecerán aquí.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colors.primary.withOpacity(0.15),
                        colors.secondary.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Text('🧠', style: TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${items.length} ítems en el ranking · ${items.fold<int>(0, (s, i) => s + i.veces)} olvidos en total',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ...items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return _ForgottenTile(
                    rank: index + 1,
                    item: item,
                    exitTypeLabel: _exitTypeLabel,
                    formatDate: _formatDate,
                  ).animate(delay: (index * 40).ms).fadeIn().slideX(begin: 0.05);
                }),
              ],
            ),
    );
  }
}

class _ForgottenTile extends StatelessWidget {
  final int rank;
  final ForgottenItem item;
  final String Function(String) exitTypeLabel;
  final String Function(DateTime) formatDate;

  const _ForgottenTile({
    required this.rank,
    required this.item,
    required this.exitTypeLabel,
    required this.formatDate,
  });

  Color _rankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700);
      case 2:
        return const Color(0xFFC0C0C0);
      case 3:
        return const Color(0xFFCD7F32);
      default:
        return const Color(0xFF6C5CE7);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _rankColor(rank).withOpacity(0.2),
          child: Text(
            '#$rank',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: rank <= 3 ? _rankColor(rank) : colors.primary,
            ),
          ),
        ),
        title: Text(item.nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${exitTypeLabel(item.tipoSalida)} · Último: ${formatDate(item.ultimaFecha)}',
          style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFE17055).withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${item.veces}×',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFFE17055),
            ),
          ),
        ),
      ),
    );
  }
}
