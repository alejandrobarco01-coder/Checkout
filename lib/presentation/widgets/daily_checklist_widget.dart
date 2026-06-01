import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../domain/entities/daily_checklist.dart';
import '../providers/daily_checklist_provider.dart';

/// Widget para mostrar el checklist diario con progreso
class DailyChecklistWidget extends StatelessWidget {
  final DailyChecklistProvider provider;
  final VoidCallback? onAddItem;

  const DailyChecklistWidget({
    super.key,
    required this.provider,
    this.onAddItem,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = provider.completionPercentage;
    final isComplete = provider.allCompleted;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isComplete
              ? [
                  Colors.green.withOpacity(isDark ? 0.15 : 0.08),
                  Colors.green.withOpacity(isDark ? 0.08 : 0.02),
                ]
              : [
                  colors.primary.withOpacity(isDark ? 0.12 : 0.08),
                  colors.primary.withOpacity(isDark ? 0.06 : 0.02),
                ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isComplete
              ? Colors.green.withOpacity(0.4)
              : colors.primary.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isComplete
                ? Colors.green.withOpacity(isDark ? 0.1 : 0.08)
                : colors.primary.withOpacity(isDark ? 0.1 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Título y badge de progreso
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '✨ Mi Día',
                          style:
                              Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        const SizedBox(width: 8),
                        if (isComplete)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.green.withOpacity(0.5),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.check_circle,
                                    size: 14, color: Colors.green),
                                SizedBox(width: 4),
                                Text(
                                  'Completado',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: colors.primary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${provider.completedCount}/${provider.totalCount}',
                              style: TextStyle(
                                color: colors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Elementos esenciales para tu día',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurfaceVariant.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                if (isComplete)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.green.withOpacity(0.3),
                          Colors.green.withOpacity(0.15),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.sentiment_very_satisfied,
                      color: Colors.green,
                      size: 20,
                    ),
                  )
                  .animate()
                  .scale(duration: 500.ms, curve: Curves.elasticOut),
              ],
            ),
            const SizedBox(height: 16),

            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LinearProgressIndicator(
                value: progress / 100,
                minHeight: 8,
                backgroundColor: colors.onSurface.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation(
                  isComplete ? Colors.green : colors.primary,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Items
            if (provider.items.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: provider.items.length,
                itemBuilder: (context, index) {
                  final item = provider.items[index];
                  return _DailyItemTile(
                    item: item,
                    onToggle: () => provider.toggleItem(item.id),
                  );
                },
              )
            else
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Cargando elementos...',
                    style: TextStyle(
                      color: colors.onSurfaceVariant.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ).animate().fadeIn().scale();
  }
}

/// Widget para cada item del daily checklist
class _DailyItemTile extends StatelessWidget {
  final DailyChecklistItem item;
  final VoidCallback onToggle;

  const _DailyItemTile({
    required this.item,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: item.completado
              ? Colors.green.withOpacity(0.1)
              : colors.surface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: item.completado
                ? Colors.green.withOpacity(0.4)
                : colors.primary.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // Checkbox
            GestureDetector(
              onTap: onToggle,
              child: AnimatedScale(
                scale: item.completado ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    gradient: item.completado
                        ? LinearGradient(
                            colors: [
                              Colors.green,
                              Colors.green.withOpacity(0.7),
                            ],
                          )
                        : null,
                    color: item.completado ? null : colors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: item.completado
                          ? Colors.transparent
                          : colors.primary.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: item.completado
                      ? const Icon(Icons.check_rounded,
                          size: 14, color: Colors.white)
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Contenido
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        item.emoji,
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: item.completado
                                ? FontWeight.w500
                                : FontWeight.w600,
                            color: item.completado
                                ? colors.onSurface.withOpacity(0.4)
                                : colors.onSurface,
                            decoration: item.completado
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                          child: Text(item.nombre),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
