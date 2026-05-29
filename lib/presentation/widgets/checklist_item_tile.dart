import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants.dart';
import '../../domain/entities/item.dart';

/// Ítem del checklist con animación suave al marcar/desmarcar.
/// Resalta en azul los ítems relacionados con lluvia cuando corresponde.
class ChecklistItemTile extends StatelessWidget {
  final Item item;
  final bool isRainHighlighted;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const ChecklistItemTile({
    super.key,
    required this.item,
    required this.onToggle,
    required this.onDelete,
    this.isRainHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isRainHighlighted
            ? Colors.blue.shade50
            : (item.completado
                ? colors.surfaceVariant.withOpacity(0.5)
                : colors.surface),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRainHighlighted
              ? Colors.blue.shade200
              : (item.completado ? Colors.green.shade200 : colors.outline.withOpacity(0.3)),
          width: isRainHighlighted ? 1.5 : 1,
        ),
      ),
      child: CheckboxListTile(
        value: item.completado,
        onChanged: (_) => onToggle(),
        title: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 300),
          style: TextStyle(
            decoration: item.completado
                ? TextDecoration.lineThrough
                : TextDecoration.none,
            color: item.completado ? Colors.grey : null,
            fontWeight: item.completado ? FontWeight.normal : FontWeight.w500,
          ),
          child: Row(
            children: [
              if (isRainHighlighted)
                const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: Text('🌧️', style: TextStyle(fontSize: 14)),
                ),
              Expanded(child: Text(item.nombre)),
            ],
          ),
        ),
        subtitle: Text(
          '${item.pesoKg.toStringAsFixed(2)} kg',
          style: TextStyle(
            color: colors.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
        secondary: IconButton(
          icon: const Icon(Icons.delete_outline, size: 20),
          color: colors.error.withOpacity(0.7),
          onPressed: onDelete,
        ),
        controlAffinity: ListTileControlAffinity.leading,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
