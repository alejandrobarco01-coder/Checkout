import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../data/datasources/local/shared_prefs_helper.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';

/// Pantalla de configuración y perfil.
/// Permite cambiar tema, ciudad del clima y cerrar sesión.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _cityController = TextEditingController();
  bool _loadingCity = true;

  @override
  void initState() {
    super.initState();
    _loadCity();
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _loadCity() async {
    final city = await SharedPrefsHelper.instance.getCity();
    if (mounted) {
      setState(() {
        _cityController.text = city;
        _loadingCity = false;
      });
    }
  }

  Future<void> _saveCity() async {
    final city = _cityController.text.trim();
    if (city.isEmpty) return;
    await SharedPrefsHelper.instance.setCity(city);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ciudad actualizada: $city'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Deseas cerrar tu sesión?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Cerrar sesión')),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await context.read<AuthProvider>().logout();
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: _loadingCity
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Apariencia ─────────────────────────────────
                _SectionHeader(title: 'Apariencia', icon: Icons.palette_outlined),
                Card(
                  child: SwitchListTile(
                    title: const Text('Modo oscuro'),
                    subtitle: Text(
                      themeProvider.isDarkMode ? 'Activado' : 'Desactivado',
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                    secondary: Icon(
                      themeProvider.isDarkMode
                          ? Icons.dark_mode
                          : Icons.light_mode_outlined,
                      color: colors.primary,
                    ),
                    value: themeProvider.isDarkMode,
                    onChanged: (_) => themeProvider.toggleTheme(),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Clima ───────────────────────────────────────
                _SectionHeader(title: 'Clima', icon: Icons.cloud_outlined),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ciudad para el clima',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _cityController,
                                decoration: const InputDecoration(
                                  hintText: 'Ej: Madrid, Buenos Aires',
                                  prefixIcon: Icon(Icons.location_city),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: _saveCity,
                              child: const Text('Guardar'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Cuenta ──────────────────────────────────────
                _SectionHeader(title: 'Cuenta', icon: Icons.person_outlined),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text(
                      'Cerrar sesión',
                      style: TextStyle(color: Colors.red),
                    ),
                    subtitle: const Text('Elimina el JWT guardado'),
                    onTap: _logout,
                  ),
                ),

                const SizedBox(height: 32),
                Center(
                  child: Text(
                    'CheckOut v1.0.0',
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                ),
              ],
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
          ),
        ],
      ),
    );
  }
}
