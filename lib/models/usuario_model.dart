class Usuario {
  final String uid;
  final String nombre;
  final String email;
  final String telefono;
  final String carrera;
  final String semestre;
  final String universidad;
  final String? fotoPerfil;

  Usuario({
    required this.uid,
    required this.nombre,
    required this.email,
    this.telefono    = '',
    this.carrera     = '',
    this.semestre    = '',
    this.universidad = '',
    this.fotoPerfil  = '',
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
      fotoPerfil:   data['fotoPerfil']   ?? '',
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
      'fotoPerfil':  fotoPerfil,
    };
  }

  Usuario copyWith({
    String? nombre,
    String? email,
    String? telefono,
    String? carrera,
    String? semestre,
    String? universidad,
    String? fotoPerfil,
  }) {
    return Usuario(
      uid:          uid,
      nombre:       nombre       ?? this.nombre,
      email:        email        ?? this.email,
      telefono:     telefono     ?? this.telefono,
      carrera:      carrera      ?? this.carrera,
      semestre:     semestre     ?? this.semestre,
      universidad:  universidad  ?? this.universidad,
      fotoPerfil:   fotoPerfil   ?? this.fotoPerfil,
    );
  }
}