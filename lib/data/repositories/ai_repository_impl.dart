import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../domain/entities/trip_context.dart';
import '../../domain/repositories/ai_repository.dart';

/// Implementación concreta de AIRepository usando la API de Anthropic (Claude).
class AIRepositoryImpl implements AIRepository {
  // ── Configura tu clave en un archivo .env o como constante de compilación.
  // Ejemplo: flutter run --dart-define=ANTHROPIC_API_KEY=sk-ant-xxx
  static const String _apiKey = String.fromEnvironment(
    'ANTHROPIC_API_KEY',
    defaultValue: '',
  );
  static const String _endpoint = 'https://api.anthropic.com/v1/messages';
  static const String _model = 'claude-sonnet-4-20250514';
  static const String _anthropicVersion = '2023-06-01';

  static const String _systemPrompt = '''
Eres un asistente experto en ayudar a las personas a preparar sus equipajes y checklists de viaje.
El usuario te describirá su viaje en lenguaje natural. Tu tarea es generar una checklist completa,
priorizada y organizada por categorías.

REGLAS ESTRICTAS:
1. Responde ÚNICAMENTE con JSON válido, sin texto adicional, sin markdown, sin explicaciones.
2. El JSON debe seguir exactamente esta estructura:
{
  "items": [
    {
      "name": "Nombre del item en español",
      "quantity": 1,
      "category": "Categoría en español",
      "priority": "high" | "medium" | "low"
    }
  ]
}
3. Los items de priority "high" son los más importantes (documentos, medicamentos, etc.).
4. Genera entre 10 y 25 items según la complejidad del viaje.
5. Agrupa por categorías: Documentos, Ropa, Higiene, Electrónicos, Salud, Comida, Entretenimiento, etc.
6. Adapta la lista al tipo de viaje: playa, montaña, trabajo, gym, etc.
7. Si se menciona clima (lluvia, frío, calor), ajusta los items en consecuencia.
8. Si hay bebés o niños, incluye sus items específicos.
''';

  @override
  Future<AIChecklistResult> generateChecklist(TripContext tripContext) async {
    if (_apiKey.isEmpty) {
      throw Exception(
        'ANTHROPIC_API_KEY no configurada. '
        'Ejecuta con: flutter run --dart-define=ANTHROPIC_API_KEY=tu_clave',
      );
    }

    final userMessage = _buildUserMessage(tripContext);

    final body = jsonEncode({
      'model': _model,
      'max_tokens': 2048,
      'system': _systemPrompt,
      'messages': [
        {'role': 'user', 'content': userMessage},
      ],
    });

    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {
        'x-api-key': _apiKey,
        'anthropic-version': _anthropicVersion,
        'content-type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode != 200) {
      debugPrint('Anthropic error ${response.statusCode}: ${response.body}');
      throw Exception(
        'Error al contactar la IA (${response.statusCode}). '
        'Verifica tu API key y conexión.',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final content = (decoded['content'] as List<dynamic>).first;
    final rawText = content['text'] as String;

    // Extraer JSON aunque el modelo envíe texto alrededor
    final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(rawText);
    if (jsonMatch == null) {
      throw const FormatException('La IA no devolvió JSON válido.');
    }

    final checklistJson =
        jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
    return AIChecklistResult.fromJson(checklistJson);
  }

  String _buildUserMessage(TripContext ctx) {
    final buffer = StringBuffer();
    buffer.writeln('Descripción del viaje: ${ctx.description}');
    if (ctx.destination != null && ctx.destination!.isNotEmpty) {
      buffer.writeln('Destino: ${ctx.destination}');
    }
    if (ctx.travelType != null && ctx.travelType!.isNotEmpty) {
      buffer.writeln('Tipo de viaje: ${ctx.travelType}');
    }
    if (ctx.duration != null && ctx.duration!.isNotEmpty) {
      buffer.writeln('Duración: ${ctx.duration}');
    }
    if (ctx.companions != null && ctx.companions!.isNotEmpty) {
      buffer.writeln('Acompañantes: ${ctx.companions}');
    }
    buffer.writeln('\nGenera la checklist en JSON:');
    return buffer.toString();
  }
}
