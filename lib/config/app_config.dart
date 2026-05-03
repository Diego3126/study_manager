class AppConfig {
  static const String appName = 'StudyManager';
  static const String version = '1.0.0';

  // Categorías de materias
  static const List<String> materias = [
    'Matemáticas',
    'Física',
    'Química',
    'Historia',
    'Literatura',
    'Inglés',
    'Programación',
    'Electiva Profesional',
    'Otra',
  ];

  // Tipos de tarea
  static const List<String> tiposTarea = [
    'Tarea',
    'Examen',
    'Trabajo',
    'Proyecto',
    'Quiz',
    'Exposición',
  ];

  // Prioridades
  static const List<String> prioridades = [
    'Alta',
    'Media',
    'Baja',
  ];
}