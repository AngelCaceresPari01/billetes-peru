import 'package:flutter/material.dart';

import '../servicios/cuentas.dart';
import '../servicios/voz.dart';
import 'inicio.dart';
import 'registro.dart';

class PantallaLogin extends StatefulWidget {
  const PantallaLogin({super.key});

  @override
  State<PantallaLogin> createState() => _PantallaLoginState();
}

class _PantallaLoginState extends State<PantallaLogin> {
  final _form = GlobalKey<FormState>();
  final _usuario = TextEditingController();
  final _clave = TextEditingController();
  bool _recordar = true;
  bool _verClave = false;
  bool _cargando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    Voz.instancia.dictar([
      'Bienvenido a Billetes Perú.',
      'Inicia sesión, crea una cuenta, o entra como invitado.',
    ]);
  }

  @override
  void dispose() {
    _usuario.dispose();
    _clave.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!_form.currentState!.validate()) {
      Voz.instancia.decir('Completa el usuario y la contraseña.', sonido: Sonido.aviso);
      return;
    }
    setState(() => _cargando = true);
    final error = await Cuentas.instancia.iniciarSesion(_usuario.text, _clave.text, recordar: _recordar);
    if (!mounted) return;
    setState(() {
      _cargando = false;
      _error = error;
    });
    if (error != null) {
      Voz.instancia.decir(error, sonido: Sonido.aviso);
      return;
    }
    await irAlInicio(context);
  }

  Future<void> _invitado() async {
    await Cuentas.instancia.entrarComoInvitado();
    if (mounted) await irAlInicio(context);
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _form,
          child: AutofillGroup(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 12),
                ExcludeSemantics(child: Icon(Icons.payments, size: 88, color: tema.colorScheme.primary)),
                const SizedBox(height: 8),
                Semantics(
                  header: true,
                  child: Text(
                    'Billetes Perú',
                    textAlign: TextAlign.center,
                    style: tema.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold, color: tema.colorScheme.primary),
                  ),
                ),
                const SizedBox(height: 4),
                Text('Reconoce billetes con la cámara y escúchalos en voz alta',
                    textAlign: TextAlign.center, style: tema.textTheme.titleMedium),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _usuario,
                  autofillHints: const [AutofillHints.username],
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(fontSize: 22),
                  decoration: const InputDecoration(labelText: 'Usuario', prefixIcon: Icon(Icons.person)),
                  validator: (v) => (v ?? '').trim().isEmpty ? 'Escribe tu usuario' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _clave,
                  obscureText: !_verClave,
                  autofillHints: const [AutofillHints.password],
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _entrar(),
                  style: const TextStyle(fontSize: 22),
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      tooltip: _verClave ? 'Ocultar contraseña' : 'Mostrar contraseña',
                      icon: Icon(_verClave ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _verClave = !_verClave),
                    ),
                  ),
                  validator: (v) => (v ?? '').isEmpty ? 'Escribe tu contraseña' : null,
                ),
                CheckboxListTile(
                  value: _recordar,
                  onChanged: (v) => setState(() => _recordar = v ?? true),
                  title: const Text('Recordar mi sesión', style: TextStyle(fontSize: 20)),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                if (_error != null)
                  Semantics(
                    liveRegion: true,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(_error!, style: TextStyle(color: tema.colorScheme.error, fontSize: 20)),
                    ),
                  ),
                FilledButton.icon(
                  onPressed: _cargando ? null : _entrar,
                  icon: const Icon(Icons.login),
                  label: const Text('Iniciar sesión'),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PantallaRegistro())),
                  icon: const Icon(Icons.person_add),
                  label: const Text('Crear cuenta'),
                ),
                const SizedBox(height: 16),
                TextButton(onPressed: _invitado, child: const Text('Entrar como invitado')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
