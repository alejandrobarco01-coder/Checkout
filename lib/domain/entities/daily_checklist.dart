import 'package:flutter/material.dart';

/// Entidad simple para el Checklist Diario del usuario
class DailyChecklistItem {
  final String id;
  final String nombre;
  final String emoji;
  bool completado;
  final int orden;

  DailyChecklistItem({
    required this.id,
    required this.nombre,
    required this.emoji,
    this.completado = false,
    required this.orden,
  });

  DailyChecklistItem copyWith({
    String? id,
    String? nombre,
    String? emoji,
    bool? completado,
    int? orden,
  }) {
    return DailyChecklistItem(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      emoji: emoji ?? this.emoji,
      completado: completado ?? this.completado,
      orden: orden ?? this.orden,
    );
  }
}

/// Items predeterminados para el checklist diario
class DailyChecklistDefaults {
  static const List<Map<String, dynamic>> defaultItems = [
    {'id': 'billetera', 'nombre': 'Billetera', 'emoji': '👛'},
    {'id': 'llaves', 'nombre': 'Llaves', 'emoji': '🔑'},
    {'id': 'telefono', 'nombre': 'Teléfono', 'emoji': '📱'},
    {'id': 'auriculares', 'nombre': 'Auriculares', 'emoji': '🎧'},
    {'id': 'reloj', 'nombre': 'Reloj', 'emoji': '⌚'},
    {'id': 'mascarilla', 'nombre': 'Mascarilla', 'emoji': '😷'},
    {'id': 'mochila', 'nombre': 'Mochila', 'emoji': '🎒'},
    {'id': 'botella', 'nombre': 'Botella de agua', 'emoji': '💧'},
  ];
}
