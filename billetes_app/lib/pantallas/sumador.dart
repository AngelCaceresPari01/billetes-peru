import 'package:flutter/material.dart';

import '../datos/denominaciones.dart';
import '../datos/montos.dart';
import '../servicios/ajustes.dart';
import '../servicios/historial.dart';
import '../servicios/voz.dart';
import '../widgets/boton_grande.dart';
import '../widgets/detector_camara.dart';

/// Suma billetes uno por uno. Opcionalmente, con un monto a pagar: dice cuánto falta o el vuelto.
class PantallaSumador extends StatefulWidget {
  const PantallaSumador({super.key});

  @override
  State<PantallaSumador> createState() => _PantallaSumadorState();
}

class _PantallaSumadorState extends State<PantallaSumador> {
  final _detector = GlobalKey<DetectorCamaraState>();
  final _sumados = <Denominacion>[];
  Denominacion? _candidato;
  double _confianzaCandidato = 0;
  int? _meta; // céntimos

  int get _total => _sumados.fold(0, (s, d) => s + d.centimos);

  @override
  void initState() {
    super.initState();
    Voz.instancia.dictar([
      'Sumador de billetes.',
      Ajustes.instancia.sumaAutomatica
          ? 'Muestra los billetes de uno en uno. Se suman solos; retira cada billete después de oírlo.'
          : 'Muestra un billete. Cuando lo diga, toca la pantalla para sumarlo.',
    ]);
  }

  void _alDetectar(String etiqueta, double confianza) {
    final d = denominaciones[etiqueta];
    if (d == null) {
      Voz.instancia.decir(fraseDe(etiqueta), sonido: Sonido.aviso);
      return;
    }
    if (Ajustes.instancia.sumaAutomatica) {
      _sumar(d, confianza);
      return;
    }
    setState(() {
      _candidato = d;
      _confianzaCandidato = confianza;
    });
    Voz.instancia.dictar(['${d.hablado}.', 'Toca para sumarlo.'], sonido: Sonido.detectado, vibrar: true);
  }

  void _tocarPantalla() {
    final d = _candidato;
    if (d == null) {
      Voz.instancia.dictar(['Todavía no hay un billete para sumar.', 'Total: ${montoEnPalabras(_total)}.']);
      return;
    }
    _sumar(d, _confianzaCandidato);
  }

  void _sumar(Denominacion d, double confianza) {
    setState(() {
      _sumados.add(d);
      _candidato = null;
    });
    _detector.currentState?.silenciar(d.etiqueta);
    Historial.instancia.agregar(
      Registro(fecha: DateTime.now(), etiqueta: d.etiqueta, confianza: confianza, modo: 'sumador'),
    );
    Voz.instancia.dictar(
      ['Sumé ${montoEnPalabras(d.centimos)}.', 'Total: ${montoEnPalabras(_total)}.', ..._frasesMeta()],
      sonido: Sonido.sumado,
      vibrar: true,
    );
  }

  List<String> _frasesMeta() {
    final meta = _meta;
    if (meta == null) return [];
    final dif = meta - _total;
    if (dif > 0) return ['Faltan ${montoEnPalabras(dif)}.'];
    if (dif == 0) return ['Monto exacto.'];
    return ['Completaste el monto.', 'Tu vuelto es ${montoEnPalabras(-dif)}.'];
  }

  String _cuantos() {
    final n = _sumados.length;
    return n == 1 ? 'un billete' : '${numeroEnPalabras(n, apocope: true)} billetes';
  }

  void _decirTotal() {
    Voz.instancia.dictar(['Total: ${montoEnPalabras(_total)}.', 'Llevas ${_cuantos()}.', ..._frasesMeta()]);
  }

  void _deshacer() {
    if (_sumados.isEmpty) {
      Voz.instancia.decir('No hay nada que deshacer.', sonido: Sonido.aviso);
      return;
    }
    final d = _sumados.last;
    setState(() => _sumados.removeLast());
    Voz.instancia.dictar(['Quité ${montoEnPalabras(d.centimos)}.', 'Total: ${montoEnPalabras(_total)}.', ..._frasesMeta()]);
  }

