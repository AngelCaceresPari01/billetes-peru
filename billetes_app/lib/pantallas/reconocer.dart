import 'package:flutter/material.dart';

import '../datos/denominaciones.dart';
import '../servicios/historial.dart';
import '../servicios/voz.dart';
import '../widgets/boton_grande.dart';
import '../widgets/detector_camara.dart';

class PantallaReconocer extends StatefulWidget {
  const PantallaReconocer({super.key});

  @override
  State<PantallaReconocer> createState() => _PantallaReconocerState();
}

class _PantallaReconocerState extends State<PantallaReconocer> {
  final _detector = GlobalKey<DetectorCamaraState>();
  String? _ultima;

  @override
  void initState() {
    super.initState();
    Voz.instancia.dictar([
      'Modo reconocer.',
      'Apunta la cámara al billete, a unos veinte centímetros.',
      'Toca la pantalla para repetir el último valor.',
    ]);
  }

  void _alDetectar(String etiqueta, double confianza) {
    _ultima = etiqueta;
    Voz.instancia.dictar(['${fraseDe(etiqueta)}.'], sonido: Sonido.detectado, vibrar: true);
    if (denominaciones.containsKey(etiqueta)) {
      Historial.instancia.agregar(
        Registro(fecha: DateTime.now(), etiqueta: etiqueta, confianza: confianza, modo: 'reconocer'),
      );
    }
  }

  void _noVeNada() {
    Voz.instancia.dictar([
      'No reconozco ningún billete.',
      'Acércalo a la cámara, sin taparlo con los dedos, y busca buena luz.',
    ], sonido: Sonido.aviso);
  }

  void _repetir() {
    final u = _ultima;
    Voz.instancia.decir(u == null ? 'Todavía no reconocí ningún billete.' : '${fraseDe(u)}.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reconocer')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Semantics(
                button: true,
                label: 'Cámara. Toca para repetir el último valor.',
                onTap: _repetir,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _repetir,
                  child: DetectorCamara(key: _detector, alDetectar: _alDetectar, alNoVerNada: _noVeNada),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: BotonGrande(
                      icono: Icons.replay,
                      texto: 'Repetir',
                      confirmar: false,
                      alPresionar: _repetir,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: BotonGrande(
                      icono: Icons.flashlight_on,
                      texto: 'Linterna',
                      confirmar: false,
                      alPresionar: () => _detector.currentState?.alternarLinterna(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
