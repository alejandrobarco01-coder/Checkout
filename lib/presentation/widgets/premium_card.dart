import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Tarjeta premium reutilizable con gradientes, sombras y animaciones.
/// Proporciona un componente visual de alto nivel para toda la app.
class PremiumCard extends StatelessWidget {
  final Widget child;
  final Color accentColor;
  final BorderRadius borderRadius;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final bool animated;
  final double elevation;
  final Duration? animationDuration;

  const PremiumCard({
    super.key,
    required this.child,
    this.accentColor = const Color(0xFF6C5CE7),
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.animated = true,
    this.elevation = 0.1,
    this.animationDuration,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget card = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor.withOpacity(isDark ? 0.12 : 0.08),
            accentColor.withOpacity(isDark ? 0.06 : 0.02),
          ],
        ),
        borderRadius: borderRadius,
        border: Border.all(
          color: accentColor.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(isDark ? 0.1 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );

    if (animated) {
      card = card
          .animate()
          .fadeIn(duration: animationDuration ?? const Duration(milliseconds: 400))
          .scale(duration: animationDuration ?? const Duration(milliseconds: 400));
    }

    return card;
  }
}

/// Tarjeta gradiente horizontal con ícono y contenido.
class GradientIconCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;
  final bool animated;

  const GradientIconCard({
    super.key,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
    this.animated = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget card = PremiumCard(
      accentColor: color,
      onTap: onTap,
      animated: animated,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.3),
                  color.withOpacity(0.15),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withOpacity(0.65),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return card;
  }
}

/// Tarjeta vacía con estado premium.
class EmptyStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onActionTap;
  final String? actionLabel;

  const EmptyStateCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.color = const Color(0xFF6C5CE7),
    this.onActionTap,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      accentColor: color,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.15),
                  color.withOpacity(0.05),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: color.withOpacity(0.7)),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onActionTap != null) ...[
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onActionTap,
              child: Text(actionLabel!),
            ),
          ]
        ],
      ),
    ).animate().fadeIn().scale();
  }
}

/// Tarjeta cargando con efecto shimmer.
class LoadingCard extends StatelessWidget {
  final Color color;

  const LoadingCard({
    super.key,
    this.color = const Color(0xFF6C5CE7),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PremiumCard(
      accentColor: color,
      animated: false,
      child: Column(
        children: [
          Container(
            height: 16,
            width: double.infinity,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 14,
            width: 200,
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(7),
            ),
          ),
        ],
      ),
    );
  }
}
