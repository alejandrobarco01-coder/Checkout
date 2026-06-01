import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import '../../core/packing_intelligence.dart';
import '../../domain/entities/item.dart';
import '../../domain/entities/weather.dart';
import '../providers/checklist_provider.dart';
import '../widgets/checklist_item_tile.dart';
import '../widgets/sync_indicator.dart';

enum _ChecklistFilter { all, pending, critical, completed }

/// Pantalla del checklist activo.
/// Demuestra: StatefulWidget completo, Isolate via compute(),
/// Timer.periodic y animaciones.
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
  final _searchController = TextEditingController();
  _ChecklistFilter _filter = _ChecklistFilter.all;

  late ConfettiController _confettiController;
  double _lastPct = 0.0;

  // ── Ciclo de vida ──────────────────────────────

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    // Carga checklist e ítems al montar
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<ChecklistProvider>().loadChecklist(widget.checklistId);
    });
    // Timer.periodic: actualiza el tiempo transcurrido cada segundo
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed += const Duration(seconds: 1));
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    // Cancela el timer para evitar memory leaks (ciclo de vida)
    _timer?.cancel();
    _itemNameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────

  String _formatElapsed(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${d.inHours}:$m:$s';
  }

  Future<void> _showAddItemDialog() async {
    _itemNameController.clear();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setBS) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Agregar ítem', style: Theme.of(ctx).textTheme.titleLarge),
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
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final name = _itemNameController.text.trim();
                    if (name.isEmpty) return;
                    await context.read<ChecklistProvider>().addItem(name, 0);
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

  Future<bool?> _confirmDeleteItem(String itemName) async {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('¿Eliminar ítem?'),
        content: Text('¿Deseas eliminar "$itemName" de la lista?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteItemDialog(int itemId, String itemName) async {
    final confirm = await _confirmDeleteItem(itemName);
    if (confirm == true && mounted) {
      await context.read<ChecklistProvider>().deleteItem(itemId);
    }
  }

  Future<void> _finishChecklist() async {
    final provider = context.read<ChecklistProvider>();
    final checklist = provider.activeChecklist;
    final items = provider.items;
    final stats = provider.stats;

    if (checklist == null || items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Agrega al menos un ítem antes de finalizar')),
      );
      return;
    }

    final pending = items.where((item) => !item.completado).length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(_isShoppingChecklist(checklist.tipoSalida)
            ? 'Finalizar compras'
            : 'Finalizar checklist'),
        content: Text(
          pending == 0
              ? 'Todo está marcado. ¿Quieres cerrar esta lista?'
              : 'Tienes $pending ítem(s) pendientes. Progreso: ${(stats?.porcentajeCompletado ?? 0).toStringAsFixed(0)}%.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Seguir editando'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.check_circle_outline_rounded),
            label: const Text('Finalizar'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    await provider.completeActiveChecklist();
    if (!mounted) return;

    _confettiController.play();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('¡Checklist registrado como completado! 🎉'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  bool _isShoppingChecklist(String type) {
    return type == 'compras' || type == 'hogar' || type == 'personalizado';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChecklistProvider>();
    final checklist = provider.activeChecklist;
    final items = provider.items;
    final stats = provider.stats;
    final exitType = checklist?.tipoSalida ?? '';
    final readinessScore = PackingIntelligence.readinessScore(
      items: items,
      exitType: exitType,
    );
    final query = _searchController.text.trim().toLowerCase();
    final visibleItems = items.where((item) {
      final isCritical = PackingIntelligence.isCritical(item, exitType);
      final matchesFilter = switch (_filter) {
        _ChecklistFilter.all => true,
        _ChecklistFilter.pending => !item.completado,
        _ChecklistFilter.critical => isCritical,
        _ChecklistFilter.completed => item.completado,
      };
      final matchesQuery =
          query.isEmpty || item.nombre.toLowerCase().contains(query);
      return matchesFilter && matchesQuery;
    }).toList();

    // Disparar confeti de forma reactiva si el progreso llega al 100%
    final pct = stats?.porcentajeCompletado ?? 0.0;
    if (pct == 100.0 && _lastPct < 100.0 && items.isNotEmpty) {
      _confettiController.play();
    }
    _lastPct = pct;

    return Stack(
      children: [
        Scaffold(
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
                              readinessScore: readinessScore,
                              criticalPending:
                                  provider.criticalPendingItems.length,
                              formatElapsed: _formatElapsed,
                            ).animate().fadeIn().slideY(begin: -0.1),

                            const SizedBox(height: 12),

                            // Sugerencias por tipo de checklist.
                            _SmartSuggestions(
                              items: items,
                              weather: null,
                              tipoSalida: exitType,
                              onAdd: (suggestion) => provider.addItem(
                                  suggestion.name, suggestion.weightKg),
                              onAddAll: provider.addSuggestions,
                            ),

                            const SizedBox(height: 12),
                            _ChecklistControls(
                              controller: _searchController,
                              selectedFilter: _filter,
                              onFilterChanged: (filter) {
                                setState(() => _filter = filter);
                              },
                              onSearchChanged: (_) => setState(() {}),
                              totalItems: items.length,
                              visibleItems: visibleItems.length,
                            ),

                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),

                    // ── Lista de ítems (ListView dentro de Sliver) ──
                    if (items.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 34),
                          child: _EmptyChecklistState(
                            tipoSalida: exitType,
                            onAdd: _showAddItemDialog,
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final item = visibleItems[index];
                              final isCritical = PackingIntelligence.isCritical(
                                  item, exitType);
                              final category =
                                  PackingIntelligence.categoryFor(item.nombre);
                              final isRainItem = false;

                              return Dismissible(
                                key: Key('item_${item.id}'),
                                direction: DismissDirection.horizontal,
                                confirmDismiss: (direction) async {
                                  if (direction ==
                                      DismissDirection.startToEnd) {
                                    // Swipe to Complete
                                    provider.toggleItem(item);
                                    // Mostrar feedback visual
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(!item.completado
                                            ? '¡Completado: ${item.nombre}! 🎉'
                                            : 'Marcado como pendiente: ${item.nombre}'),
                                        duration: const Duration(seconds: 1),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                    return false; // No remueve el widget de la lista
                                  } else {
                                    // Swipe to Delete
                                    final confirm =
                                        await _confirmDeleteItem(item.nombre);
                                    if (confirm == true) {
                                      provider.deleteItem(item.id!);
                                      return true;
                                    }
                                    return false;
                                  }
                                },
                                background: Container(
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF00B894),
                                        Color(0xFF55EFC4)
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.check_circle_rounded,
                                          color: Colors.white, size: 24),
                                      SizedBox(width: 12),
                                      Text(
                                        'Marcar Completado',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                                secondaryBackground: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFD63031),
                                        Color(0xFFFF7675)
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Eliminar Ítem',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14),
                                      ),
                                      SizedBox(width: 12),
                                      Icon(Icons.delete_sweep_rounded,
                                          color: Colors.white, size: 24),
                                    ],
                                  ),
                                ),
                                child: ChecklistItemTile(
                                  item: item,
                                  isRainHighlighted: isRainItem,
                                  isCritical: isCritical,
                                  category: category,
                                  onToggle: () => provider.toggleItem(item),
                                  onDelete: () => _confirmDeleteItemDialog(
                                      item.id!, item.nombre),
                                ),
                              );
                            },
                            childCount: visibleItems.length,
                          ),
                        ),
                      ),

                    if (items.isNotEmpty && visibleItems.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 32),
                          child: _EmptyFilteredState(
                            onClear: () {
                              _searchController.clear();
                              setState(() => _filter = _ChecklistFilter.all);
                            },
                          ),
                        ),
                      ),

                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
          floatingActionButton: items.isNotEmpty
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    FloatingActionButton.extended(
                      heroTag: 'register_departure',
                      onPressed: _finishChecklist,
                      backgroundColor: const Color(0xFF00B894),
                      icon: const Icon(Icons.check_circle_outline_rounded),
                      label: const Text('Finalizar lista'),
                    ),
                    const SizedBox(height: 12),
                    FloatingActionButton(
                      heroTag: 'add_item',
                      onPressed: _showAddItemDialog,
                      tooltip: 'Agregar ítem',
                      child: const Icon(Icons.add),
                    ),
                  ],
                )
              : FloatingActionButton(
                  onPressed: _showAddItemDialog,
                  tooltip: 'Agregar ítem',
                  child: const Icon(Icons.add),
                ),
        ),

        // Confetti Widget encima de todo
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              Color(0xFF6C5CE7),
              Color(0xFF00CEC9),
              Color(0xFFFF7675),
              Color(0xFF00B894),
              Color(0xFFFDCB6E),
            ],
            numberOfParticles: 20,
            gravity: 0.2,
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────
// Widgets auxiliares de esta pantalla
// ──────────────────────────────────────────────

