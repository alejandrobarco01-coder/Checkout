import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/location_service.dart';
import '../../data/datasources/local/shared_prefs_helper.dart';
import '../../domain/entities/checklist.dart';
import '../../domain/entities/habit.dart';
import '../providers/checklist_provider.dart';
import '../providers/habit_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/weather_provider.dart';
import '../widgets/app_bottom_navigation.dart';
import 'habits_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChecklistProvider>().loadChecklists();
      _loadWeather();
    });
  }

  Future<void> _loadWeather() async {
    final prefs = SharedPrefsHelper.instance;
    final useCurrent = await prefs.getUseCurrentLocation();
    final current = await prefs.getCurrentLocation();
    if (!mounted) return;
    if (useCurrent && current != null) {
      context.read<WeatherProvider>().fetchWeatherByCoordinates(
            lat: current.lat,
            lng: current.lng,
            label: current.name,
          );
      return;
    }

    final city = await prefs.getCity();
    if (!mounted) return;
    context.read<WeatherProvider>().fetchWeather(city);
  }

  Future<void> _detectCurrentLocation() async {
    try {
      final location = await LocationService.instance.getCurrentLocation();
      await SharedPrefsHelper.instance.setCurrentLocation(
        lat: location.lat,
        lng: location.lng,
      );
      if (!mounted) return;
      await context.read<WeatherProvider>().fetchWeatherByCoordinates(
            lat: location.lat,
            lng: location.lng,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ubicación actual activada'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on LocationServiceException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showCreateChecklistDialog() async {
    String name = '';
    String type = AppConstants.exitTypes.first['id']!;
    final lastType = await SharedPrefsHelper.instance.getLastExitType();
    if (lastType != null) type = lastType;
    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) {
          final colors = Theme.of(ctx).colorScheme;
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text('Nuevo Checklist'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    hintText: 'Ej: Viaje a Medellín',
                    prefixIcon: Icon(Icons.edit_outlined),
                  ),
                  onChanged: (value) => name = value,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: type,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de salida',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: AppConstants.exitTypes
                      .map(
                        (item) => DropdownMenuItem(
                          value: item['id'],
                          child: Text('${item['emoji']} ${item['nombre']}'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setStateDialog(() => type = value);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  if (name.trim().isEmpty) return;
                  final checklistProvider = context.read<ChecklistProvider>();
                  await SharedPrefsHelper.instance.setLastExitType(type);
                  final id = await checklistProvider.createChecklist(
                    name.trim(),
                    type,
                  );
                  if (mounted) context.push('/checklist/$id');
                },
                style:
                    ElevatedButton.styleFrom(backgroundColor: colors.primary),
                child: const Text('Crear'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final checklistProvider = context.watch<ChecklistProvider>();
    final habitProvider = context.watch<HabitProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final weatherProvider = context.watch<WeatherProvider>();
    final colors = Theme.of(context).colorScheme;
    final habits = habitProvider.activeHabits;
    final checklists = checklistProvider.checklists;
    final warnings = checklistProvider.warnings;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hoy',
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Tu inicio',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => themeProvider.toggleTheme(),
                      icon: const Icon(Icons.brightness_6_rounded),
                    ),
                    IconButton(
                      onPressed: () => context.push('/settings'),
                      icon: const Icon(Icons.tune_rounded),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: _PrimaryAction(
                        icon: Icons.add_circle_rounded,
                        label: 'Nuevo hábito',
                        color: const Color(0xFFFF5A7A),
                        onTap: () => context.push('/habits'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _PrimaryAction(
                        icon: Icons.playlist_add_check_rounded,
                        label: 'Nuevo checklist',
                        color: colors.primary,
                        onTap: _showCreateChecklistDialog,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _HomeWeatherPanel(
                weatherProvider: weatherProvider,
                onRefresh: _loadWeather,
                onDetectLocation: _detectCurrentLocation,
              ),
            ),
            if (warnings.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: _SectionHeader(
                  title: 'Advertencias',
                  action: 'Ver todos',
                  onAction: () => context.push('/checklists'),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList.builder(
                  itemCount: warnings.length,
                  itemBuilder: (context, index) {
                    return _ChecklistWarningCard(warning: warnings[index]);
                  },
                ),
              ),
            ],
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'Hábitos activos',
                action: habits.isEmpty ? 'Explorar' : 'Ver todos',
                onAction: () => context.push('/habits'),
              ),
            ),
            if (habits.isEmpty)
              SliverToBoxAdapter(
                child: _EmptyPanel(
                  icon: Icons.favorite_rounded,
                  title: 'Crea tu primer hábito',
                  text:
                      'Caminar, dormir mejor, beber agua o reducir pantalla pueden vivir aquí.',
                  action: 'Elegir hábito',
                  onTap: () => context.push('/habits'),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList.builder(
                  itemCount: habits.length.clamp(0, 4),
                  itemBuilder: (context, index) {
                    final habit = habits[index];
                    return _HomeHabitCard(
                      habit: habit,
                      status: habitProvider.statusText(habit),
                      progress: habitProvider.progressFor(habit),
                      isOverLimit: habitProvider.isOverLimit(habit),
                      onTap: () => showHabitActionSheet(context, habit),
                    );
                  },
                ),
              ),
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'Checklists',
                action: checklists.isEmpty ? 'Crear' : 'Ver todos',
                onAction: checklists.isEmpty
                    ? _showCreateChecklistDialog
                    : () => context.push('/checklists'),
              ),
            ),
            if (checklists.isEmpty)
              SliverToBoxAdapter(
                child: _EmptyPanel(
                  icon: Icons.fact_check_rounded,
                  title: 'Sin checklists todavía',
                  text:
                      'Crea listas libres para compras, hogar, viajes, gym o cualquier plan.',
                  action: 'Crear checklist',
                  onTap: _showCreateChecklistDialog,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                sliver: SliverList.builder(
                  itemCount: checklists.length,
                  itemBuilder: (context, index) {
                    return _ChecklistCard(checklist: checklists[index]);
                  },
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavigation(selectedIndex: 0),
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _PrimaryAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.24)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String action;
  final VoidCallback onAction;

  const _SectionHeader({
    required this.title,
    required this.action,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
          ),
          TextButton(onPressed: onAction, child: Text(action)),
        ],
      ),
    );
  }
}

class _HomeWeatherPanel extends StatelessWidget {
  final WeatherProvider weatherProvider;
  final VoidCallback onRefresh;
  final VoidCallback onDetectLocation;

  const _HomeWeatherPanel({
    required this.weatherProvider,
    required this.onRefresh,
    required this.onDetectLocation,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final weather = weatherProvider.weather;
    final isLoading = weatherProvider.status == WeatherStatus.loading;
    final recommendations = weatherProvider.recommendations;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  weather?.esLluvia == true
                      ? Icons.umbrella_rounded
                      : Icons.wb_sunny_rounded,
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recomendaciones de hoy',
                      style:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      weather == null
                          ? 'Calculando según el clima de tu ciudad'
                          : '${weather.ciudad} · ${weather.temperatura.toStringAsFixed(0)}°C · ${weather.descripcion}',
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: isLoading ? null : onRefresh,
                icon: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
              ),
              IconButton(
                onPressed: isLoading ? null : onDetectLocation,
                tooltip: 'Usar mi ubicación',
                icon: const Icon(Icons.my_location_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (recommendations.isEmpty)
            Text(
              'Cuando cargue el clima verás aquí qué conviene llevar antes de crear una salida.',
              style: TextStyle(color: colors.onSurfaceVariant),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: recommendations
                  .take(6)
                  .map(
                    (item) => Chip(
                      avatar: Text(item.emoji),
                      label: Text(item.nombre),
                      backgroundColor: colors.primary.withOpacity(0.08),
                      side: BorderSide.none,
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _ChecklistWarningCard extends StatelessWidget {
  final ChecklistWarning warning;

  const _ChecklistWarningCard({required this.warning});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final type = AppConstants.exitTypes.firstWhere(
      (item) => item['id'] == warning.checklist.tipoSalida,
      orElse: () => {'emoji': '⚠️', 'nombre': warning.checklist.tipoSalida},
    );
    final urgent = warning.isEmpty || warning.hasNoSelection;

    return InkWell(
      onTap: () => context.push('/checklist/${warning.checklist.id}'),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: urgent
              ? const Color(0xFFFFF3E8)
              : colors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: urgent
                ? const Color(0xFFE17055).withOpacity(0.45)
                : colors.primary.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Center(
                child: Text(
                  type['emoji'] ?? '⚠️',
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    warning.checklist.nombre,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    warning.message,
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (!warning.isEmpty) ...[
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: warning.progress,
                      minHeight: 5,
                      borderRadius: BorderRadius.circular(10),
                      backgroundColor: Colors.white.withOpacity(0.75),
                      color: urgent ? const Color(0xFFE17055) : colors.primary,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              urgent
                  ? Icons.warning_amber_rounded
                  : Icons.chevron_right_rounded,
              color: urgent ? const Color(0xFFE17055) : colors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeHabitCard extends StatelessWidget {
  final ActiveHabit habit;
  final String status;
  final double progress;
  final bool isOverLimit;
  final VoidCallback onTap;

  const _HomeHabitCard({
    required this.habit,
    required this.status,
    required this.progress,
    required this.isOverLimit,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(habit.colorValue);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isOverLimit ? Colors.grey.shade700 : color,
        borderRadius: BorderRadius.circular(24),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        leading: CircleAvatar(
          backgroundColor: Colors.white.withOpacity(0.2),
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
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              status,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: Colors.white.withOpacity(0.2),
              color: Colors.white,
            ),
          ],
        ),
        trailing: Icon(
          isOverLimit ? Icons.warning_rounded : Icons.add_rounded,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _ChecklistCard extends StatelessWidget {
  final Checklist checklist;

  const _ChecklistCard({required this.checklist});

  @override
  Widget build(BuildContext context) {
    final type = AppConstants.exitTypes.firstWhere(
      (item) => item['id'] == checklist.tipoSalida,
      orElse: () => {'emoji': '📋', 'nombre': checklist.tipoSalida},
    );
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        leading:
            Text(type['emoji'] ?? '📋', style: const TextStyle(fontSize: 28)),
        title: Text(
          checklist.nombre,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(type['nombre'] ?? checklist.tipoSalida),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => context.push('/checklist/${checklist.id}'),
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  final String action;
  final VoidCallback onTap;

  const _EmptyPanel({
    required this.icon,
    required this.title,
    required this.text,
    required this.action,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Icon(icon, color: colors.primary, size: 38),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(text, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: onTap, child: Text(action)),
        ],
      ),
    );
  }
}
