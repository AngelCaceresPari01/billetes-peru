import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferencias de la app, guardadas en el teléfono.
class Ajustes extends ChangeNotifier {
  Ajustes._();
  static final instancia = Ajustes._();

  late SharedPreferences _p;

  // Voz estilo dictado: algo más lenta y grave que la normal (0.5 / 1.0), con pausas entre frases
  double velocidad = 0.42;
  double tono = 0.95;
  bool estiloDictado = true;
  int pausaMs = 350;
  String? vozNombre;
  String? vozLocale;

  bool sonidos = true;
  bool vibracion = true;
  bool linternaAuto = true;
  bool dobleToque = true;
  bool sumaAutomatica = false;

  /// Confianza mínima del modelo para decir un valor.
  double umbral = 0.85;

  Future<void> cargar() async {
    _p = await SharedPreferences.getInstance();
    velocidad = _p.getDouble('velocidad') ?? velocidad;
    tono = _p.getDouble('tono') ?? tono;
    estiloDictado = _p.getBool('estiloDictado') ?? estiloDictado;
    pausaMs = _p.getInt('pausaMs') ?? pausaMs;
    vozNombre = _p.getString('vozNombre');
    vozLocale = _p.getString('vozLocale');
    sonidos = _p.getBool('sonidos') ?? sonidos;
    vibracion = _p.getBool('vibracion') ?? vibracion;
    linternaAuto = _p.getBool('linternaAuto') ?? linternaAuto;
    dobleToque = _p.getBool('dobleToque') ?? dobleToque;
    sumaAutomatica = _p.getBool('sumaAutomatica') ?? sumaAutomatica;
    umbral = _p.getDouble('umbral') ?? umbral;
  }

  Future<void> guardar() async {
    await _p.setDouble('velocidad', velocidad);
    await _p.setDouble('tono', tono);
    await _p.setBool('estiloDictado', estiloDictado);
    await _p.setInt('pausaMs', pausaMs);
    vozNombre == null ? await _p.remove('vozNombre') : await _p.setString('vozNombre', vozNombre!);
    vozLocale == null ? await _p.remove('vozLocale') : await _p.setString('vozLocale', vozLocale!);
    await _p.setBool('sonidos', sonidos);
    await _p.setBool('vibracion', vibracion);
    await _p.setBool('linternaAuto', linternaAuto);
    await _p.setBool('dobleToque', dobleToque);
    await _p.setBool('sumaAutomatica', sumaAutomatica);
    await _p.setDouble('umbral', umbral);
    notifyListeners();
  }

  Future<void> restaurar() async {
    velocidad = 0.42;
    tono = 0.95;
    estiloDictado = true;
    pausaMs = 350;
    vozNombre = null;
    vozLocale = null;
    sonidos = true;
    vibracion = true;
    linternaAuto = true;
    dobleToque = true;
    sumaAutomatica = false;
    umbral = 0.85;
    await guardar();
  }
}
