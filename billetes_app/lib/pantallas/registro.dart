import 'package:flutter/material.dart';

import '../servicios/cuentas.dart';
import '../servicios/voz.dart';
import 'inicio.dart';

class PantallaRegistro extends StatefulWidget {
  const PantallaRegistro({super.key});

  @override
  State<PantallaRegistro> createState() => _PantallaRegistroState();
}

class _PantallaRegistroState extends State<PantallaRegistro> {
  final _form = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _usuario = TextEditingController();
  final _clave = TextEditingController();
  final _confirmar = TextEditingController();
  bool _cargando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    Voz.instancia.dictar(['Crear cuenta.', 'Escribe tu nombre, un usuario y una contraseña de al menos cuatro caracteres.']);
  }

  @override
  void dispose() {
    for (final c in [_nombre, _usuario, _clave, _confirmar]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _crear() async {
    if (!_form.currentState!.validate()) {
      Voz.instancia.decir('Revisa los datos marcados en rojo.', sonido: Sonido.aviso);
      return;
    }
    setState(() => _cargando = true);
    final cuentas = Cuentas.instancia;
    final error = await cuentas.registrar(nombre: _nombre.text, usuario: _usuario.text, clave: _clave.text) ??
        await cuentas.iniciarSesion(_usuario.text, _clave.text);
    if (!mounted) return;
    setState(() {
      _cargando = false;
      _error = error;
    });
    if (error != null) {
      Voz.instancia.decir(error, sonido: Sonido.aviso);
      return;
    }
    Voz.instancia.decir('Cuenta creada.');
    await irAlInicio(context);
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    const estilo = TextStyle(fontSize: 22);
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SafeArea(
        child: Form(
          key: _form,
          child: AutofillGroup(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                TextFormField(
                  controller: _nombre,
                  style: estilo,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  decoration: const InputDecoration(labelText: 'Tu nombre', prefixIcon: Icon(Icons.badge)),
                  validator: (v) => (v ?? '').trim().isEmpty ? 'Escribe tu nombre' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _usuario,
                  style: estilo,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newUsername],
                  decoration: const InputDecoration(
                    labelText: 'Usuario',
                    helperText: 'De 3 a 20 letras sin tilde, números o punto',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (v) => Cuentas.formatoUsuario.hasMatch((v ?? '').trim().toLowerCase())
                      ? null
                      : 'Usa de 3 a 20 letras sin tilde, números o punto',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _clave,
                  style: estilo,
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: const InputDecoration(labelText: 'Contraseña', prefixIcon: Icon(Icons.lock)),
                  validator: (v) => (v ?? '').length < 4 ? 'Mínimo 4 caracteres' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmar,
                  style: estilo,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _crear(),
                  decoration: const InputDecoration(labelText: 'Repite la contraseña', prefixIcon: Icon(Icons.lock_outline)),
                  validator: (v) => v != _clave.text ? 'Las contraseñas no coinciden' : null,
                ),
                const SizedBox(height: 12),
                Text(
                  'Tu cuenta se guarda solo en este teléfono. La contraseña se guarda cifrada.',
                  style: tema.textTheme.bodyLarge,
                ),
                const SizedBox(height: 12),
                if (_error != null)
                  Semantics(
                    liveRegion: true,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(_error!, style: TextStyle(color: tema.colorScheme.error, fontSize: 20)),
                    ),
                  ),
                FilledButton.icon(
                  onPressed: _cargando ? null : _crear,
                  icon: const Icon(Icons.check),
                  label: const Text('Crear cuenta'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
