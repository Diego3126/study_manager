import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/universidad_model.dart';
import '../../services/universidad_service.dart';
import '../../themes/app_theme.dart';

class UniversidadFormView extends StatefulWidget {
  const UniversidadFormView({super.key});

  @override
  State<UniversidadFormView> createState() => _UniversidadFormViewState();
}

class _UniversidadFormViewState extends State<UniversidadFormView> {
  final _formKey   = GlobalKey<FormState>();
  final _nit       = TextEditingController();
  final _nombre    = TextEditingController();
  final _direccion = TextEditingController();
  final _telefono  = TextEditingController();
  final _paginaWeb = TextEditingController();
  bool  _guardando = false;

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      await UniversidadService().crear(Universidad(
        nit:       _nit.text.trim(),
        nombre:    _nombre.text.trim(),
        direccion: _direccion.text.trim(),
        telefono:  _telefono.text.trim(),
        paginaWeb: _paginaWeb.text.trim(),
      ));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:         Text('Universidad registrada correctamente'),
          backgroundColor: Colors.green,
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:         Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  void dispose() {
    _nit.dispose();
    _nombre.dispose();
    _direccion.dispose();
    _telefono.dispose();
    _paginaWeb.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva Universidad')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(
                child: CircleAvatar(
                  radius:          36,
                  backgroundColor: AppTheme.primary,
                  child: Icon(Icons.account_balance,
                      color: Colors.white, size: 36),
                ),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _nit,
                decoration: const InputDecoration(
                  labelText:  'NIT *',
                  prefixIcon: Icon(Icons.badge_outlined),
                  hintText:   'Ej: 890.123.456-7',
                ),
                validator: (v) => v == null || v.isEmpty
                    ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _nombre,
                decoration: const InputDecoration(
                  labelText:  'Nombre *',
                  prefixIcon: Icon(Icons.account_balance_outlined),
                ),
                validator: (v) => v == null || v.isEmpty
                    ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _direccion,
                decoration: const InputDecoration(
                  labelText:  'Dirección *',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                validator: (v) => v == null || v.isEmpty
                    ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller:  _telefono,
                decoration: const InputDecoration(
                  labelText:  'Teléfono *',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                keyboardType: TextInputType.phone,
                validator: (v) => v == null || v.isEmpty
                    ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _paginaWeb,
                decoration: const InputDecoration(
                  labelText:  'Página web *',
                  prefixIcon: Icon(Icons.language),
                  hintText:   'https://www.universidad.edu.co',
                ),
                keyboardType: TextInputType.url,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Campo requerido';
                  final uri = Uri.tryParse(v);
                  if (uri == null || !uri.hasScheme ||
                      (!uri.scheme.startsWith('http')))
                    return 'Ingresa una URL válida (https://...)';
                  return null;
                },
              ),
              const SizedBox(height: 28),

              ElevatedButton.icon(
                onPressed: _guardando ? null : _guardar,
                icon: _guardando
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save_outlined),
                label: Text(_guardando
                    ? 'Guardando...' : 'Registrar universidad'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}