import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/habit_templates.dart';
import '../../domain/entities/habit.dart';
import '../providers/habit_provider.dart';
import '../widgets/app_bottom_navigation.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  HabitCategory _selectedCategory = HabitCategory.popular;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final habits = context.watch<HabitProvider>().activeHabits;
    final templates = HabitTemplates.byCategory(_selectedCategory);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hábitos'),
        actions: [
          IconButton(
            tooltip: 'Calendario de hábitos',
            onPressed: () => context.push('/habit-calendar'),
            icon: const Icon(Icons.calendar_month_rounded),
          ),
          IconButton(
            tooltip: 'Configuración',
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            if (habits.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
                  child: _ActiveHabitsPreview(habits: habits.take(3).toList()),
                ),
              ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 68,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  children: HabitCategory.values.map((category) {
                    final selected = category == _selectedCategory;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: ChoiceChip(
                        selected: selected,
                        onSelected: (_) => setState(() {
                          _selectedCategory = category;
                        }),
                        selectedColor: const Color(0xFFFF5A7A),
                        backgroundColor: Colors.white,
                        labelPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              HabitTemplates.categoryIcons[category] ?? '',
                              style: TextStyle(
                                color: selected ? Colors.white : colors.primary,
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              HabitTemplates.categoryNames[category] ?? '',
                              style: TextStyle(
                                color:
                                    selected ? Colors.white : colors.onSurface,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                          side: BorderSide(
                            color: selected
                                ? Colors.transparent
                                : colors.outlineVariant.withOpacity(0.45),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
              sliver: SliverList.builder(
                itemCount: templates.length + 2,
                itemBuilder: (context, index) {
                  if (index == templates.length) {
                    return _IdeaCard(
                      category: _selectedCategory,
                      onTap: () => context.push('/habit/custom'),
                    );
                  }
                  if (index == templates.length + 1) {
                    return _CustomHabitButton(
                      onTap: () => context.push('/habit/custom'),
                    );
                  }
                  final template = templates[index];
                  return _HabitTemplateTile(
                    template: template,
                    onTap: () => context.push('/habit/new/${template.id}'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavigation(selectedIndex: 1),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/habit/custom'),
        backgroundColor: const Color(0xFFFF5A7A),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ActiveHabitsPreview extends StatelessWidget {
  final List<ActiveHabit> habits;

  const _ActiveHabitsPreview({required this.habits});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hábitos activos',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        ...habits.map(
          (habit) => _ActiveHabitTile(
            habit: habit,
            status: provider.statusText(habit),
            isOverLimit: provider.isOverLimit(habit),
            onTap: () => showHabitActionSheet(context, habit),
          ),
        ),
      ],
    );
  }
}

class _HabitTemplateTile extends StatelessWidget {
  final HabitTemplate template;
  final VoidCallback onTap;

  const _HabitTemplateTile({
    required this.template,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        leading: Text(template.emoji, style: const TextStyle(fontSize: 26)),
        title: Text(
          template.name,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          _goalTypeLabel(template),
          style: TextStyle(color: colors.onSurfaceVariant),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (template.goalType == HabitGoalType.build ||
                template.goalType == HabitGoalType.counter)
              const Icon(Icons.favorite, color: Color(0xFFFF5A7A), size: 24),
            const SizedBox(width: 10),
            const Icon(Icons.add, color: Colors.black, size: 30),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  String _goalTypeLabel(HabitTemplate template) {
    switch (template.goalType) {
      case HabitGoalType.limit:
        return 'Límite de ${template.defaultTarget} ${template.unit}';
      case HabitGoalType.reduce:
        return 'Reducir a ${template.defaultTarget} ${template.unit}';
      case HabitGoalType.timer:
        return 'Temporizador de ${template.defaultTarget} ${template.unit}';
      case HabitGoalType.counter:
        return 'Contador diario';
      case HabitGoalType.checklist:
        return 'Marcar una vez al día';
      case HabitGoalType.build:
        return 'Construir hábito diario';
    }
  }
}

class _IdeaCard extends StatelessWidget {
  final HabitCategory category;
  final VoidCallback onTap;

  const _IdeaCard({
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ideas = switch (category) {
      HabitCategory.quit => [
          'Reducir comida rápida',
          'Comprar menos por impulso',
          'No mirar redes al despertar',
        ],
      HabitCategory.sports => [
          'Subir escaleras',
          'Movilidad de espalda',
          'Plancha'
        ],
      HabitCategory.health => [
          'Tomar sol 10 min',
          'Preparar comida',
          'Respirar profundo'
        ],
      HabitCategory.time => [
          'Bloque sin notificaciones',
          'Estudiar 25 min',
          'Dormir sin móvil'
        ],
      HabitCategory.lifestyle => [
          'Leer una página',
          'Ordenar escritorio',
          'Agradecer algo'
        ],
      HabitCategory.popular => ['Caminar', 'Beber agua', 'Meditar 5 min'],
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFF5A7A).withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_rounded, color: Color(0xFFFF5A7A)),
              const SizedBox(width: 8),
              const Text(
                'Ideas de hábito',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
              const Spacer(),
              TextButton(onPressed: onTap, child: const Text('Crear')),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ideas.map((idea) => Chip(label: Text(idea))).toList(),
          ),
        ],
      ),
    );
  }
}

class _CustomHabitButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CustomHabitButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 20),
        child: FilledButton.icon(
          onPressed: onTap,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFFF5A7A),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          icon: const Icon(Icons.edit_rounded),
          label: const Text(
            'Hábito Personalizado',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}

class HabitSetupScreen extends StatefulWidget {
  final String? templateId;

  const HabitSetupScreen({super.key, this.templateId});

  @override
  State<HabitSetupScreen> createState() => _HabitSetupScreenState();
}

class _HabitSetupScreenState extends State<HabitSetupScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late HabitCategory _category;
  late HabitGoalType _goalType;
  late String _emoji;
  late String _unit;
  late int _target;
  late int _colorValue;

  bool get _isCustom => widget.templateId == null;

  @override
  void initState() {
    super.initState();
    final template = widget.templateId == null
        ? null
        : HabitTemplates.templateById(widget.templateId!);
    _nameController = TextEditingController(text: template?.name ?? '');
    _descriptionController =
        TextEditingController(text: template?.description ?? '');
    _category = template?.category ?? HabitCategory.lifestyle;
    _goalType = template?.goalType ?? HabitGoalType.build;
    _emoji = template?.emoji ?? '✨';
    _unit = template?.unit ?? 'veces';
    _target = template?.defaultTarget ?? 1;
    _colorValue = 0xFFFF5A7A;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isCustom ? 'Hábito Personalizado' : _nameController.text),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
          children: [
            _SetupCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _EmojiPicker(
                    emoji: _emoji,
                    onChanged: (emoji) => setState(() => _emoji = emoji),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nombre del hábito',
                            hintText: 'Ej: Jugar Menos Juegos',
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Descripción (Opcional)',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _SetupCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Tipo de Hábito',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.help, color: colors.outline),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SegmentedButton<HabitGoalType>(
                    segments: const [
                      ButtonSegment(
                        value: HabitGoalType.build,
                        label: Text('Construir'),
                      ),
                      ButtonSegment(
                        value: HabitGoalType.reduce,
                        label: Text('Dejar'),
                      ),
                    ],
                    selected: {
                      _goalType == HabitGoalType.reduce ||
                              _goalType == HabitGoalType.limit
                          ? HabitGoalType.reduce
                          : HabitGoalType.build
                    },
                    onSelectionChanged: (value) {
                      final selected = value.first;
                      setState(() {
                        _goalType = selected;
                        if (selected == HabitGoalType.reduce &&
                            _unit == 'veces') {
                          _target = 0;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<HabitCategory>(
                    value: _category,
                    decoration: const InputDecoration(labelText: 'Grupo'),
                    items: HabitCategory.values
                        .where((category) => category != HabitCategory.popular)
                        .map(
                          (category) => DropdownMenuItem(
                            value: category,
                            child: Text(
                              HabitTemplates.categoryNames[category] ?? '',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _category = value);
                    },
                  ),
                ],
              ),
            ),
            _SetupCard(
              child: Column(
                children: [
                  _SetupRow(
                    label: 'Valor Objetivo',
                    value: '$_target $_unit / Día',
                    onTap: _showTargetEditor,
                  ),
                  const Divider(),
                  _SetupRow(
                    label: 'Medición',
                    value: _measurementLabel,
                    onTap: _showMeasurementEditor,
                  ),
                  const Divider(),
                  const _SetupRow(
                    label: 'Días de Tarea',
                    value: 'Cada Día',
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _goalHint,
                      style: const TextStyle(
                        color: Color(0xFFFF7043),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _SetupCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rango de Tiempo',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    children: const [
                      Chip(label: Text('Cualquier momento')),
                      Chip(label: Text('Mañana')),
                      Chip(label: Text('Tarde')),
                      Chip(label: Text('Noche')),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20),
        child: FilledButton(
          onPressed: _saveHabit,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFFF5A7A),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text(
            'Guardar hábito',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ),
      ),
    );
  }

  String get _measurementLabel {
    return switch (_goalType) {
      HabitGoalType.limit => 'Temporizador con límite',
      HabitGoalType.timer => 'Temporizador',
      HabitGoalType.counter => 'Contador',
      HabitGoalType.reduce => 'Sumar o restar',
      HabitGoalType.checklist => 'Hecho / pendiente',
      HabitGoalType.build => 'Progreso diario',
    };
  }

  String get _goalHint {
    if (_goalType == HabitGoalType.limit) {
      return '*Mantente por debajo de $_target $_unit cada día';
    }
    if (_goalType == HabitGoalType.reduce) {
      return '*No superar $_target $_unit cada día';
    }
    return '*Completa $_target $_unit cada día';
  }

  Future<void> _showTargetEditor() async {
    final targetController = TextEditingController(text: '$_target');
    final unitController = TextEditingController(text: _unit);
    final result = await showDialog<(int, String)>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Objetivo diario'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: targetController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Valor'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: unitController,
              decoration: const InputDecoration(labelText: 'Unidad'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(
                ctx,
                (
                  int.tryParse(targetController.text.trim()) ?? _target,
                  unitController.text.trim().isEmpty
                      ? _unit
                      : unitController.text.trim(),
                ),
              );
            },
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
    targetController.dispose();
    unitController.dispose();
    if (result == null) return;
    setState(() {
      _target = result.$1.clamp(0, 99999);
      _unit = result.$2;
    });
  }

  Future<void> _showMeasurementEditor() async {
    final result = await showModalBottomSheet<HabitGoalType>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.timer_rounded),
              title: const Text('Temporizador'),
              onTap: () => Navigator.pop(ctx, HabitGoalType.timer),
            ),
            ListTile(
              leading: const Icon(Icons.exposure_plus_1_rounded),
              title: const Text('Contador'),
              onTap: () => Navigator.pop(ctx, HabitGoalType.counter),
            ),
            ListTile(
              leading: const Icon(Icons.block_rounded),
              title: const Text('Límite / Dejar'),
              onTap: () => Navigator.pop(ctx, HabitGoalType.reduce),
            ),
            ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: const Text('Hecho / pendiente'),
              onTap: () => Navigator.pop(ctx, HabitGoalType.checklist),
            ),
          ],
        ),
      ),
    );
    if (result != null) setState(() => _goalType = result);
  }

  Future<void> _saveHabit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    await context.read<HabitProvider>().addHabit(
          templateId: widget.templateId ?? 'custom',
          name: name,
          emoji: _emoji,
          category: _category,
          goalType: _goalType,
          unit: _unit,
          target: _target,
          description: _descriptionController.text.trim(),
          colorValue: _colorValue,
        );
    if (!mounted) return;
    context.go('/habits');
  }
}

class _EmojiPicker extends StatelessWidget {
  final String emoji;
  final ValueChanged<String> onChanged;

  const _EmojiPicker({
    required this.emoji,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const options = ['✨', '🚶', '💧', '🎮', '🚭', '🍺', '📚', '🧘', '🏃', '☕'];
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        showModalBottomSheet(
          context: context,
          builder: (ctx) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: options
                    .map(
                      (item) => ActionChip(
                        label: Text(item, style: const TextStyle(fontSize: 24)),
                        onPressed: () {
                          Navigator.pop(ctx);
                          onChanged(item);
                        },
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        );
      },
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blueAccent.withOpacity(0.45)),
        ),
        child: Center(child: Text(emoji, style: const TextStyle(fontSize: 36))),
      ),
    );
  }
}

class _SetupCard extends StatelessWidget {
  final Widget child;

  const _SetupCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
      ),
      child: child,
    );
  }
}

