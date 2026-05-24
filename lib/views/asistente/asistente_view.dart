import 'package:flutter/material.dart';
import '../../services/ai_service.dart';
import '../../services/tarea_service.dart';
import '../../models/tarea_model.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter/services.dart';

class AsistenteView extends StatefulWidget {
  const AsistenteView({super.key});

  @override
  State<AsistenteView> createState() => _AsistenteViewState();
}

class _AsistenteViewState extends State<AsistenteView> {
  final AiService _aiService = AiService();
  final TareaService _tareaService = TareaService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<_Mensaje> _mensajes = [];
  List<Tarea> _tareas = [];
  bool _cargando = false;
  bool _inicializado = false;

  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  Future<void> _inicializar() async {
    final tareas = await _tareaService.getPendientes();
    final historialGuardado = await _aiService.cargarHistorial(tareas);

    setState(() {
      _tareas = tareas;
      _inicializado = true;

      if (historialGuardado.isEmpty) {
        // Primera vez: mensaje de bienvenida
        _mensajes = [
          _Mensaje(
            texto:
                '¡Hola! Soy tu asistente académico ✨\n'
                'Veo que tienes ${tareas.length} tareas pendientes. '
                'Puedo ayudarte a organizar tu estudio, explicarte temas o darte consejos. '
                '¿En qué te ayudo hoy?',
            esUsuario: false,
          ),
        ];
      } else {
        // Conversaciones previas: reconstruye los mensajes en pantalla
        _mensajes = historialGuardado.map((m) {
          return _Mensaje(
            texto: m['texto'] as String,
            esUsuario: m['esUsuario'] as bool,
            hora: (m['hora'] as dynamic).toDate(),
          );
        }).toList();
      }
    });
  }

  Future<void> _enviarMensaje() async {
    final texto = _controller.text.trim();
    if (texto.isEmpty || _cargando) return;

    setState(() {
      _mensajes.add(_Mensaje(texto: texto, esUsuario: true));
      _cargando = true;
    });

    _controller.clear();
    _scrollAlFinal();

    final respuesta = await _aiService.enviarMensaje(
      mensaje: texto,
      tareasPendientes: _tareas,
    );

    setState(() {
      _mensajes.add(_Mensaje(texto: respuesta, esUsuario: false));
      _cargando = false;
    });

    _scrollAlFinal();
  }

  void _scrollAlFinal() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _limpiarChat() {
    _aiService.limpiarHistorial();
    setState(() {
      _mensajes = [
        _Mensaje(
          texto: 'Chat reiniciado ✨ ¿En qué te puedo ayudar?',
          esUsuario: false,
        ),
      ];
    });
  }

  void _usarSugerencia(String texto) {
    _controller.text = texto;
    _enviarMensaje();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F1117)
          : const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1A1D2E) : primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Asistente IA',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'StudyManager',
                  style: TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Nuevo chat',
            onPressed: _limpiarChat,
          ),
        ],
      ),
      body: !_inicializado
          ? Center(child: CircularProgressIndicator(color: primary))
          : Column(
              children: [
                // Banner urgentes
                if (_tareas.any(
                  (t) => t.fechaEntrega.difference(DateTime.now()).inDays <= 2,
                ))
                  _BannerUrgente(tareas: _tareas),

                // Mensajes
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    itemCount: _mensajes.length,
                    itemBuilder: (context, index) =>
                        _BurbujaMensaje(mensaje: _mensajes[index]),
                  ),
                ),

                if (_mensajes.length <= 1 && !_cargando)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _SugerenciasRapidas(onSugerencia: _usarSugerencia),
                  ),

                // Typing indicator
                if (_cargando)
                  Padding(
                    padding: const EdgeInsets.only(left: 20, bottom: 6),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1A1D2E)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF2A2D45)
                                  : Colors.grey.shade200,
                            ),
                          ),
                          child: const _TypingIndicator(),
                        ),
                      ],
                    ),
                  ),

                // Input
                _CampoTexto(
                  controller: _controller,
                  cargando: _cargando,
                  onEnviar: _enviarMensaje,
                ),
              ],
            ),
    );
  }
}

// ── Widgets auxiliares ────────────────────────────────────────────────────────

class _Mensaje {
  final String texto;
  final bool esUsuario;
  final DateTime hora;
  _Mensaje({required this.texto, required this.esUsuario, DateTime? hora})
    : hora = hora ?? DateTime.now();
}

class _BurbujaMensaje extends StatelessWidget {
  final _Mensaje mensaje;
  const _BurbujaMensaje({required this.mensaje});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final esUsuario = mensaje.esUsuario;

