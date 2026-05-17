class Usuario {
  final String uid;
  final String nombre;
  final String email;
  final String telefono;
  final String carrera;
  final String semestre;
  final String universidad;

  Usuario({
    required this.uid,
    required this.nombre,
    required this.email,
    this.telefono    = '',
    this.carrera     = '',
    this.semestre    = '',
    this.universidad = '',
  });

  factory Usuario.fromFirestore(String uid, Map<String, dynamic> data) {
    return Usuario(
      uid:          uid,
      nombre:       data['nombre']       ?? '',
      email:        data['email']        ?? '',
      telefono:     data['telefono']     ?? '',
      carrera:      data['carrera']      ?? '',
      semestre:     data['semestre']     ?? '',
      universidad:  data['universidad']  ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nombre':      nombre,
      'email':       email,
      'telefono':    telefono,
      'carrera':     carrera,
      'semestre':    semestre,
      'universidad': universidad,
    };
  }

  Usuario copyWith({
    String? nombre,
    String? email,
    String? telefono,
    String? carrera,
    String? semestre,
    String? universidad,
  }) {
    return Usuario(
      uid:          uid,
      nombre:       nombre       ?? this.nombre,
      email:        email        ?? this.email,
      telefono:     telefono     ?? this.telefono,
      carrera:      carrera      ?? this.carrera,
      semestre:     semestre     ?? this.semestre,
      universidad:  universidad  ?? this.universidad,
    );
  }
}