class _SetupRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _SetupRow({
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        label,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: const TextStyle(fontSize: 16)),
          if (onTap != null) const Icon(Icons.chevron_right_rounded),
        ],
      ),
      onTap: onTap,
    );
  }
}

class _ActiveHabitTile extends StatelessWidget {
  final ActiveHabit habit;
  final String status;
  final bool isOverLimit;
  final VoidCallback onTap;

  const _ActiveHabitTile({
    required this.habit,
    required this.status,
    required this.isOverLimit,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(habit.colorValue);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isOverLimit ? Colors.grey.shade700 : color,
        borderRadius: BorderRadius.circular(22),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        leading: CircleAvatar(
          backgroundColor: Colors.white.withOpacity(0.18),
          child: Text(habit.emoji, style: const TextStyle(fontSize: 24)),
        ),
        title: Text(
          habit.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: Text(
          status,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        trailing: Icon(
          isOverLimit ? Icons.close_rounded : Icons.add_rounded,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }
}

void showHabitActionSheet(BuildContext context, ActiveHabit habit) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _HabitActionSheet(habit: habit),
  );
}

class _HabitActionSheet extends StatefulWidget {
  final ActiveHabit habit;

  const _HabitActionSheet({required this.habit});

  @override
  State<_HabitActionSheet> createState() => _HabitActionSheetState();
}

class _HabitActionSheetState extends State<_HabitActionSheet> {
  Timer? _timer;
  int _sessionSeconds = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();
    final habit = provider.habits.firstWhere(
      (item) => item.id == widget.habit.id,
      orElse: () => widget.habit,
    );
    final isTimer = habit.goalType == HabitGoalType.timer ||
        habit.goalType == HabitGoalType.limit;
    final isReduce = habit.goalType == HabitGoalType.reduce;
    final isOver = provider.isOverLimit(habit);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(habit.emoji, style: const TextStyle(fontSize: 34)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    habit.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    provider.deleteHabit(habit.id);
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              habit.description.isEmpty
                  ? 'Registra tu avance de hoy.'
                  : habit.description,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 18),
            Center(
              child: Text(
                provider.statusText(habit),
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: isOver ? Colors.redAccent : Color(habit.colorValue),
                ),
              ),
            ),
            const SizedBox(height: 18),
            if (isTimer) _buildTimerControls(context, habit),
            if (!isTimer)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => provider.addProgress(habit.id, -1),
                      icon: const Icon(Icons.remove_rounded),
                      label: const Text('Restar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => provider.addProgress(habit.id, 1),
                      icon: const Icon(Icons.add_rounded),
                      label: Text(isReduce ? 'Sumar' : 'Completar'),
                    ),
                  ),
                ],
              ),
            if (isOver) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.auto_awesome, color: Colors.redAccent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        provider.aiRecommendation(habit),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimerControls(BuildContext context, ActiveHabit habit) {
    final provider = context.read<HabitProvider>();
    final running = _timer?.isActive ?? false;
    return Column(
      children: [
        Text(
          _formatSeconds(_sessionSeconds),
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: running
                    ? null
                    : () {
                        _timer =
                            Timer.periodic(const Duration(seconds: 1), (_) {
                          setState(() => _sessionSeconds++);
                        });
                      },
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Iniciar'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: _sessionSeconds == 0
                    ? null
                    : () async {
                        _timer?.cancel();
                        await provider.addElapsedSeconds(
                          habit.id,
                          _sessionSeconds,
                        );
                        setState(() => _sessionSeconds = 0);
                      },
                icon: const Icon(Icons.save_rounded),
                label: const Text('Guardar'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatSeconds(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final rest = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$rest';
  }
}

class HabitCalendarScreen extends StatefulWidget {
  const HabitCalendarScreen({super.key});

  @override
  State<HabitCalendarScreen> createState() => _HabitCalendarScreenState();
}

class _HabitCalendarScreenState extends State<HabitCalendarScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();
    final habits = provider.activeHabits;
    final colors = Theme.of(context).colorScheme;
    final score = provider.monthlyScore(_month);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progreso mensual'),
      ),
      body: habits.isEmpty
          ? const Center(child: Text('Crea un hábito para ver tu calendario.'))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => setState(() {
                              _month = DateTime(_month.year, _month.month - 1);
                            }),
                            icon: const Icon(Icons.chevron_left_rounded),
                          ),
                          Expanded(
                            child: Text(
                              _monthLabel(_month),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => setState(() {
                              _month = DateTime(_month.year, _month.month + 1);
                            }),
                            icon: const Icon(Icons.chevron_right_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _MonthMetric(
                              label: 'Mes',
                              value: '${(score * 100).round()}%',
                              color: colors.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _MonthMetric(
                              label: 'Hábitos',
                              value: '${habits.length}',
                              color: const Color(0xFFFF5A7A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      LinearProgressIndicator(
                        value: score,
                        minHeight: 9,
                        borderRadius: BorderRadius.circular(10),
                        backgroundColor: colors.primary.withOpacity(0.12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                ...habits.map(
                  (habit) => _HabitMonthCard(
                    habit: habit,
                    month: _month,
                    completedDays: provider.monthCompletedDays(habit, _month),
                    streak: provider.currentStreak(habit),
                    isCompletedOn: (date) =>
                        provider.isCompletedOn(habit, date),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: const AppBottomNavigation(selectedIndex: 1),
    );
  }

  String _monthLabel(DateTime date) {
    const months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

class _MonthMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MonthMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(color: color, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _HabitMonthCard extends StatelessWidget {
  final ActiveHabit habit;
  final DateTime month;
  final int completedDays;
  final int streak;
  final bool Function(DateTime date) isCompletedOn;

  const _HabitMonthCard({
    required this.habit,
    required this.month,
    required this.completedDays,
    required this.streak,
    required this.isCompletedOn,
  });

  @override
  Widget build(BuildContext context) {
    final days = DateUtils.getDaysInMonth(month.year, month.month);
    final color = Color(habit.colorValue);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(habit.emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  habit.name,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ),
              _SmallStat(label: 'Racha', value: '$streak d', color: color),
              const SizedBox(width: 8),
              _SmallStat(
                  label: 'Mes', value: '$completedDays/$days', color: color),
            ],
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: days,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 7,
              crossAxisSpacing: 7,
            ),
            itemBuilder: (context, index) {
              final day = index + 1;
              final date = DateTime(month.year, month.month, day);
              final done = isCompletedOn(date);
              return Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: done ? color : color.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$day',
                  style: TextStyle(
                    color: done ? Colors.white : color,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SmallStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SmallStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(color: color, fontWeight: FontWeight.w900)),
          Text(label, style: TextStyle(color: color, fontSize: 10)),
        ],
      ),
    );
  }
}
