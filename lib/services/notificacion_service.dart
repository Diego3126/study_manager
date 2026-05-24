import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../models/tarea_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _inicializado = false;

  // ── Inicializar (llamar desde main.dart) ──────────────────────────────────
  Future<void> init() async {
    if (_inicializado) return;

    tz.initializeTimeZones();

    // Detectar timezone local del dispositivo
    final String zonaLocal = _detectarZonaLocal();
    tz.setLocalLocation(tz.getLocation(zonaLocal));

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    final permitido = await androidPlugin?.canScheduleExactNotifications();
    debugPrint('⏰ ¿Puede programar alarmas exactas? $permitido');

    if (permitido == false) {
      await androidPlugin?.requestExactAlarmsPermission();
    }

    _inicializado = true;
  }

  // ── Programar notificaciones para una tarea ───────────────────────────────
  Future<void> programarParaTarea(Tarea tarea) async {
    if (tarea.firestoreId == null) return;

    // Cancelar las anteriores por si se está editando
    await cancelarParaTarea(tarea.firestoreId!);

    final fechaHora = tarea.fechaHoraEntrega;
    final ahora = DateTime.now();

    debugPrint('🔔 Intentando programar notificaciones para: ${tarea.titulo}');
    debugPrint('📅 Fecha/hora de entrega: $fechaHora');
    debugPrint('🕐 Ahora: $ahora');
    debugPrint('⏰ Zona horaria local: ${tz.local.name}');

    // IDs únicos basados en el firestoreId
    final idBase = tarea.firestoreId.hashCode.abs();
    final id1Dia = idBase;
    final id1Hora = idBase + 1;

    // ── 1 día antes ───────────────────────────────────────────────────────
    final momento1Dia = fechaHora.subtract(const Duration(days: 1));
    if (momento1Dia.isAfter(ahora)) {
      await _programar(
        id: id1Dia,
        titulo: '📚 Tarea mañana',
        cuerpo:
            '${tarea.titulo} vence mañana${tarea.horaEntrega != null ? ' a las ${_formatHora(tarea.horaEntrega!)}' : ''}',
        momento: momento1Dia,
      );
    }

    // ── 1 hora antes ──────────────────────────────────────────────────────
    final momento1Hora = fechaHora.subtract(const Duration(hours: 1));
    if (momento1Hora.isAfter(ahora)) {
      await _programar(
        id: id1Hora,
        titulo: '⏰ Tarea en 1 hora',
        cuerpo:
            '${tarea.titulo} vence en 1 hora${tarea.horaEntrega != null ? ' a las ${_formatHora(tarea.horaEntrega!)}' : ''}',
        momento: momento1Hora,
      );
    }

    debugPrint(
      '📌 1 día antes: $momento1Dia — ¿futuro? ${momento1Dia.isAfter(ahora)}',
    );
    debugPrint(
      '📌 1 hora antes: $momento1Hora — ¿futuro? ${momento1Hora.isAfter(ahora)}',
    );
  }

  // ── Cancelar notificaciones de una tarea ──────────────────────────────────
  Future<void> cancelarParaTarea(String firestoreId) async {
    final idBase = firestoreId.hashCode.abs();
    await _plugin.cancel(idBase); // 1 día antes
    await _plugin.cancel(idBase + 1); // 1 hora antes
  }

  // ── Reprogramar todas las tareas (tras reinicio del dispositivo) ──────────
  Future<void> reprogramarTodas(List<Tarea> tareas) async {
    await _plugin.cancelAll();
    for (final tarea in tareas) {
      if (!tarea.completada) {
        await programarParaTarea(tarea);
      }
    }
  }

  // ── Interno: programar una notificación exacta ────────────────────────────
  Future<void> _programar({
    required int id,
    required String titulo,
    required String cuerpo,
    required DateTime momento,
  }) async {
    final tzMomento = tz.TZDateTime.from(momento, tz.local);

    debugPrint('📬 Programando id=$id');
    debugPrint('   titulo: $titulo');
    debugPrint('   tzMomento: $tzMomento');
    debugPrint('   tz.local: ${tz.local.name}');
    debugPrint('   ahora en tz: ${tz.TZDateTime.now(tz.local)}');

    try {
      await _plugin.zonedSchedule(
        id,
        titulo,
        cuerpo,
        tzMomento,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'tareas_channel',
            'Recordatorios de tareas',
            channelDescription: 'Notificaciones de vencimiento de tareas',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            color: const Color(0xFF6C47FF),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation
                .absoluteTime, // ✅ requerido en v17
      );
      debugPrint('✅ Notificación programada exitosamente id=$id');
    } catch (e) {
      debugPrint('❌ Error programando notificación: $e');
    }
  }

  // ── Helper: detectar zona horaria local ───────────────────────────────────
  String _detectarZonaLocal() {
    try {
      // Intenta con la zona del dispositivo
      final offset = DateTime.now().timeZoneOffset;
      final horas = offset.inHours;
      // Colombia es UTC-5
      if (horas == -5) return 'America/Bogota';
      if (horas == -6) return 'America/Mexico_City';
      if (horas == -3) return 'America/Sao_Paulo';
      if (horas == -4) return 'America/Caracas';
      if (horas == -5) return 'America/Lima';
      return 'America/Bogota'; // fallback
    } catch (_) {
      return 'America/Bogota';
    }
  }

  String _formatHora(TimeOfDay hora) =>
      '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}';
}
