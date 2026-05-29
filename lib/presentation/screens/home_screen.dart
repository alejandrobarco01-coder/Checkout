import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants.dart';
import '../../data/datasources/local/shared_prefs_helper.dart';
import '../providers/checklist_provider.dart';

/// Pantalla principal: muestra los tipos de salida disponibles
/// y la lista de checklists creados por el usuario.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Carga los checklists al montar la pantalla (ciclo de vida)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChecklistProvider>().loadChecklists();
    });
  }

  Future<void> _showCreateDialog() async {
    String nombre = '';
    String tipoSalida = AppConstants.exitTypes.first['id']!;

    // Lee el último tipo usado y lo preselecciona
    final lastType = await SharedPrefsHelper.instance.getLastExitType();
    if (lastType != null) tipoSalida = lastType;

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDlg) => AlertDialog(
          title: const Text('Nuevo checklist'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Nombre del checklist',
                  hintText: 'Ej: Viaje a Barcelona',
                ),
                onChanged: (v) => nombre = v,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: tipoSalida,
                decoration: const InputDecoration(labelText: 'Tipo de salida'),
                items: AppConstants.exitTypes
                    .map((t) => DropdownMenuItem(
                          value: t['id'],
                          child: Text('${t['emoji']} ${t['nombre']}'),
                        ))
                    .toList(),
                onChanged: (v) => setStateDlg(() => tipoSalida = v!),
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
                if (nombre.trim().isEmpty) return;
                // Guarda el tipo de salida usado
                await SharedPrefsHelper.instance.setLastExitType(tipoSalida);
                final id = await context
                    .read<ChecklistProvider>()
                    .createChecklist(nombre.trim(), tipoSalida);
                if (mounted) context.push('/checklist/$id');
              },
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChecklistProvider>();
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('CheckOut'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
            tooltip: 'Configuración',
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.checklists.isEmpty
              ? _buildEmptyState(context)
              : _buildChecklistsList(provider, colors),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo'),
        tooltip: 'Crear checklist',
      ).animate().scale(delay: 300.ms),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.checklist_rounded, size: 80, color: Colors.grey)
              .animate()
              .fadeIn()
              .scale(),
          const SizedBox(height: 16),
          Text(
            '¡Crea tu primer checklist!',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Presiona el botón + para comenzar',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistsList(
      ChecklistProvider provider, ColorScheme colors) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.checklists.length,
      itemBuilder: (context, index) {
        final checklist = provider.checklists[index];
        // Busca el emoji del tipo de salida
        final typeData = AppConstants.exitTypes.firstWhere(
          (t) => t['id'] == checklist.tipoSalida,
          orElse: () => {'emoji': '📋', 'nombre': checklist.tipoSalida},
        );

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: colors.primaryContainer,
              child: Text(typeData['emoji']!, style: const TextStyle(fontSize: 22)),
            ),
            title: Text(checklist.nombre,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(
              '${typeData['nombre']} · ${_formatDate(checklist.fechaCreacion)}',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: colors.error,
                  onPressed: () => _confirmDelete(checklist.id!),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: () => context.push('/checklist/${checklist.id}'),
          ),
        )
            .animate(delay: (index * 60).ms)
            .fadeIn()
            .slideY(begin: 0.1, end: 0);
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _confirmDelete(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar checklist'),
        content: const Text('¿Estás seguro? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await context.read<ChecklistProvider>().deleteChecklist(id);
    }
  }
}
