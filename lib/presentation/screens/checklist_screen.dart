import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants.dart';
import '../../data/datasources/local/shared_prefs_helper.dart';
import '../../domain/entities/item.dart';
import '../providers/checklist_provider.dart';
import '../providers/weather_provider.dart';
import '../widgets/checklist_item_tile.dart';
import '../widgets/weather_card.dart';
import '../widgets/sync_indicator.dart';

/// Pantalla del checklist activo.
/// Demuestra: StatefulWidget completo, Isolate via compute(),
/// Timer.periodic, consumo de API del clima, y animaciones.
class ChecklistScreen extends StatefulWidget {
  final int checklistId;
  const ChecklistScreen({super.key, required this.checklistId});

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  final _itemNameController = TextEditingController();
  double _itemWeight = 0.5;

  // ── Ciclo de vida ──────────────────────────────

  @override
  void initState() {
    super.initState();
    // Carga checklist e ítems al montar
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<ChecklistProvider>().loadChecklist(widget.checklistId);
      await _fetchWeather();
    });
    // Timer.periodic: actualiza el tiempo transcurrido cada segundo
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed += const Duration(seconds: 1));
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Se puede usar para reaccionar a cambios en dependencias heredadas
  }

  @override
  void dispose() {
    // Cancela el timer para evitar memory leaks (ciclo de vida)
    _timer?.cancel();
    _itemNameController.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────

  Future<void> _fetchWeather() async {
    final city = await SharedPrefsHelper.instance.getCity();
    if (mounted) {
      await context.read<WeatherProvider>().fetchWeather(city);
    }
  }

  String _formatElapsed(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${d.inHours}:$m:$s';
  }

  Future<void> _showAddItemDialog() async {
    _itemNameController.clear();
    _itemWeight = 0.5;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setBS) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Agregar ítem',
                  style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(
                controller: _itemNameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Nombre del ítem',
                  prefixIcon: Icon(Icons.label_outline),
                ),
              ),
              const SizedBox(height: 16),
              Text('Peso estimado: ${_itemWeight.toStringAsFixed(1)} kg'),
              Slider(
                value: _itemWeight,
                min: 0.0,
                max: 10.0,
                divisions: 100,
                onChanged: (v) => setBS(() => _itemWeight = v),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final name = _itemNameController.text.trim();
                    if (name.isEmpty) return;
                    await context
                        .read<ChecklistProvider>()
                        .addItem(name, _itemWeight);
                  },
                  child: const Text('Agregar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChecklistProvider>();
    final weatherProvider = context.watch<WeatherProvider>();
    final checklist = provider.activeChecklist;
    final items = provider.items;
    final stats = provider.stats;
    final isRaining = weatherProvider.isRaining;

    return Scaffold(
      appBar: AppBar(
        title: Text(checklist?.nombre ?? 'Checklist'),
        actions: [
          // Indicador de sincronización Firestore
          SyncIndicator(status: provider.syncStatus),
          const SizedBox(width: 8),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // ── Tarjeta de estadísticas (calculadas en Isolate) ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Tiempo transcurrido (Timer.periodic)
                        _StatsCard(
                          elapsed: _elapsed,
                          stats: stats,
                          formatElapsed: _formatElapsed,
                        ).animate().fadeIn().slideY(begin: -0.1),

                        const SizedBox(height: 12),

                        // Tarjeta del clima
                        WeatherCard(
                          weatherProvider: weatherProvider,
                          onRefresh: _fetchWeather,
                        ).animate().fadeIn(delay: 100.ms),

                        // Aviso de lluvia
                        if (isRaining)
                          _RainAlert()
                              .animate()
                              .fadeIn(delay: 200.ms)
                              .shake(hz: 2),

                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),

                // ── Lista de ítems (ListView dentro de Sliver) ──
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = items[index];
                        // Resalta ítems de lluvia si está lloviendo
                        final isRainItem = isRaining &&
                            AppConstants.rainKeywords.any(
                              (k) => item.nombre
                                  .toLowerCase()
                                  .contains(k),
                            );
                        return ChecklistItemTile(
                          item: item,
                          isRainHighlighted: isRainItem,
                          onToggle: () =>
                              provider.toggleItem(item),
                          onDelete: () =>
                              provider.deleteItem(item.id!),
                        )
                            .animate(delay: (index * 50).ms)
                            .fadeIn()
                            .slideX(begin: 0.05, end: 0);
                      },
                      childCount: items.length,
                    ),
                  ),
                ),

                const SliverToBoxAdapter(
                    child: SizedBox(height: 80)),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddItemDialog,
        tooltip: 'Agregar ítem',
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Widgets auxiliares de esta pantalla
// ──────────────────────────────────────────────

class _StatsCard extends StatelessWidget {
  final Duration elapsed;
  final dynamic stats;
  final String Function(Duration) formatElapsed;

  const _StatsCard(
      {required this.elapsed,
      required this.stats,
      required this.formatElapsed});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final pct = stats?.porcentajeCompletado ?? 0.0;
    final peso = stats?.pesoTotalKg ?? 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Completado',
                        style: Theme.of(context).textTheme.labelMedium),
                    Text('${pct.toStringAsFixed(0)}%',
                        style:
                            Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colors.primary,
                                )),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Peso total',
                        style: Theme.of(context).textTheme.labelMedium),
                    Text('${peso.toStringAsFixed(2)} kg',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: pct / 100,
              backgroundColor: colors.surfaceVariant,
              color: pct == 100 ? Colors.green : colors.primary,
              borderRadius: BorderRadius.circular(8),
              minHeight: 8,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.timer_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Tiempo: ${formatElapsed(elapsed)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RainAlert extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: const Row(
        children: [
          Text('🌧️', style: TextStyle(fontSize: 20)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '¡Está lloviendo! Revisa tus ítems de lluvia (resaltados en azul).',
              style: TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }
}
