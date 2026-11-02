import 'package:flutter/material.dart';

import '../servicios/cuentas.dart';
import '../servicios/historial.dart';
import '../servicios/voz.dart';
import '../widgets/boton_grande.dart';
import 'ajustes.dart';
import 'ayuda.dart';
import 'historial.dart';
import 'login.dart';
import 'reconocer.dart';
import 'sumador.dart';

/// Carga el historial del usuario que acaba de entrar y abre el menú principal.
Future<void> irAlInicio(BuildContext context) async {
  await Historial.instancia.cargar(Cuentas.instancia.actual!.usuario);
  if (!context.mounted) return;
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const PantallaInicio()),
    (_) => false,
  );
}

class PantallaInicio extends StatefulWidget {
  const PantallaInicio({super.key});

  @override
  State<PantallaInicio> createState() => _PantallaInicioState();
}

class _PantallaInicioState extends State<PantallaInicio> {
  static bool _saludado = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _saludar());
  }

  void _saludar() {
    if (!mounted) return;
    final u = Cuentas.instancia.actual!;
    final lector = MediaQuery.accessibleNavigationOf(context);
    if (_saludado) {
      Voz.instancia.decir('Menú principal.');
      return;
    }
    _saludado = true;
    Voz.instancia.dictar([
      'Hola, ${u.nombre}.',
      'Menú principal.',
      if (!lector) 'Toca un botón para escuchar qué hace. Tócalo otra vez para abrirlo.',
    ]);
  }

  Future<void> _abrir(Widget pantalla) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => pantalla));
    if (mounted) Voz.instancia.decir('Menú principal.');
  }

  Future<void> _cerrarSesion() async {
    await Cuentas.instancia.cerrarSesion();
    _saludado = false;
    Voz.instancia.decir('Sesión cerrada.');
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const PantallaLogin()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final u = Cuentas.instancia.actual!;
    final botones = [
      BotonGrande(
        icono: Icons.camera_alt,
        texto: 'Reconocer',
        descripcion: 'Dice en voz alta el valor del billete que muestres a la cámara.',
        alPresionar: () => _abrir(const PantallaReconocer()),
      ),
      BotonGrande(
        icono: Icons.calculate,
        texto: 'Sumador',
        descripcion: 'Suma varios billetes y te dice el total, lo que falta o tu vuelto.',
        alPresionar: () => _abrir(const PantallaSumador()),
      ),
      BotonGrande(
        icono: Icons.history,
        texto: 'Historial',
        descripcion: 'Los últimos billetes que reconociste.',
        alPresionar: () => _abrir(const PantallaHistorial()),
      ),
      BotonGrande(
        icono: Icons.tune,
        texto: 'Ajustes',
        descripcion: 'Velocidad y tipo de voz, sonidos, vibración y linterna.',
        alPresionar: () => _abrir(const PantallaAjustes()),
      ),
      BotonGrande(
        icono: Icons.help,
        texto: 'Ayuda',
        descripcion: 'Cómo usar la aplicación.',
        alPresionar: () => _abrir(const PantallaAyuda()),
      ),
      BotonGrande(
        icono: Icons.logout,
        texto: u.esInvitado ? 'Salir' : 'Cerrar sesión',
        descripcion: 'Vuelve a la pantalla de inicio de sesión.',
        peligro: true,
        alPresionar: _cerrarSesion,
      ),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(u.esInvitado ? 'Hola' : 'Hola, ${u.nombre}')),
      body: SafeArea(
        child: GridView.count(
          padding: const EdgeInsets.all(16),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.95,
          children: botones,
        ),
      ),
    );
  }
}
