# StudyManager 📚

Aplicación móvil desarrollada en **Flutter** como proyecto de la asignatura **Electiva Profesional I** en la Unidad Central del Valle del Cauca (UCEVA). StudyManager es una agenda académica inteligente que demuestra conceptos fundamentales de programación asíncrona en Dart/Flutter: `Future`, `async/await`, `Timer` e `Isolate`.

---

## Tabla de contenidos

1. [Descripción general](#descripción-general)
2. [Estructura del proyecto](#estructura-del-proyecto)
3. [Pantallas y flujos](#pantallas-y-flujos)
4. [Conceptos de asincronía](#conceptos-de-asincronía)
5. [Cuándo usar cada herramienta](#cuándo-usar-cada-herramienta)
6. [Navegación con go_router](#navegación-con-go_router)
7. [Cómo ejecutar el proyecto](#cómo-ejecutar-el-proyecto)
8. [Dependencias](#dependencias)

---

## Descripción general

StudyManager resuelve el problema de la desorganización académica que enfrentan estudiantes de secundaria y universidad. La app permite registrar tareas, trabajos y exámenes, y organiza las actividades de forma inteligente.

En esta versión del proyecto se integran módulos que demuestran el uso de programación asíncrona en Flutter, sin bloquear la interfaz de usuario en ningún momento.

**Público objetivo:** Estudiantes de 13 a 25 años.

---

## Estructura del proyecto

```
study_manager/
├── lib/
│   ├── main.dart                        # Punto de entrada de la app
│   ├── app_router.dart                  # Configuración centralizada de rutas
│   ├── app_theme.dart                   # Tema visual global
│   ├── home_screen.dart                 # Pantalla de inicio
│   │
│   ├── widgets/
│   │   ├── base_view.dart               # Componente base reutilizable (AppBar + Drawer)
│   │   └── custom_drawer.dart           # Menú lateral de navegación
│   │
│   ├── paso_parametros/
│   │   ├── paso_parametros_screen.dart  # Envío de parámetros entre pantallas
│   │   └── detalle_screen.dart          # Recepción de parámetros
│   │
│   ├── ciclo_vida/
│   │   └── ciclo_vida_screen.dart       # Ciclo de vida de StatefulWidget
│   │
│   ├── future/
│   │   └── future_view.dart             # Asincronía con Future / async / await
│   │
│   ├── timer/
│   │   └── timer_view.dart              # Cronómetro con Timer
│   │
│   └── isolate/
│       └── isolate_view.dart            # Tarea pesada con Isolate
│
├── pubspec.yaml                         # Dependencias y metadatos del proyecto
└── README.md                            # Este archivo
```

### Rol de cada archivo principal

| Archivo | Qué hace |
|---|---|
| `main.dart` | Inicializa la app con `MaterialApp.router`, aplica el tema y conecta el router |
| `app_router.dart` | Define todas las rutas de la app en un solo lugar usando `GoRouter` |
| `app_theme.dart` | Centraliza colores, tipografía y estilos del AppBar y Drawer |
| `base_view.dart` | Widget reutilizable que evita repetir Scaffold + AppBar + Drawer en cada pantalla |
| `custom_drawer.dart` | Menú lateral con acceso a todas las secciones de la app |

---

## Pantallas y flujos

### Pantallas disponibles

| Ruta | Pantalla | Descripción |
|---|---|---|
| `/` | HomeScreen | Dashboard de bienvenida |
| `/paso_parametros` | PasoParametrosScreen | Demuestra go, push y replace |
| `/detalle/:param/:metodo` | DetalleScreen | Recibe parámetros por URL |
| `/ciclo_vida` | CicloVidaScreen | Muestra initState, setState, dispose |
| `/future` | FutureView | Carga datos con Future y async/await |
| `/timer` | TimerView | Cronómetro con Timer |
| `/isolate` | IsolateView | Tarea pesada en hilo secundario |

---

### Flujo 1 — Future / async / await (FutureView)

```
Usuario entra a /future
        │
        ▼
initState() → obtenerDatos() llamado
        │
        ▼
Estado: 'cargando' → UI muestra CircularProgressIndicator
        │
        ▼
cargarNombres() → Future.delayed(3s) → datos listos
        │
        ├─── Éxito → Estado: 'exito' → UI muestra GridView con 20 nombres
        │
        └─── Error → Estado: 'error' → UI muestra mensaje + botón Reintentar
```

**Orden de ejecución impreso en consola:**
```
>>> [FutureView] initState — antes de cargar datos
>>> [FutureView] obtenerDatos — estado: cargando
>>> [FutureView] cargarNombres — inicio (esperando 3s)
>>> [FutureView] cargarNombres — datos listos
>>> [FutureView] obtenerDatos — estado: éxito
```

---

### Flujo 2 — Timer / Cronómetro (TimerView)

```
Estado inicial: 00:00 — Pausado
        │
        ▼ [Botón Iniciar]
Timer.periodic(1s) → _segundos++ → setState() → UI actualiza cada segundo
        │
        ├─── [Botón Pausar] → timer.cancel() → UI muestra ⏸ Pausado
        │          │
        │          ▼ [Botón Reanudar]
        │       Timer.periodic nuevo → continúa desde donde pausó
        │
        └─── [Botón Reiniciar] → timer.cancel() → _segundos = 0 → 00:00
        
Al salir de la pantalla:
        dispose() → timer?.cancel() → recursos liberados
```

**Estados del cronómetro:**

| Estado | Botones visibles | Indicador |
|---|---|---|
| Inicial (00:00) | Iniciar, Reiniciar | ⏸ Pausado |
| Corriendo | Pausar, Reiniciar | ▶ Corriendo |
| Pausado (> 00:00) | Reanudar, Reiniciar | ⏸ Pausado |

---

### Flujo 3 — Isolate / Tarea pesada (IsolateView)

```
Usuario presiona "Ejecutar tarea en segundo plano"
        │
        ▼
UI muestra CircularProgressIndicator (no se bloquea)
        │
        ▼
Isolate.spawn(_simulacionTareaPesada, receivePort.sendPort)
        │
        ▼
Hilo secundario: suma del 1 al 1,000,000 (tarea CPU-bound)
        │
        ▼
Isolate envía resultado por SendPort → hilo principal recibe
        │
        ▼
setState() → UI muestra resultado + Isolate.exit()
```

**Comunicación entre hilos:**
```
Hilo principal                    Isolate (hilo secundario)
      │                                    │
      │── Isolate.spawn() ────────────────>│
      │<─ sendPort del isolate ────────────│
      │── sendPort.send([datos, reply]) ──>│
      │                                    │── procesa (suma 1..1,000,000)
      │<─ replyPort.send(resultado) ───────│
      │                                    │── Isolate.exit()
      │── setState() → actualiza UI
```

---

## Conceptos de asincronía

### Future y async/await

Un `Future` representa un valor que estará disponible en el futuro (puede ser datos de una API, lectura de archivos, etc.). `async/await` es la forma más legible de trabajar con `Future` sin anidar callbacks.

```dart
// Sin async/await (callbacks anidados — difícil de leer)
cargarDatos().then((datos) {
  procesarDatos(datos).then((resultado) {
    mostrarResultado(resultado);
  });
});

// Con async/await (secuencial y legible)
Future<void> cargarYMostrar() async {
  final datos = await cargarDatos();       // espera sin bloquear la UI
  final resultado = await procesarDatos(datos);
  mostrarResultado(resultado);
}
```

**Cómo funciona en FutureView:**
```dart
Future<void> obtenerDatos() async {
  setState(() => _estado = 'cargando');         // UI muestra spinner
  try {
    final datos = await cargarNombres();        // espera 3 segundos
    setState(() {
      _nombres = datos;
      _estado = 'exito';                        // UI muestra GridView
    });
  } catch (e) {
    setState(() => _estado = 'error');          // UI muestra error
  }
}
```

---

### Timer

`Timer` de `dart:async` ejecuta una función después de un tiempo determinado. `Timer.periodic` la repite en intervalos regulares.

```dart
// Ejecutar una vez después de 2 segundos
Timer(Duration(seconds: 2), () {
  print('Han pasado 2 segundos');
});

// Ejecutar cada segundo (cronómetro)
Timer.periodic(Duration(seconds: 1), (timer) {
  setState(() => _segundos++);
});

// Cancelar el timer (importante para liberar recursos)
timer.cancel();
```

**Regla fundamental:** siempre cancelar el `Timer` en `dispose()` para evitar memory leaks:
```dart
@override
void dispose() {
  _timer?.cancel();   // libera el timer al salir de la pantalla
  super.dispose();
}
```

---

### Isolate

Un `Isolate` es un hilo de ejecución independiente con su propia memoria. En Dart, el hilo principal (UI thread) no debe ejecutar tareas pesadas porque bloquearía la interfaz. Los `Isolate` permiten ejecutar esas tareas en paralelo.

```dart
// Sin Isolate — BLOQUEA la UI (incorrecto para tareas pesadas)
int sumaGrande() {
  int total = 0;
  for (int i = 1; i <= 1000000; i++) total += i;
  return total;  // la UI se congela mientras esto corre
}

// Con Isolate — NO bloquea la UI (correcto)
await Isolate.spawn(funcionPesada, receivePort.sendPort);
final resultado = await receivePort.first;  // UI sigue respondiendo
```

**Comunicación con mensajes (SendPort / ReceivePort):**
```dart
// Los Isolates no comparten memoria, se comunican por mensajes
static void funcionPesada(SendPort sendPort) {
  // ejecuta la tarea...
  sendPort.send('resultado');  // envía el resultado al hilo principal
}
```

---

## Cuándo usar cada herramienta

| Herramienta | Usar cuando... | Ejemplo típico |
|---|---|---|
| `Future` + `async/await` | Se necesita esperar un resultado sin bloquear la UI. La tarea involucra I/O: red, base de datos, archivos. | Llamar una API, leer SharedPreferences, consultar SQLite |
| `Timer` | Se necesita ejecutar código después de un tiempo o de forma periódica. | Cronómetros, cuenta regresiva, polling, animaciones manuales |
| `Isolate` | La tarea es intensiva en CPU y tardaría más de unos pocos milisegundos. | Procesamiento de imágenes, cifrado, cálculos matemáticos complejos, parsing de JSON grande |
| Solo `setState` | La operación es inmediata y no involucra espera ni cálculo pesado. | Cambiar el valor de un contador, mostrar/ocultar un widget |

### Comparación rápida

```
Tarea de red (API)          → Future + async/await   ✅
Tarea de archivos           → Future + async/await   ✅
Cuenta regresiva            → Timer                  ✅
Suma del 1 al 1,000,000     → Isolate                ✅
Procesamiento de imagen     → Isolate                ✅
Cambiar color de un botón   → setState               ✅
```

### ¿Por qué NO usar Isolate para todo?

Los `Isolate` tienen un costo de creación y no comparten memoria, por lo que para tareas simples de I/O es innecesario y más complejo. `async/await` es suficiente para operaciones de red o archivos porque estas tareas ya son no bloqueantes por naturaleza.

---

## Navegación con go_router

Todas las rutas están definidas centralizadamente en `app_router.dart`:

```dart
final GoRouter appRouter = GoRouter(
  routes: [
    GoRoute(path: '/',              builder: (c, s) => const HomeScreen()),
    GoRoute(path: '/future',        builder: (c, s) => const FutureView()),
    GoRoute(path: '/timer',         builder: (c, s) => const TimerView()),
    GoRoute(path: '/isolate',       builder: (c, s) => const IsolateView()),
    GoRoute(path: '/ciclo_vida',    builder: (c, s) => const CicloVidaScreen()),
    GoRoute(path: '/paso_parametros', builder: (c, s) => const PasoParametrosScreen()),
    GoRoute(
      path: '/detalle/:parametro/:metodo',
      builder: (c, s) => DetalleScreen(
        parametro: s.pathParameters['parametro']!,
        metodoNavegacion: s.pathParameters['metodo']!,
      ),
    ),
  ],
);
```

| Método | Comportamiento |
|---|---|
| `context.go('/ruta')` | Reemplaza toda la pila — no hay botón atrás |
| `context.push('/ruta')` | Apila la ruta — el usuario puede volver |
| `context.replace('/ruta')` | Reemplaza la ruta actual manteniendo el historial previo |
| `context.pop()` | Vuelve a la pantalla anterior (solo si fue push) |

---

## Cómo ejecutar el proyecto

### Requisitos previos

- Flutter SDK 3.x instalado
- Android Studio con un emulador configurado (API 34 recomendado)
- VS Code con las extensiones Flutter y Dart

### Pasos

```bash
# 1. Clonar o abrir el proyecto
cd study_manager

# 2. Instalar dependencias
flutter pub get

# 3. Verificar el entorno
flutter doctor

# 4. Ejecutar la app
flutter run
```

### Comandos útiles durante el desarrollo

```bash
r        # Hot Reload — recarga la UI manteniendo el estado
R        # Hot Restart — reinicia la app completamente
q        # Salir
```

---

## Dependencias

```yaml
dependencies:
  flutter:
    sdk: flutter
  go_router: ^14.x.x    # Navegación declarativa
```

Todas las demás funcionalidades (`Future`, `Timer`, `Isolate`) son parte de la librería estándar de Dart (`dart:async`, `dart:isolate`) y no requieren paquetes adicionales.

---

## Referencias

- [Futures / async/await — dart.dev](https://dart.dev/libraries/async/async-await)
- [Timer class — api.flutter.dev](https://api.flutter.dev/flutter/dart-async/Timer-class.html)
- [Isolates en Flutter — docs.flutter.dev](https://docs.flutter.dev/perf/isolates)
- [go_router — pub.dev](https://pub.dev/packages/go_router)
- [Widget catalog — docs.flutter.dev](https://docs.flutter.dev/ui/widgets)

---

*Proyecto desarrollado por Diego Fernando España Valderrama — Electiva Profesional I, UCEVA 2026*