import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/location_service.dart';
import '../../data/datasources/local/shared_prefs_helper.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/app_bottom_navigation.dart';

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
  bool _useCurrentLocation = false;
  String? _currentLocationLabel;

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
    final useCurrent = await SharedPrefsHelper.instance.getUseCurrentLocation();
    final current = await SharedPrefsHelper.instance.getCurrentLocation();
    if (mounted) {
      setState(() {
        _cityController.text = city;
        _useCurrentLocation = useCurrent;
        _currentLocationLabel = current == null
            ? null
            : '${current.name} (${current.lat.toStringAsFixed(4)}, ${current.lng.toStringAsFixed(4)})';
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

  Future<void> _useDeviceLocation() async {
    try {
      final location = await LocationService.instance.getCurrentLocation();
      await SharedPrefsHelper.instance.setCurrentLocation(
        lat: location.lat,
        lng: location.lng,
      );
      if (!mounted) return;
      setState(() {
        _useCurrentLocation = true;
        _currentLocationLabel =
            'Ubicación actual (${location.lat.toStringAsFixed(4)}, ${location.lng.toStringAsFixed(4)})';
      });
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
      final authProvider = context.read<AuthProvider>();
      await authProvider.logout();
      if (!mounted) return;
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
                _SectionHeader(
                    title: 'Apariencia', icon: Icons.palette_outlined),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tema de la aplicación',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildThemeOption(
                              context,
                              themeProvider,
                              'light',
                              'Claro',
                              Icons.light_mode_outlined,
                              const Color(0xFF6C5CE7),
                            ),
                            _buildThemeOption(
                              context,
                              themeProvider,
                              'dark',
                              'Oscuro',
                              Icons.dark_mode_outlined,
                              const Color(0xFF1E272E),
                            ),
                            _buildThemeOption(
                              context,
                              themeProvider,
                              'sunset',
                              'Sunset',
                              Icons.wb_sunny_outlined,
                              const Color(0xFFE17055),
                            ),
                          ],
                        ),
                      ],
                    ),
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
                          'Ubicación para clima y mapa',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _useCurrentLocation,
                          title: const Text('Usar mi ubicación actual'),
                          subtitle: Text(_currentLocationLabel ??
                              'Pide permiso al dispositivo o navegador.'),
                          onChanged: (_) => _useDeviceLocation(),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _cityController,
                                decoration: const InputDecoration(
                                  hintText: 'Respaldo: Medellín, Bogotá...',
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

                // ── Historial y viajes ─────────────────────────
                _SectionHeader(
                    title: 'Historial y viajes', icon: Icons.history),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.flight, color: colors.primary),
                        title: const Text('Mis Viajes'),
                        subtitle:
                            const Text('Historial de salidas registradas'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/trips'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.psychology_outlined,
                            color: Color(0xFFE17055)),
                        title: const Text('Historial de Olvidos'),
                        subtitle: const Text('Ítems que más sueles olvidar'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/forgotten'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.calendar_month,
                            color: Color(0xFF6C5CE7)),
                        title: const Text('Calendario'),
                        subtitle: const Text('Citas, viajes y eventos'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/calendar'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.map_outlined,
                            color: Color(0xFF00B894)),
                        title: const Text('Mapa de Destinos'),
                        subtitle: const Text('Ver destinos en OpenStreetMap'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/map'),
                      ),
                    ],
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
      bottomNavigationBar: const AppBottomNavigation(selectedIndex: 4),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    ThemeProvider provider,
    String value,
    String label,
    IconData icon,
    Color activeColor,
  ) {
    final isSelected = provider.themeName == value;
    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => provider.setTheme(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.12) : colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isSelected ? activeColor : colors.onSurface.withOpacity(0.08),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color:
                  isSelected ? activeColor : colors.onSurface.withOpacity(0.4),
              size: 26,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? activeColor
                    : colors.onSurface.withOpacity(0.6),
                fontSize: 13,
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
