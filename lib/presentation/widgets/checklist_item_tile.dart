import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/packing_intelligence.dart';
import '../../domain/entities/item.dart';

/// Ítem del checklist mejorado con animaciones premium y efectos visuales.
/// Incluye transiciones suaves y resaltado inteligente para lluvia.
class ChecklistItemTile extends StatefulWidget {
  final Item item;
  final bool isRainHighlighted;
  final bool isCritical;
  final PackingCategory category;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const ChecklistItemTile({
    super.key,
    required this.item,
    required this.onToggle,
    required this.onDelete,
    this.isRainHighlighted = false,
    this.isCritical = false,
    this.category = PackingCategory.other,
  });

  @override
  State<ChecklistItemTile> createState() => _ChecklistItemTileState();
}

class _ChecklistItemTileState extends State<ChecklistItemTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        gradient: widget.isRainHighlighted
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue.withOpacity(isDark ? 0.15 : 0.08),
                  Colors.blue.withOpacity(isDark ? 0.08 : 0.04),
                ],
              )
            : (widget.item.completado
                ? LinearGradient(
                    colors: [
                      Colors.green.withOpacity(isDark ? 0.08 : 0.03),
                      Colors.green.withOpacity(isDark ? 0.04 : 0.01),
                    ],
                  )
                : LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      (isDark ? const Color(0xFF252532) : Colors.white),
                      (isDark ? const Color(0xFF1E1E2F) : Colors.grey.shade50),
                    ],
                  )),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.isRainHighlighted
              ? Colors.blue.withOpacity(0.5)
              : (widget.item.completado
                  ? Colors.green.withOpacity(isDark ? 0.4 : 0.5)
                  : (isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.black.withOpacity(0.06))),
          width: 1.5,
        ),
        boxShadow: widget.item.completado
            ? []
            : [
                BoxShadow(
                  color: colors.primary.withOpacity(isDark ? 0.1 : 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _controller.forward(from: 0.0);
            widget.onToggle();
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                // Checkbox Personalizado con Animación
                ScaleTransition(
                  scale: Tween<double>(begin: 1.0, end: 1.1).animate(
                      CurvedAnimation(
                          parent: _controller, curve: Curves.elasticOut)),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      gradient: widget.item.completado
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                (widget.isRainHighlighted
                                        ? Colors.blue
                                        : colors.primary)
                                    .withOpacity(0.9),
                                (widget.isRainHighlighted
                                        ? Colors.blue
                                        : colors.secondary)
                                    .withOpacity(0.7),
                              ],
                            )
                          : null,
                      color: widget.item.completado ? null : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: widget.item.completado
                            ? Colors.transparent
                            : (widget.isRainHighlighted
                                ? Colors.blue.withOpacity(0.6)
                                : colors.primary.withOpacity(0.3)),
                        width: 2,
                      ),
                      boxShadow: widget.item.completado
                          ? [
                              BoxShadow(
                                color: (widget.isRainHighlighted
                                        ? Colors.blue
                                        : colors.primary)
                                    .withOpacity(0.4),
                                blurRadius: 8,
                                spreadRadius: 0,
                              )
                            ]
                          : [],
                    ),
                    child: widget.item.completado
                        ? const Icon(Icons.check_rounded,
                            size: 16, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(width: 18),

                // Texto e Información del Ítem
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (widget.isRainHighlighted)
                            const Padding(
                              padding: EdgeInsets.only(right: 8),
                              child:
                                  Text('🌧️', style: TextStyle(fontSize: 16)),
                            ),
                          Expanded(
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 250),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: widget.item.completado
                                    ? FontWeight.w500
                                    : FontWeight.w700,
                                color: widget.item.completado
                                    ? colors.onSurface.withOpacity(0.45)
                                    : colors.onSurface,
                                decoration: widget.item.completado
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                                decorationThickness: 2,
                              ),
                              child: Text(widget.item.nombre),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _ItemBadge(
                            label: PackingIntelligence
                                    .categoryLabels[widget.category] ??
                                'Otros',
                            color: colors.secondary,
                          ),
                          if (widget.isCritical)
                            _ItemBadge(
                              label: 'Crítico',
                              color: colors.error,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Botón de eliminar con efecto mejorado
                AnimatedRotation(
                  turns: widget.item.completado ? 0.5 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 22),
                    color: colors.error.withOpacity(0.7),
                    onPressed: widget.onDelete,
                    splashRadius: 24,
                    tooltip: 'Eliminar',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.1);
  }
}

class _ItemBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _ItemBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color.withOpacity(0.85),
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
