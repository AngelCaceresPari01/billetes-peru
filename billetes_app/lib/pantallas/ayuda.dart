import 'package:flutter/material.dart';

import '../datos/denominaciones.dart';
import '../servicios/clasificador.dart';
import '../servicios/voz.dart';
import '../widgets/boton_grande.dart';

class PantallaAyuda extends StatefulWidget {
  const PantallaAyuda({super.key});

  @override
  State<PantallaAyuda> createState() => _PantallaAyudaState();
}

class _PantallaAyudaState extends State<PantallaAyuda> {
  String _reconoce = '';

  @override
  void initState() {
    super.initState();
    Voz.instancia.decir('Ayuda. Toca Escuchar ayuda para oír las instrucciones.');
    // Lo que reconoce sale del labels.txt del modelo instalado
    Clasificador.instancia.cargar().then((_) {
      final nombres = Clasificador.instancia.etiquetas.where(denominaciones.containsKey).map((e) => denominaciones[e]!.hablado.toLowerCase());
      if (mounted) setState(() => _reconoce = nombres.join(', '));
    }).catchError((_) {});
  }

  List<String> get _parrafos => [
        'Esta aplicación reconoce billetes peruanos con la cámara y te dice su valor en voz alta.',
        'En Reconocer, sostén el billete a unos veinte centímetros, sin taparlo con los dedos. La aplicación habla sola cuando está segura.',
        'Si no está segura, se queda callada. Mueve un poco el billete, dale la vuelta o enciende la linterna.',
        'Toca la cámara o el botón Repetir para volver a escuchar el último valor.',
        'En el Sumador, muestra un billete y toca la pantalla para sumarlo. Con Monto a pagar, te digo cuánto falta o cuánto es tu vuelto.',
        'En el menú, toca un botón una vez para escuchar qué hace, y otra vez para abrirlo. Si usas TalkBack o VoiceOver, funciona con sus gestos normales.',
        if (_reconoce.isNotEmpty) 'Este modelo reconoce: $_reconoce.',
        'Todo funciona sin internet. Tu cuenta y tu historial se guardan solo en este teléfono.',
      ];

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Ayuda')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  for (final p in _parrafos)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(p, style: tema.textTheme.titleLarge),
                    ),
                  Text(
                    'Modelo entrenado con el dataset "Peruvian Banknotes" (Caytuiro-Silva et al., 2023, Mendeley Data, CC BY 4.0). '
                    'No detecta billetes falsos.',
                    style: tema.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: BotonGrande(
                      icono: Icons.volume_up,
                      texto: 'Escuchar ayuda',
                      confirmar: false,
                      alPresionar: () => Voz.instancia.dictar(_parrafos),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: BotonGrande(
                      icono: Icons.stop,
                      texto: 'Detener',
                      confirmar: false,
                      alPresionar: Voz.instancia.callar,
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
