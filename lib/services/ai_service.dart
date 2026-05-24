import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/tarea_model.dart';
import 'firestore_service.dart';

class AiService {
  static const String _apiKey =
      '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';
  static const String _url = 'https://api.groq.com/openai/v1/chat/completions';
  static const String _modelo = 'llama-3.3-70b-versatile';

  final FirestoreService _fs = FirestoreService();
  final List<Map<String, dynamic>> _historialApi = [];
  bool _inicializado = false;

  // Carga el historial guardado en Firestore y lo prepara para la API
  Future<List<Map<String, dynamic>>> cargarHistorial(
    List<Tarea> tareasPendientes,
  ) async {
    if (_inicializado) return [];

    final mensajes = await _fs.obtenerHistorialChat();
    final pomodoro = await _fs.obtenerResumenPomodoro();
    _inicializado = true;

    if (mensajes.isEmpty) return [];

    // Reconstruye el historial para la API
    for (final m in mensajes) {
      _historialApi.add({
        'role': m['esUsuario'] == true ? 'user' : 'assistant',
        'content': m['texto'],
      });
    }

    // Inyecta contexto actualizado de tareas al inicio
    _historialApi.insert(0, {
      'role': 'system',
      'content': _construirContexto(tareasPendientes, pomodoro),
    });

    return mensajes;
  }

  Future<String> enviarMensaje({
    required String mensaje,
    required List<Tarea> tareasPendientes,
  }) async {
    // Primera vez: agrega el contexto del sistema
    if (_historialApi.isEmpty) {
      final pomodoro = await _fs.obtenerResumenPomodoro();
      _historialApi.add({
        'role': 'system',
        'content': _construirContexto(tareasPendientes, pomodoro),
      });
    }

    // Agrega el mensaje del usuario
    _historialApi.add({'role': 'user', 'content': mensaje});

    // Guarda en Firestore
    await _fs.guardarMensaje(
      texto: mensaje,
      esUsuario: true,
      hora: DateTime.now(),
    );

    try {
      final response = await http.post(
        Uri.parse(_url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _modelo,
          'messages': _historialApi,
          'max_tokens': 1024,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final respuesta = data['choices'][0]['message']['content'] as String;

        // Agrega al historial de la API
        _historialApi.add({'role': 'assistant', 'content': respuesta});

        // Guarda en Firestore
        await _fs.guardarMensaje(
          texto: respuesta,
          esUsuario: false,
          hora: DateTime.now(),
        );

        return respuesta;
      } else {
        final error = jsonDecode(response.body);
        return 'Error: ${error['error']['message'] ?? 'Intenta de nuevo'}';
      }
    } catch (e) {
      return 'Sin conexión. Verifica tu internet e intenta de nuevo.';
    }
  }

  String _construirContexto(List<Tarea> tareas, Map<String, dynamic> pomodoro) {
    final ahora = DateTime.now();

    final tareasTexto = tareas.isEmpty
        ? 'No tienes tareas pendientes.'
        : tareas
              .map((t) {
                final diasRestantes = t.fechaEntrega.difference(ahora).inDays;
                final urgencia = diasRestantes < 0
                    ? '🔴 VENCIDA'
                    : diasRestantes <= 1
                    ? '🔴 URGENTE'
                    : diasRestantes <= 3
                    ? '🟡 Próxima'
                    : '🟢 Con tiempo';
                return '- ${t.titulo} | Materia: ${t.materia} | Tipo: ${t.tipo} | '
                    'Prioridad: ${t.prioridad} | Entrega: ${t.fechaEntrega.day}/${t.fechaEntrega.month}/${t.fechaEntrega.year} '
                    '| $urgencia ($diasRestantes días)';
              })
              .join('\n');

    return '''
Eres un asistente académico dentro de una app llamada StudyManager.
Ayudas a estudiantes universitarios a organizar su estudio, gestionar tareas y rendir mejor.
Responde siempre en español, de forma amigable, motivadora y concisa (máximo 3 párrafos).
Si te preguntan sobre un tema académico, explícalo claramente con ejemplos prácticos.
Si te preguntan por horarios, sugiere bloques específicos considerando las fechas de entrega.

📚 Tareas pendientes:
$tareasTexto

🍅 Rendimiento pomodoro:
- Sesiones de enfoque hoy: ${pomodoro['enfoqueHoy']}
- Descansos tomados hoy: ${pomodoro['descansosHoy']}
- Productividad promedio hoy: ${pomodoro['productividadHoy']}%
- Sesiones de enfoque esta semana: ${pomodoro['enfoqueSemana']}
- Mejor productividad de la semana: ${pomodoro['mejorProductividad']}%
- Total sesiones registradas: ${pomodoro['totalSesiones']}
''';
  }

  Future<void> limpiarHistorial() async {
    _historialApi.clear();
    _inicializado = false;
    await _fs.limpiarHistorialChat();
  }
}
