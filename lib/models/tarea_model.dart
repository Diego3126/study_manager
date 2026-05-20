class Tarea {
  final String? firestoreId;  // ID de Firestore (reemplaza el int de SQLite)
  final String titulo;
  final String descripcion;
  final String materia;
  final String tipo;
  final String prioridad;
  final DateTime fechaEntrega;
  final bool completada;
  final DateTime creadaEn;
  final List<String> archivos; // URLs de los archivos adjuntos

  Tarea({
    this.firestoreId,
    required this.titulo,
    required this.descripcion,
    required this.materia,
    required this.tipo,
    required this.prioridad,
    required this.fechaEntrega,
    this.completada = false,
    DateTime? creadaEn,
    this.archivos = const [],
  }) : creadaEn = creadaEn ?? DateTime.now();

  // Para guardar en Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'titulo':        titulo,
      'descripcion':   descripcion,
      'materia':       materia,
      'tipo':          tipo,
      'prioridad':     prioridad,
      'fechaEntrega':  fechaEntrega.toIso8601String(),
      'completada':    completada,
      'creadaEn':      creadaEn.toIso8601String(),
      'archivos':      archivos,
    };
  }

  // Para leer desde Firestore
  factory Tarea.fromFirestore(String id, Map<String, dynamic> data) {
    return Tarea(
      firestoreId:  id,
      titulo:       data['titulo']        ?? '',
      descripcion:  data['descripcion']   ?? '',
      materia:      data['materia']       ?? '',
      tipo:         data['tipo']          ?? 'Tarea',
      prioridad:    data['prioridad']     ?? 'Media',
      fechaEntrega: DateTime.parse(data['fechaEntrega']),
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
      completada:   completada   ?? this.completada,
      creadaEn:     creadaEn,
      archivos:     archivos     ?? this.archivos,
    );
  }
}