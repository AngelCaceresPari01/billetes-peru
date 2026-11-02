import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Usuario {
  const Usuario(this.usuario, this.nombre);

  final String usuario;
  final String nombre;

  static const invitado = Usuario('_invitado', 'invitado');
  bool get esInvitado => usuario == invitado.usuario;
}

/// Cuentas locales: viven solo en este teléfono (sin servidor) y la contraseña
/// se guarda como SHA-256 con sal, nunca en texto plano.
class Cuentas extends ChangeNotifier {
  Cuentas._();
  static final instancia = Cuentas._();

  static final formatoUsuario = RegExp(r'^[a-z0-9.]{3,20}$');

  late SharedPreferences _p;
  Usuario? actual;

  Map<String, dynamic> get _usuarios => jsonDecode(_p.getString('usuarios') ?? '{}') as Map<String, dynamic>;

  Future<void> cargar() async {
    _p = await SharedPreferences.getInstance();
    final sesion = _p.getString('sesion');
    if (sesion == Usuario.invitado.usuario) {
      actual = Usuario.invitado;
    } else if (sesion != null && _usuarios[sesion] != null) {
      actual = Usuario(sesion, _usuarios[sesion]['nombre'] as String);
    }
  }

  String _hash(String sal, String clave) => sha256.convert(utf8.encode('$sal:$clave')).toString();

  /// Devuelve un mensaje de error, o null si la cuenta se creó.
  Future<String?> registrar({required String nombre, required String usuario, required String clave}) async {
    final u = usuario.trim().toLowerCase();
    final usuarios = _usuarios;
    if (usuarios.containsKey(u)) return 'Ese usuario ya existe. Elige otro.';
    final sal = base64Url.encode(List.generate(16, (_) => Random.secure().nextInt(256)));
    usuarios[u] = {'nombre': nombre.trim(), 'sal': sal, 'hash': _hash(sal, clave)};
    await _p.setString('usuarios', jsonEncode(usuarios));
    return null;
  }

  /// Devuelve un mensaje de error, o null si entró.
  Future<String?> iniciarSesion(String usuario, String clave, {bool recordar = true}) async {
    final u = usuario.trim().toLowerCase();
    final datos = _usuarios[u];
    if (datos == null || _hash(datos['sal'] as String, clave) != datos['hash']) {
      return 'Usuario o contraseña incorrectos.';
    }
    actual = Usuario(u, datos['nombre'] as String);
    recordar ? await _p.setString('sesion', u) : await _p.remove('sesion');
    notifyListeners();
    return null;
  }

  Future<void> entrarComoInvitado() async {
    actual = Usuario.invitado;
    await _p.setString('sesion', Usuario.invitado.usuario);
    notifyListeners();
  }

  Future<void> cerrarSesion() async {
    actual = null;
    await _p.remove('sesion');
    notifyListeners();
  }
}
