import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../data/datasources/local/shared_prefs_helper.dart';
import '../providers/checklist_provider.dart';
import '../widgets/app_bottom_navigation.dart';

class ChecklistsScreen extends StatefulWidget {
  const ChecklistsScreen({super.key});

  @override
  State<ChecklistsScreen> createState() => _ChecklistsScreenState();
}

class _ChecklistsScreenState extends State<ChecklistsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChecklistProvider>().loadChecklists();
    });
  }

  Future<void> _showCreateDialog({String? presetType}) async {
    String name = '';
    String type = presetType ?? AppConstants.exitTypes.first['id']!;
    if (presetType == null) {
      final lastType = await SharedPrefsHelper.instance.getLastExitType();
      if (lastType != null) type = lastType;
    }
    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
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
                  hintText: 'Ej: Viaje a Cartagena',
                ),
                onChanged: (value) => name = value,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: type,
                decoration: const InputDecoration(labelText: 'Tipo de salida'),
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
              if (type == 'personalizado') ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).colorScheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    'Esta lista empezará vacía para que agregues tus propios ítems.',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
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
        title: const Text('Checklist'),
        actions: [
          IconButton(
            onPressed: () => context.push('/ai-checklist'),
            icon: const Icon(Icons.auto_awesome_rounded),
            tooltip: 'Crear con IA',
          ),
        ],
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Elige una plantilla o crea una lista libre',
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () => _showCreateDialog(presetType: 'personalizado'),
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: colors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(22),
                        border:
                            Border.all(color: colors.primary.withOpacity(0.24)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.edit_note_rounded,
                              color: colors.primary, size: 32),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Checklist a mi gusto',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                    'Empieza vacío y agrega tus propios ítems.'),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Text(
                'Plantillas rápidas',
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid.builder(
              itemCount: AppConstants.exitTypes
                  .where((type) => type['id'] != 'personalizado')
                  .length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.95,
              ),
              itemBuilder: (context, index) {
                final types = AppConstants.exitTypes
                    .where((type) => type['id'] != 'personalizado')
                    .toList();
                final type = types[index];
                return InkWell(
                  onTap: () => _showCreateDialog(presetType: type['id']),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: colors.outlineVariant),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          type['emoji'] ?? '📋',
                          style: const TextStyle(fontSize: 28),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          type['nombre'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Tus checklists',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _showCreateDialog(),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Nuevo'),
                  ),
                ],
              ),
            ),
          ),
          if (provider.checklists.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text('Aún no tienes checklists.')),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              sliver: SliverList.builder(
                itemCount: provider.checklists.length,
                itemBuilder: (context, index) {
                  final checklist = provider.checklists[index];
                  final type = AppConstants.exitTypes.firstWhere(
                    (item) => item['id'] == checklist.tipoSalida,
                    orElse: () => {
                      'emoji': '📋',
                      'nombre': checklist.tipoSalida,
                    },
                  );
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      leading: Text(
                        type['emoji'] ?? '📋',
                        style: const TextStyle(fontSize: 28),
                      ),
                      title: Text(
                        checklist.nombre,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      subtitle: Text(type['nombre'] ?? checklist.tipoSalida),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline_rounded),
                        onPressed: () =>
                            provider.deleteChecklist(checklist.id!),
                      ),
                      onTap: () => context.push('/checklist/${checklist.id}'),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavigation(selectedIndex: 2),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Checklist'),
      ),
    );
  }
}