    return Align(
      alignment: esUsuario ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () => _copiarTexto(context, mensaje.texto),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78,
          ),
          decoration: BoxDecoration(
            color: esUsuario
                ? primary
                : isDark
                    ? const Color(0xFF1A1D2E)
                    : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(esUsuario ? 18 : 4),
              bottomRight: Radius.circular(esUsuario ? 4 : 18),
            ),
            border: esUsuario
                ? null
                : Border.all(
                    color: isDark
                        ? const Color(0xFF2A2D45)
                        : Colors.grey.shade200,
                  ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Markdown para mensajes de la IA, texto plano para el usuario
              esUsuario
                  ? Text(
                      mensaje.texto,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    )
                  : MarkdownBody(
                      data: mensaje.texto,
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(
                          color: isDark
                              ? const Color(0xFFF0F0FF)
                              : const Color(0xFF1A1A2E),
                          fontSize: 14,
                          height: 1.5,
                        ),
                        strong: TextStyle(
                          color: isDark
                              ? const Color(0xFFF0F0FF)
                              : const Color(0xFF1A1A2E),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                        em: TextStyle(
                          color: isDark
                              ? const Color(0xFFF0F0FF)
                              : const Color(0xFF1A1A2E),
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                        listBullet: TextStyle(
                          color: isDark
                              ? const Color(0xFFF0F0FF)
                              : const Color(0xFF1A1A2E),
                          fontSize: 14,
                        ),
                        code: TextStyle(
                          backgroundColor: isDark
                              ? const Color(0xFF0F1117)
                              : const Color(0xFFF4F6FA),
                          color: primary,
                          fontSize: 13,
                          fontFamily: 'monospace',
                        ),
                        codeblockDecoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF0F1117)
                              : const Color(0xFFF4F6FA),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        blockquoteDecoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(
                              color: primary,
                              width: 3,
                            ),
                          ),
                        ),
                        blockquote: TextStyle(
                          color: isDark
                              ? Colors.white60
                              : Colors.grey.shade600,
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                        h1: TextStyle(
                          color: isDark
                              ? const Color(0xFFF0F0FF)
                              : const Color(0xFF1A1A2E),
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                        h2: TextStyle(
                          color: isDark
                              ? const Color(0xFFF0F0FF)
                              : const Color(0xFF1A1A2E),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        h3: TextStyle(
                          color: isDark
                              ? const Color(0xFFF0F0FF)
                              : const Color(0xFF1A1A2E),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

              const SizedBox(height: 4),

              // Hora + botón copiar
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${mensaje.hora.hour.toString().padLeft(2, '0')}:${mensaje.hora.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 10,
                      color: esUsuario
                          ? Colors.white.withOpacity(0.65)
                          : isDark
                              ? Colors.white38
                              : Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => _copiarTexto(context, mensaje.texto),
                    child: Icon(
                      Icons.copy_rounded,
                      size: 11,
                      color: esUsuario
                          ? Colors.white.withOpacity(0.65)
                          : isDark
                              ? Colors.white38
                              : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _copiarTexto(BuildContext context, String texto) {
    Clipboard.setData(ClipboardData(text: texto));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_rounded, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Text('Texto copiado', style: TextStyle(fontSize: 13)),
          ],
        ),
        backgroundColor: const Color(0xFF6C47FF),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }
}

class _BannerUrgente extends StatelessWidget {
  final List<Tarea> tareas;
  const _BannerUrgente({required this.tareas});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final urgentes = tareas
        .where((t) => t.fechaEntrega.difference(DateTime.now()).inDays <= 2)
        .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: isDark ? const Color(0xFF2A1F00) : const Color(0xFFFFF8E1),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFF5A623),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${urgentes.length} tarea(s) urgente(s): '
              '${urgentes.map((t) => t.titulo).join(', ')}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFF5A623),
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _animController,
          builder: (_, __) {
            final delay = i * 0.3;
            final value = ((_animController.value - delay) % 1.0);
            final scale = value < 0.5
                ? 0.6 + (value / 0.5) * 0.6
                : 1.2 - ((value - 0.5) / 0.5) * 0.6;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: primary.withOpacity(0.7 + scale * 0.15),
                shape: BoxShape.circle,
              ),
              transform: Matrix4.identity()..scale(scale.clamp(0.6, 1.2)),
              transformAlignment: Alignment.center,
            );
          },
        );
      }),
    );
  }
}

class _CampoTexto extends StatelessWidget {
  final TextEditingController controller;
  final bool cargando;
  final VoidCallback onEnviar;

  const _CampoTexto({
    required this.controller,
    required this.cargando,
    required this.onEnviar,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1D2E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: !cargando,
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onEnviar(),
              style: TextStyle(
                color: isDark
                    ? const Color(0xFFF0F0FF)
                    : const Color(0xFF1A1A2E),
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'Pregúntame algo...',
                hintStyle: TextStyle(
                  color: isDark ? Colors.white38 : Colors.grey.shade400,
                  fontSize: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF242840)
                    : const Color(0xFFF4F6FA),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: cargando ? null : onEnviar,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: cargando ? primary.withOpacity(0.5) : primary,
                borderRadius: BorderRadius.circular(23),
                boxShadow: cargando
                    ? []
                    : [
                        BoxShadow(
                          color: primary.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
              ),
              child: Center(
                child: cargando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SugerenciasRapidas extends StatelessWidget {
  final Function(String) onSugerencia;

  const _SugerenciasRapidas({required this.onSugerencia});

  static const _sugerencias = [
    ('¿Qué estudio hoy?', Icons.today_rounded),
    ('Organiza mi semana', Icons.calendar_month_rounded),
    ('¿Qué tarea es más urgente?', Icons.warning_amber_rounded),
    ('Dame un consejo de estudio', Icons.lightbulb_outline_rounded),
    ('¿Cuánto tiempo tengo para mis tareas?', Icons.timer_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _sugerencias.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (texto, icono) = _sugerencias[index];
          return GestureDetector(
            onTap: () => onSugerencia(texto),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF242840) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: primary.withOpacity(0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icono, size: 14, color: primary),
                  const SizedBox(width: 6),
                  Text(
                    texto,
                    style: TextStyle(
                      fontSize: 12,
                      color: primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
