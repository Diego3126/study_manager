class Tarea {
  final int? id;
  final String titulo;
  final String descripcion;
  final String materia;
  final String tipo;
  final String prioridad;
  final DateTime fechaEntrega;
  final bool completada;
  final DateTime creadaEn;

  Tarea({
    this.id,
    required this.titulo,
    required this.descripcion,
    required this.materia,
    required this.tipo,
    required this.prioridad,
    required this.fechaEntrega,
    this.completada = false,
    DateTime? creadaEn,
  }) : creadaEn = creadaEn ?? DateTime.now();

  // Para guardar en SQLite
  Map<String, dynamic> toMap() {
    return {
      'id':            id,
      'titulo':        titulo,
      'descripcion':   descripcion,
      'materia':       materia,
      'tipo':          tipo,
      'prioridad':     prioridad,
      'fechaEntrega':  fechaEntrega.toIso8601String(),
      'completada':    completada ? 1 : 0,
      'creadaEn':      creadaEn.toIso8601String(),
    };
  }

  // Para leer desde SQLite
  factory Tarea.fromMap(Map<String, dynamic> map) {
    return Tarea(
      id:           map['id'],
      titulo:       map['titulo']      ?? '',
      descripcion:  map['descripcion'] ?? '',
      materia:      map['materia']     ?? '',
      tipo:         map['tipo']        ?? 'Tarea',
      prioridad:    map['prioridad']   ?? 'Media',
      fechaEntrega: DateTime.parse(map['fechaEntrega']),
      completada:   map['completada']  == 1,
      creadaEn:     DateTime.parse(map['creadaEn']),
    );
  }

  // Para crear una copia con cambios
  Tarea copyWith({
    int? id,
    String? titulo,
    String? descripcion,
    String? materia,
    String? tipo,
    String? prioridad,
    DateTime? fechaEntrega,
    bool? completada,
  }) {
    return Tarea(
      id:           id           ?? this.id,
      titulo:       titulo       ?? this.titulo,
      descripcion:  descripcion  ?? this.descripcion,
      materia:      materia      ?? this.materia,
      tipo:         tipo         ?? this.tipo,
      prioridad:    prioridad    ?? this.prioridad,
      fechaEntrega: fechaEntrega ?? this.fechaEntrega,
      completada:   completada   ?? this.completada,
      creadaEn:     creadaEn,
    );
  }
}