  void _reiniciar() {
    setState(() {
      _sumados.clear();
      _candidato = null;
    });
    Voz.instancia.dictar(['Suma reiniciada.', 'Total: cero soles.']);
  }

  Future<void> _pedirMeta() async {
    Voz.instancia.decir('Escribe el monto a pagar, en soles.');
    final res = await showDialog<String>(context: context, builder: (_) => _DialogoMonto(inicial: _meta));
    if (!mounted || res == null) return;
    if (res.isEmpty) {
      setState(() => _meta = null);
      Voz.instancia.decir('Quité el monto a pagar.');
      return;
    }
    final meta = leerMonto(res);
    if (meta == null) {
      Voz.instancia.decir('No entendí el monto. Escríbelo con números, por ejemplo: doce punto cincuenta.', sonido: Sonido.aviso);
      return;
    }
    setState(() => _meta = meta);
    Voz.instancia.dictar(['Monto a pagar: ${montoEnPalabras(meta)}.', ..._frasesMeta()]);
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final meta = _meta;
    final dif = meta == null ? null : meta - _total;
    final detalle = [
      _sumados.length == 1 ? '1 billete' : '${_sumados.length} billetes',
      if (meta != null) 'Pagar ${formatoSoles(meta)}',
      if (dif != null) dif > 0 ? 'Faltan ${formatoSoles(dif)}' : (dif == 0 ? 'Exacto' : 'Vuelto ${formatoSoles(-dif)}'),
    ].join('  ·  ');

    return Scaffold(
      appBar: AppBar(title: const Text('Sumador')),
      body: SafeArea(
        child: Column(
          children: [
            Semantics(
              label: 'Total: ${montoEnPalabras(_total)}. ${_cuantos()}. ${_frasesMeta().join(' ')}',
              excludeSemantics: true,
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: tema.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text('TOTAL', style: tema.textTheme.titleMedium),
                    Text(
                      formatoSoles(_total),
                      style: tema.textTheme.displayMedium?.copyWith(
                        color: tema.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(detalle, textAlign: TextAlign.center, style: tema.textTheme.titleMedium),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Semantics(
                button: true,
                label: _candidato == null ? 'Cámara.' : 'Cámara. Toca para sumar ${_candidato!.hablado}.',
                onTap: _tocarPantalla,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _tocarPantalla,
                  child: DetectorCamara(key: _detector, alDetectar: _alDetectar),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: BotonGrande(
                          icono: Icons.record_voice_over,
                          texto: 'Decir total',
                          confirmar: false,
                          alPresionar: _decirTotal,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: BotonGrande(
                          icono: Icons.point_of_sale,
                          texto: 'Monto a pagar',
                          descripcion: 'Escribe cuánto tienes que pagar y te diré lo que falta o tu vuelto.',
                          alPresionar: _pedirMeta,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: BotonGrande(
                          icono: Icons.undo,
                          texto: 'Deshacer',
                          descripcion: 'Quita el último billete sumado.',
                          alPresionar: _deshacer,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: BotonGrande(
                          icono: Icons.restart_alt,
                          texto: 'Reiniciar',
                          descripcion: 'Borra la suma y empieza de cero.',
                          peligro: true,
                          alPresionar: _reiniciar,
                        ),
                      ),
                    ],
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

class _DialogoMonto extends StatefulWidget {
  const _DialogoMonto({this.inicial});

  final int? inicial;

  @override
  State<_DialogoMonto> createState() => _DialogoMontoState();
}

class _DialogoMontoState extends State<_DialogoMonto> {
  late final _ctrl = TextEditingController(
    text: widget.inicial == null ? '' : (widget.inicial! / 100).toStringAsFixed(2),
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Monto a pagar'),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(fontSize: 28),
        decoration: const InputDecoration(prefixText: 'S/ ', labelText: 'Monto en soles'),
        onSubmitted: (v) => Navigator.pop(context, v),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, ''), child: const Text('Quitar')),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(context, _ctrl.text), child: const Text('Aceptar')),
      ],
    );
  }
}
