import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Registro {
  const Registro({required this.fecha, required this.etiqueta, required this.confianza, required this.modo});

  final DateTime fecha;
  final String etiqueta;
  final double confianza;
  final String modo; // 'reconocer' o 'sumador'

  Map<String, dynamic> toJson() =>
      {'f': fecha.millisecondsSinceEpoch, 'e': etiqueta, 'c': confianza, 'm': modo};

  factory Registro.fromJson(Map<String, dynamic> j) => Registro(
        fecha: DateTime.fromMillisecondsSinceEpoch(j['f'] as int),
        etiqueta: j['e'] as String,
        confianza: (j['c'] as num).toDouble(),
        modo: j['m'] as String,
      );
}

/// Historial de billetes reconocidos, separado por usuario.
class Historial extends ChangeNotifier {
  Historial._();
  static final instancia = Historial._();
  static const maximo = 300;

  String _clave = 'historial__invitado';
  List<Registro> registros = []; // el más reciente primero

  Future<void> cargar(String usuario) async {
    _clave = 'historial_$usuario';
    final p = await SharedPreferences.getInstance();
    final lista = jsonDecode(p.getString(_clave) ?? '[]') as List;
    registros = lista.map((e) => Registro.fromJson(e as Map<String, dynamic>)).toList();
    notifyListeners();
  }

  Future<void> agregar(Registro r) async {
    registros.insert(0, r);
    if (registros.length > maximo) registros.removeRange(maximo, registros.length);
    notifyListeners();
    await _guardar();
  }

  Future<void> borrar() async {
    registros.clear();
    notifyListeners();
    await _guardar();
  }

  List<Registro> get deHoy {
    final h = DateTime.now();
    return registros.where((r) => r.fecha.year == h.year && r.fecha.month == h.month && r.fecha.day == h.day).toList();
  }

  Future<void> _guardar() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_clave, jsonEncode(registros.map((r) => r.toJson()).toList()));
  }
}
