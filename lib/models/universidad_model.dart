class Universidad {
  final String? id;
  final String nit;
  final String nombre;
  final String direccion;
  final String telefono;
  final String paginaWeb;
  final String? logoUrl;

  Universidad({
    this.id,
    required this.nit,
    required this.nombre,
    required this.direccion,
    required this.telefono,
    required this.paginaWeb,
    this.logoUrl,
  });

  factory Universidad.fromFirestore(String id, Map<String, dynamic> data) {
    return Universidad(
      id: id,
      nit: data['nit'] ?? '',
      nombre: data['nombre'] ?? '',
      direccion: data['direccion'] ?? '',
      telefono: data['telefono'] ?? '',
      paginaWeb: data['pagina_web'] ?? '',
      logoUrl: data['logo_url'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nit': nit,
      'nombre': nombre,
      'direccion': direccion,
      'telefono': telefono,
      'pagina_web': paginaWeb,
      if (logoUrl != null) 'logo_url': logoUrl,
    };
  }
}
