import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'pantallas/inicio.dart';
import 'pantallas/login.dart';
import 'servicios/ajustes.dart';
import 'servicios/clasificador.dart';
import 'servicios/cuentas.dart';
import 'servicios/historial.dart';
import 'servicios/voz.dart';
import 'tema.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Ajustes.instancia.cargar();
  await Cuentas.instancia.cargar();
  final usuario = Cuentas.instancia.actual;
  if (usuario != null) await Historial.instancia.cargar(usuario.usuario);
  try {
    await Voz.instancia.iniciar();
  } catch (_) {
    // Sin motor de voz la app sigue funcionando en pantalla
  }
  // El modelo se carga en segundo plano para que la cámara abra más rápido
  unawaited(Clasificador.instancia.cargar().catchError((Object _) {}));
  runApp(BilletesApp(conSesion: usuario != null));
}

class BilletesApp extends StatelessWidget {
  const BilletesApp({super.key, required this.conSesion});

  final bool conSesion;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Billetes Perú',
      debugShowCheckedModeBanner: false,
      theme: temaAltoContraste(),
      home: conSesion ? const PantallaInicio() : const PantallaLogin(),
    );
  }
}
