import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _slides = [
    {
      'title': 'Checklists Inteligentes',
      'description': 'Organiza tus salidas (Trabajo, Viaje, Gym) y no olvides nada al salir de casa.',
      'emoji': '🎒',
    },
    {
      'title': 'Inteligencia Climática',
      'description': 'Sugerencias personalizadas y alertas en tiempo real según el clima de tu destino.',
      'emoji': '🌤️',
    },
    {
      'title': 'Generación con IA',
      'description': 'Describe tu viaje en lenguaje natural y deja que nuestra Inteligencia Artificial arme tu lista.',
      'emoji': '✨',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF1E1B4B), const Color(0xFF0F172A)]
                : [const Color(0xFFEEF2FF), const Color(0xFFE0E7FF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Botón Omitir en la parte superior derecha
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextButton(
                    onPressed: () => context.read<AuthProvider>().completeOnboarding(),
                    child: Text(
                      'Omitir',
                      style: TextStyle(
                        color: colors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (int page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  itemCount: _slides.length,
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    return Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Emoji Gigante con Animación de Rebote
                          Text(
                            slide['emoji']!,
                            style: const TextStyle(fontSize: 100),
                          )
                              .animate(key: ValueKey('emoji_$index'))
                              .scale(duration: 500.ms, curve: Curves.elasticOut)
                              .shake(delay: 200.ms, duration: 500.ms),
                          const SizedBox(height: 40),
                          // Título con Gradiente Premium
                          Text(
                            slide['title']!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          )
                              .animate(key: ValueKey('title_$index'))
                              .fadeIn(duration: 400.ms)
                              .slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuad),
                          const SizedBox(height: 16),
                          // Descripción
                          Text(
                            slide['description']!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: colors.onSurface.withOpacity(0.6),
                              height: 1.5,
                            ),
                          )
                              .animate(key: ValueKey('desc_$index'))
                              .fadeIn(delay: 150.ms, duration: 400.ms)
                              .slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuad),
                        ],
                      ),
                    );
                  },
                ),
              ),
              // Footer: Indicador de páginas y botón Siguiente/Empezar
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Indicadores de Página
                    Row(
                      children: List.generate(
                        _slides.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(right: 8),
                          height: 8,
                          width: _currentPage == index ? 24 : 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? colors.primary
                                : colors.primary.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    // Botón de Acción
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _currentPage == _slides.length - 1
                          ? ElevatedButton(
                              key: const ValueKey('btn_empezar'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 28,
                                  vertical: 16,
                                ),
                                backgroundColor: colors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 4,
                              ),
                              onPressed: () =>
                                  context.read<AuthProvider>().completeOnboarding(),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Empezar',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward_rounded, size: 20),
                                ],
                              ),
                            )
                          : FloatingActionButton(
                              key: const ValueKey('btn_next'),
                              mini: true,
                              backgroundColor: colors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              onPressed: () {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 450),
                                  curve: Curves.easeInOutCubic,
                                );
                              },
                              child: const Icon(Icons.chevron_right_rounded, size: 28),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