class _StatsCard extends StatelessWidget {
  final Duration elapsed;
  final dynamic stats;
  final int readinessScore;
  final int criticalPending;
  final String Function(Duration) formatElapsed;

  const _StatsCard({
    required this.elapsed,
    required this.stats,
    required this.readinessScore,
    required this.criticalPending,
    required this.formatElapsed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pct = stats?.porcentajeCompletado ?? 0.0;
    final pending = stats?.pendingItems ?? 0;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E1E2F), const Color(0xFF161622)]
              : [Colors.white, const Color(0xFFF1F2F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PROGRESO',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${pct.toStringAsFixed(0)}%',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: pct == 100 ? Colors.green : colors.onSurface,
                          ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _MetricPill(
                    icon: Icons.verified_user_outlined,
                    label: 'Score',
                    value: '$readinessScore/100',
                    color: readinessScore >= 85
                        ? Colors.green
                        : readinessScore >= 60
                            ? colors.primary
                            : colors.error,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MetricPill(
                    icon: Icons.priority_high_rounded,
                    label: 'Críticos',
                    value:
                        criticalPending == 0 ? 'OK' : '$criticalPending faltan',
                    color: criticalPending == 0 ? Colors.green : colors.error,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MetricPill(
                    icon: Icons.pending_actions_rounded,
                    label: 'Pendientes',
                    value: '$pending',
                    color: colors.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Barra de progreso estilizada
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: pct / 100,
                backgroundColor: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.05),
                color: pct == 100 ? Colors.green : colors.primary,
                minHeight: 10,
              ),
            ),

            const SizedBox(height: 16),

            // Tiempo transcurrido
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.av_timer_rounded,
                      size: 18,
                      color: colors.onSurfaceVariant.withOpacity(0.6),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Tiempo activo: ${formatElapsed(elapsed)}',
                      style: TextStyle(
                        color: colors.onSurfaceVariant.withOpacity(0.7),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (pct == 100)
                  const Row(
                    children: [
                      Icon(Icons.check_circle_rounded,
                          size: 16, color: Colors.green),
                      SizedBox(width: 4),
                      Text(
                        '¡Listo!',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChecklistControls extends StatelessWidget {
  final TextEditingController controller;
  final _ChecklistFilter selectedFilter;
  final ValueChanged<_ChecklistFilter> onFilterChanged;
  final ValueChanged<String> onSearchChanged;
  final int totalItems;
  final int visibleItems;

  const _ChecklistControls({
    required this.controller,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.onSearchChanged,
    required this.totalItems,
    required this.visibleItems,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          TextField(
            controller: controller,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Buscar en la maleta',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: controller.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        controller.clear();
                        onSearchChanged('');
                      },
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChipButton(
                        label: 'Todos',
                        selected: selectedFilter == _ChecklistFilter.all,
                        onTap: () => onFilterChanged(_ChecklistFilter.all),
                      ),
                      _FilterChipButton(
                        label: 'Pendientes',
                        selected: selectedFilter == _ChecklistFilter.pending,
                        onTap: () => onFilterChanged(_ChecklistFilter.pending),
                      ),
                      _FilterChipButton(
                        label: 'Críticos',
                        selected: selectedFilter == _ChecklistFilter.critical,
                        onTap: () => onFilterChanged(_ChecklistFilter.critical),
                      ),
                      _FilterChipButton(
                        label: 'Listos',
                        selected: selectedFilter == _ChecklistFilter.completed,
                        onTap: () =>
                            onFilterChanged(_ChecklistFilter.completed),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$visibleItems/$totalItems',
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: colors.primary.withOpacity(0.14),
        labelStyle: TextStyle(
          color: selected ? colors.primary : colors.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
        side: BorderSide(
          color: selected
              ? colors.primary.withOpacity(0.35)
              : colors.outlineVariant,
        ),
      ),
    );
  }
}

class _EmptyFilteredState extends StatelessWidget {
  final VoidCallback onClear;

  const _EmptyFilteredState({required this.onClear});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        Icon(Icons.manage_search_rounded, size: 42, color: colors.primary),
        const SizedBox(height: 10),
        const Text(
          'No hay resultados',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        const SizedBox(height: 6),
        Text(
          'Cambia el filtro o limpia la búsqueda.',
          textAlign: TextAlign.center,
          style: TextStyle(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: onClear,
          icon: const Icon(Icons.filter_alt_off_rounded),
          label: const Text('Limpiar filtros'),
        ),
      ],
    );
  }
}

class _EmptyChecklistState extends StatelessWidget {
  final String tipoSalida;
  final VoidCallback onAdd;

  const _EmptyChecklistState({
    required this.tipoSalida,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isShopping = tipoSalida == 'compras';
    final title = isShopping
        ? 'Tu lista de compras está lista para llenarse'
        : 'Este checklist empieza a tu gusto';
    final text = isShopping
        ? 'Agrega productos, cantidades o cualquier pendiente de mercado.'
        : 'Agrega ítems propios y ordénalos como necesites.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Icon(
            isShopping
                ? Icons.shopping_cart_checkout_rounded
                : Icons.edit_note_rounded,
            color: colors.primary,
            size: 46,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Agregar primer ítem'),
          ),
        ],
      ),
    );
  }
}

class _SmartSuggestions extends StatelessWidget {
  final List<Item> items;
  final Weather? weather;
  final String tipoSalida;
  final ValueChanged<PackingSuggestion> onAdd;
  final ValueChanged<List<PackingSuggestion>> onAddAll;

  const _SmartSuggestions({
    required this.items,
    required this.weather,
    required this.tipoSalida,
    required this.onAdd,
    required this.onAddAll,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final suggestions = PackingIntelligence.suggestions(
      items: items,
      exitType: tipoSalida,
      isRaining: weather?.esLluvia ?? false,
      temperature: weather?.temperatura,
    );

    if (suggestions.isEmpty) return const SizedBox.shrink();

    final title = _suggestionTitle(tipoSalida);
    final subtitle = _suggestionSubtitle(tipoSalida);
    final actionLabel = _suggestionActionLabel(tipoSalida);

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2F) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.04),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: colors.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => onAddAll(suggestions.take(4).toList()),
                icon: const Icon(Icons.add_task_rounded, size: 18),
                label: Text(actionLabel),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: suggestions.length,
              itemBuilder: (context, idx) {
                final suggestion = suggestions[idx];
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    avatar: CircleAvatar(
                      radius: 12,
                      backgroundColor: colors.primary.withOpacity(0.12),
                      child: Text(
                        PackingIntelligence
                                .categoryIcons[suggestion.category] ??
                            '+',
                        style: TextStyle(
                          color: colors.primary,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    label: Text('${suggestion.name} · ${suggestion.reason}'),
                    backgroundColor: colors.primary.withOpacity(0.06),
                    onPressed: () => onAdd(suggestion),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }

  String _suggestionTitle(String type) {
    switch (type) {
      case 'compras':
        return 'Ideas para compras';
      case 'hogar':
        return 'Ideas para el hogar';
      case 'personalizado':
        return 'Ideas para tu lista';
      case 'gym':
        return 'Ideas para entrenar';
      case 'medico':
        return 'Ideas para tu cita';
      case 'trabajo':
        return 'Ideas para trabajo';
      case 'playa':
        return 'Ideas para playa';
      case 'camping':
        return 'Ideas para camping';
      case 'viaje':
        return 'Ideas para viaje';
      default:
        return 'Ideas para tu salida';
    }
  }

  String _suggestionSubtitle(String type) {
    switch (type) {
      case 'compras':
        return 'Sugerencias de despensa, comida y limpieza para completar tu mercado.';
      case 'hogar':
        return 'Tareas y recordatorios útiles para cerrar pendientes de casa.';
      case 'personalizado':
        return 'Puntos base para que adaptes la lista a tu plan.';
      case 'gym':
        return 'Complementos útiles para entrenar, hidratarte y volver cómodo.';
      case 'medico':
        return 'Documentos y notas para que la consulta sea más fácil.';
      case 'trabajo':
        return 'Detalles prácticos para reuniones y jornadas largas.';
      case 'playa':
        return 'Cosas útiles para arena, sol, agua y regreso.';
      case 'camping':
        return 'Extras para seguridad, comida y energía fuera de casa.';
      case 'viaje':
        return 'Ideas para documentos, orden y comodidad del viaje.';
      default:
        return 'Sugerencias relacionadas con el tipo de lista que elegiste.';
    }
  }

  String _suggestionActionLabel(String type) {
    return type == 'viaje' || type == 'playa' || type == 'camping'
        ? 'Añadir pack'
        : 'Añadir ideas';
  }
}
