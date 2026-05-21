import 'package:flutter/material.dart';
class Tarea {
  final String? firestoreId;
  final String titulo;
  final String descripcion;
  final String materia;
  final String tipo;
  final String prioridad;
  final DateTime fechaEntrega;
  final TimeOfDay? horaEntrega; // ← NUEVO
  final bool completada;
  final DateTime creadaEn;
  final List<String> archivos;

  Tarea({
    this.firestoreId,
    required this.titulo,
    required this.descripcion,
    required this.materia,
    required this.tipo,
    required this.prioridad,
    required this.fechaEntrega,
    this.horaEntrega, // ← NUEVO
    this.completada = false,
    DateTime? creadaEn,
    this.archivos = const [],
  }) : creadaEn = creadaEn ?? DateTime.now();

  Map<String, dynamic> toFirestore() {
    return {
      'titulo':        titulo,
      'descripcion':   descripcion,
      'materia':       materia,
      'tipo':          tipo,
      'prioridad':     prioridad,
      'fechaEntrega':  fechaEntrega.toIso8601String(),
      // Guarda hora como "HH:mm", o null si no se eligió
      'horaEntrega':   horaEntrega != null
          ? '${horaEntrega!.hour.toString().padLeft(2, '0')}:${horaEntrega!.minute.toString().padLeft(2, '0')}'
          : null, // ← NUEVO
      'completada':    completada,
      'creadaEn':      creadaEn.toIso8601String(),
      'archivos':      archivos,
    };
  }

  factory Tarea.fromFirestore(String id, Map<String, dynamic> data) {
    // Parsea "HH:mm" de vuelta a TimeOfDay
    TimeOfDay? hora;
    if (data['horaEntrega'] != null) {
      final partes = (data['horaEntrega'] as String).split(':');
      hora = TimeOfDay(hour: int.parse(partes[0]), minute: int.parse(partes[1]));
    }

    return Tarea(
      firestoreId:  id,
      titulo:       data['titulo']        ?? '',
      descripcion:  data['descripcion']   ?? '',
      materia:      data['materia']       ?? '',
      tipo:         data['tipo']          ?? 'Tarea',
      prioridad:    data['prioridad']     ?? 'Media',
      fechaEntrega: DateTime.parse(data['fechaEntrega']),
      horaEntrega:  hora, // ← NUEVO
      completada:   data['completada']    ?? false,
      creadaEn:     DateTime.parse(data['creadaEn']),
      archivos:     List<String>.from(data['archivos'] ?? []),
    );
  }

  Tarea copyWith({
    String? firestoreId,
    String? titulo,
    String? descripcion,
    String? materia,
    String? tipo,
    String? prioridad,
    DateTime? fechaEntrega,
    TimeOfDay? horaEntrega, // ← NUEVO
    bool? completada,
    DateTime? creadaEn,
    List<String>? archivos,
  }) {
    return Tarea(
      firestoreId:  firestoreId  ?? this.firestoreId,
      titulo:       titulo       ?? this.titulo,
      descripcion:  descripcion  ?? this.descripcion,
      materia:      materia      ?? this.materia,
      tipo:         tipo         ?? this.tipo,
      prioridad:    prioridad    ?? this.prioridad,
      fechaEntrega: fechaEntrega ?? this.fechaEntrega,
      horaEntrega:  horaEntrega  ?? this.horaEntrega, // ← NUEVO
      completada:   completada   ?? this.completada,
      creadaEn:     creadaEn     ?? this.creadaEn,
      archivos:     archivos     ?? this.archivos,
    );
  }
}