import 'package:flutter/material.dart';
import '../models/tarea_model.dart';
import '../themes/app_theme.dart';

class TareaCard extends StatelessWidget {
  final Tarea tarea;
  final VoidCallback onTap;
  final ValueChanged<bool?> onCompletada;

  const TareaCard({
    super.key,
    required this.tarea,
    required this.onTap,
    required this.onCompletada,
  });

  String _formatFecha(DateTime fecha) {
    final ahora = DateTime.now();
    final hoy   = DateTime(ahora.year, ahora.month, ahora.day);
    final dia   = DateTime(fecha.year, fecha.month, fecha.day);
    final diff  = dia.difference(hoy).inDays;

    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Mañana';
    if (diff == -1) return 'Ayer';
    if (diff < 0) return 'Venció hace ${-diff} días';
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }

  bool get _vencida {
    return !tarea.completada &&
        tarea.fechaEntrega.isBefore(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Checkbox
              Checkbox(
                value: tarea.completada,
                onChanged: onCompletada,
                activeColor: AppTheme.accent,
                shape: const CircleBorder(),
              ),
              const SizedBox(width: 8),
              // Indicador de prioridad
              Container(
                width: 4,
                height: 50,
                decoration: BoxDecoration(
                  color: AppTheme.colorPrioridad(tarea.prioridad),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 10),
              // Contenido
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tarea.titulo,
                      style: TextStyle(
                        fontSize:      15,
                        fontWeight:    FontWeight.bold,
                        decoration:    tarea.completada
                            ? TextDecoration.lineThrough
                            : null,
                        color: tarea.completada ? Colors.grey : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.book_outlined,
                            size: 13, color: Colors.grey.shade600),
                        const SizedBox(width: 3),
                        Text(tarea.materia,
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600)),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.colorTipo(tarea.tipo)
                                .withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            tarea.tipo,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.colorTipo(tarea.tipo),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Fecha
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatFecha(tarea.fechaEntrega),
                    style: TextStyle(
                      fontSize: 12,
                      color: _vencida ? Colors.red : Colors.grey.shade600,
                      fontWeight: _vencida ? FontWeight.bold : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}