import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/ai_checklist_provider.dart';
import '../providers/checklist_provider.dart';
import '../../domain/entities/trip_context.dart';

/// Pantalla de creación de checklist mediante conversación con IA.
class ConversationalChecklistScreen extends StatefulWidget {
  const ConversationalChecklistScreen({super.key});

  @override
  State<ConversationalChecklistScreen> createState() =>
      _ConversationalChecklistScreenState();
}

class _ConversationalChecklistScreenState
    extends State<ConversationalChecklistScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _isSaving = false;

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    _inputController.clear();
    _focusNode.unfocus();
    await context.read<AIChecklistProvider>().sendMessage(text);
    _scrollToBottom();
  }

  Future<void> _saveChecklist(AIChecklistResult result) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final checklistProvider = context.read<ChecklistProvider>();

    // Nombre automático basado en la primera descripción del usuario
    final aiProvider = context.read<AIChecklistProvider>();
    final firstUserMsg = aiProvider.messages.firstWhere(
      (m) => m.isUser,
      orElse: () =>
          ChatMessage(text: 'Viaje IA', isUser: true, timestamp: DateTime.now()),
    );
    final name = firstUserMsg.text.length > 40
        ? '${firstUserMsg.text.substring(0, 40)}…'
        : firstUserMsg.text;

    final checklistId =
        await checklistProvider.createChecklist(name, 'viaje');

    // Agrega cada item generado
    for (final item in result.items) {
      await checklistProvider.addItemToChecklist(
        checklistId,
        '${item.name} ×${item.quantity}',
      );
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('✅ Checklist guardada exitosamente'),
        backgroundColor: const Color(0xFF00B894),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    context.go('/checklist/$checklistId');
  }

  @override
  Widget build(BuildContext context) {
    final ai = context.watch<AIChecklistProvider>();
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Auto-scroll cuando llegan mensajes nuevos
    if (ai.messages.isNotEmpty) _scrollToBottom();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
                : [const Color(0xFFF8F7FF), const Color(0xFFEEF2FF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(colors),
              Expanded(
                child: ai.messages.isEmpty
                    ? _buildWelcomeState(colors)
                    : _buildChatList(ai, colors, isDark),
              ),
              _buildInputBar(ai, colors, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            style: IconButton.styleFrom(
              backgroundColor: colors.primary.withOpacity(0.1),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6C5CE7),
                  const Color(0xFF0984E3),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PackSmart AI',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Cuéntame tu viaje y armo tu lista',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  title: const Text('¿Limpiar conversación?'),
                  content: const Text(
                      'Se borrará el historial y los items generados.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancelar',
                          style: TextStyle(color: Colors.grey)),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.read<AIChecklistProvider>().reset();
                      },
                      child: const Text('Limpiar'),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Nueva conversación',
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1, end: 0);
  }

  Widget _buildWelcomeState(ColorScheme colors) {
    final suggestions = [
      '🏖️ Voy a la playa este fin de semana con mi bebé, hace mucho calor',
      '✈️ Viaje de trabajo a Bogotá por 3 días, reuniones formales',
      '🏔️ Camping en la montaña, 2 noches, puede llover',
      '🏋️ Rutina de gym de mañana temprano',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C5CE7), Color(0xFF0984E3)],
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6C5CE7).withOpacity(0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 44),
          )
              .animate()
              .fadeIn(delay: 100.ms)
              .scale(begin: const Offset(0.7, 0.7)),
          const SizedBox(height: 20),
          const Text(
            '¿A dónde vas? 🌍',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
          const SizedBox(height: 8),
          Text(
            'Descríbeme tu viaje y te armo la lista perfecta con IA',
            style: TextStyle(fontSize: 15, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 32),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'PRUEBA CON',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: Colors.grey.shade400,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...suggestions.asMap().entries.map((entry) {
            final i = entry.key;
            final s = entry.value;
            return GestureDetector(
              onTap: () {
                _inputController.text = s;
                _send();
              },
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colors.primary.withOpacity(0.15),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  s,
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
              ),
            )
                .animate(delay: (400 + i * 80).ms)
                .fadeIn()
                .slideX(begin: 0.08, end: 0);
          }),
        ],
      ),
    );
  }

  Widget _buildChatList(
      AIChecklistProvider ai, ColorScheme colors, bool isDark) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: ai.messages.length + (ai.isThinking ? 1 : 0),
      itemBuilder: (context, i) {
        if (ai.isThinking && i == ai.messages.length) {
          return _buildThinkingBubble(colors);
        }
        final msg = ai.messages[i];
        return msg.isUser
            ? _buildUserBubble(msg, colors)
            : _buildAIBubble(msg, colors, isDark);
      },
    );
  }

  Widget _buildUserBubble(ChatMessage msg, ColorScheme colors) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6C5CE7), Color(0xFF5A4BD1)],
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(4),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C5CE7).withOpacity(0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          msg.text,
          style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
        ),
      ),
    ).animate().fadeIn(duration: 250.ms).slideX(begin: 0.1, end: 0);
  }

  Widget _buildAIBubble(
      ChatMessage msg, ColorScheme colors, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Avatar IA
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8, bottom: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C5CE7), Color(0xFF0984E3)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
            ),
            Flexible(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 280),
                margin: const EdgeInsets.only(bottom: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2D2D44) : Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(4),
                    bottomRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  msg.text,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ),
          ],
        ),
        // Preview de la checklist generada
        if (msg.checklistResult != null)
          _buildChecklistPreview(msg.checklistResult!, colors, isDark),
        const SizedBox(height: 8),
      ],
    ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.08, end: 0);
  }

  Widget _buildThinkingBubble(ColorScheme colors) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: 32,
          height: 32,
          margin: const EdgeInsets.only(right: 8, bottom: 4),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6C5CE7), Color(0xFF0984E3)],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Pensando',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              ),
              const SizedBox(width: 8),
              _ThinkingDots(),
            ],
          ),
        ),
      ],
    )
        .animate(onPlay: (c) => c.repeat())
        .fadeIn(duration: 300.ms);
  }

  Widget _buildChecklistPreview(
      AIChecklistResult result, ColorScheme colors, bool isDark) {
    final grouped = <String, List<AIGeneratedItem>>{};
    for (final item in result.items) {
      (grouped[item.category] ??= []).add(item);
    }

    return Container(
      margin: const EdgeInsets.only(left: 40, top: 8, bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252540) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF6C5CE7).withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6C5CE7), Color(0xFF0984E3)],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Icon(Icons.checklist_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${result.items.length} items generados',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          // Categorías
          ...grouped.entries.take(4).map((entry) {
            return _buildCategorySection(entry.key, entry.value, isDark);
          }),
          if (grouped.length > 4)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                '+ ${grouped.length - 4} categorías más...',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
              ),
            ),
          // Botones de acción
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        context.read<AIChecklistProvider>().regenerate(),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Regenerar'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        _isSaving ? null : () => _saveChecklist(result),
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child:
                                CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.save_rounded, size: 18),
                    label: Text(_isSaving ? 'Guardando…' : 'Guardar'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      backgroundColor: const Color(0xFF6C5CE7),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildCategorySection(
      String category, List<AIGeneratedItem> items, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            category.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
              color: const Color(0xFF6C5CE7),
            ),
          ),
          const SizedBox(height: 6),
          ...items.take(3).map((item) {
            final priorityColor = item.priority == AIPriority.high
                ? const Color(0xFFD63031)
                : item.priority == AIPriority.medium
                    ? const Color(0xFFFDCB6E)
                    : const Color(0xFF00B894);
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: priorityColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${item.name} ×${item.quantity}',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: priorityColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.priority.label,
                      style: TextStyle(
                        fontSize: 10,
                        color: priorityColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          if (items.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '+ ${items.length - 3} más',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade400,
                ),
              ),
            ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildInputBar(
      AIChecklistProvider ai, ColorScheme colors, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF252540)
                    : const Color(0xFFF4F3FF),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _inputController,
                focusNode: _focusNode,
                enabled: !ai.isThinking,
                maxLines: 4,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Describe tu viaje aquí…',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: Material(
              color: ai.isThinking
                  ? Colors.grey.shade300
                  : const Color(0xFF6C5CE7),
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: ai.isThinking ? null : _send,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: ai.isThinking
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded,
                          color: Colors.white, size: 20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget de los tres puntos animados "pensando".
class _ThinkingDots extends StatefulWidget {
  @override
  State<_ThinkingDots> createState() => _ThinkingDotsState();
}

class _ThinkingDotsState extends State<_ThinkingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i / 3;
            final progress = (_controller.value - delay).clamp(0.0, 1.0);
            final opacity = (progress < 0.5 ? progress * 2 : (1 - progress) * 2)
                .clamp(0.3, 1.0);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color:
                    const Color(0xFF6C5CE7).withOpacity(opacity),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}
