import 'package:flutter/material.dart';

import '../servicios/ajustes.dart';
import '../servicios/voz.dart';

class PantallaAjustes extends StatefulWidget {
  const PantallaAjustes({super.key});

  @override
  State<PantallaAjustes> createState() => _PantallaAjustesState();
}

class _PantallaAjustesState extends State<PantallaAjustes> {
  final a = Ajustes.instancia;
  late final Future<List<Map<String, String>>> _voces = Voz.instancia.vocesEnEspanol();

  @override
  void initState() {
    super.initState();
    Voz.instancia.decir('Ajustes.');
  }

  Future<void> _guardar({String? anuncio}) async {
    await a.guardar();
    await Voz.instancia.aplicarAjustes();
    if (anuncio != null) Voz.instancia.decir(anuncio);
  }

  void _probar() => Voz.instancia.dictar(
        ['Billete de cincuenta soles.', 'Total: ciento setenta soles.', 'Tu vuelto es tres soles con cincuenta céntimos.'],
        sonido: Sonido.detectado,
      );

  String _ritmo(double v) => v < 0.33 ? 'muy lenta' : (v < 0.45 ? 'pausada' : (v < 0.56 ? 'normal' : 'rápida'));

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    Widget seccion(String t) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Semantics(
            header: true,
            child: Text(t, style: tema.textTheme.titleLarge?.copyWith(color: tema.colorScheme.primary)),
          ),
        );
    Widget interruptor(String titulo, String detalle, bool valor, void Function(bool) cambiar) => SwitchListTile(
          title: Text(titulo, style: const TextStyle(fontSize: 20)),
          subtitle: Text(detalle, style: const TextStyle(fontSize: 16)),
          value: valor,
          onChanged: (v) {
            setState(() => cambiar(v));
            _guardar(anuncio: '$titulo: ${v ? 'activado' : 'desactivado'}.');
          },
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            seccion('Voz'),
            _Deslizador(
              titulo: 'Velocidad',
              valor: a.velocidad,
              min: 0.25,
              max: 0.7,
              divisiones: 9,
              texto: _ritmo,
              alCambiar: (v) => setState(() => a.velocidad = v),
              alTerminar: (v) => _guardar(anuncio: 'Velocidad ${_ritmo(v)}.'),
            ),
            _Deslizador(
              titulo: 'Tono',
              valor: a.tono,
              min: 0.7,
              max: 1.3,
              divisiones: 6,
              texto: (v) => v < 0.9 ? 'grave' : (v < 1.1 ? 'medio' : 'agudo'),
              alCambiar: (v) => setState(() => a.tono = v),
              alTerminar: (v) => _guardar(anuncio: 'Así suena este tono.'),
            ),
            interruptor('Estilo dictado', 'Habla por partes, con pausas cortas entre frases', a.estiloDictado,
                (v) => a.estiloDictado = v),
            if (a.estiloDictado)
              _Deslizador(
                titulo: 'Pausa entre frases',
                valor: a.pausaMs.toDouble(),
                min: 100,
                max: 900,
                divisiones: 8,
                texto: (v) => '${v.round()} milisegundos',
                alCambiar: (v) => setState(() => a.pausaMs = v.round()),
                alTerminar: (_) => _guardar(anuncio: 'Primera frase. Segunda frase.'),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: FutureBuilder<List<Map<String, String>>>(
                future: _voces,
                builder: (context, snap) {
                  final voces = snap.data ?? [];
                  final actual = voces.any((v) => v['name'] == a.vozNombre) ? a.vozNombre : null;
                  return DropdownButtonFormField<String?>(
                    initialValue: actual,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Voz'),
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('Automática (español)')),
                      for (final v in voces)
                        DropdownMenuItem<String?>(
                          value: v['name'],
                          child: Text('${v['locale']} · ${v['name']}', overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: (nombre) async {
                      final v = voces.where((x) => x['name'] == nombre).firstOrNull;
                      a.vozNombre = v?['name'];
                      a.vozLocale = v?['locale'];
                      await _guardar();
                      _probar();
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: FilledButton.icon(onPressed: _probar, icon: const Icon(Icons.play_arrow), label: const Text('Probar voz')),
            ),
            seccion('Sonidos y vibración'),
            interruptor('Sonidos de aviso', 'Un tono antes de decir cada billete', a.sonidos, (v) => a.sonidos = v),
            interruptor('Vibración', 'Vibra al reconocer o sumar', a.vibracion, (v) => a.vibracion = v),
            seccion('Cámara'),
            interruptor('Linterna automática', 'La enciende sola cuando hay poca luz', a.linternaAuto,
                (v) => a.linternaAuto = v),
            _Deslizador(
              titulo: 'Seguridad para hablar',
              valor: a.umbral,
              min: 0.6,
              max: 0.95,
              divisiones: 7,
              texto: (v) => '${(v * 100).round()} por ciento',
              alCambiar: (v) => setState(() => a.umbral = v),
              alTerminar: (v) => _guardar(anuncio: 'Seguridad ${(v * 100).round()} por ciento.'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Más alto: habla menos veces, pero casi nunca se equivoca. Más bajo: habla más, con más errores.',
                style: tema.textTheme.bodyLarge,
              ),
            ),
            seccion('Uso'),
            interruptor('Confirmar con doble toque', 'Primer toque: escuchar el botón. Segundo toque: activarlo',
                a.dobleToque, (v) => a.dobleToque = v),
            interruptor('Sumar automáticamente', 'En el sumador, suma sin tocar la pantalla', a.sumaAutomatica,
                (v) => a.sumaAutomatica = v),
            Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton.icon(
                onPressed: () async {
                  await a.restaurar();
                  await Voz.instancia.aplicarAjustes();
                  setState(() {});
                  Voz.instancia.decir('Ajustes restaurados.');
                },
                icon: const Icon(Icons.settings_backup_restore),
                label: const Text('Restaurar valores'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Deslizador extends StatelessWidget {
  const _Deslizador({
    required this.titulo,
    required this.valor,
    required this.min,
    required this.max,
    required this.divisiones,
    required this.texto,
    required this.alCambiar,
    required this.alTerminar,
  });

  final String titulo;
  final double valor, min, max;
  final int divisiones;
  final String Function(double) texto;
  final void Function(double) alCambiar;
  final void Function(double) alTerminar;

  @override
  Widget build(BuildContext context) {
    final v = valor.clamp(min, max).toDouble();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(child: Text('$titulo: ${texto(v)}', style: const TextStyle(fontSize: 20))),
          Slider(
            value: v,
            min: min,
            max: max,
            divisions: divisiones,
            label: texto(v),
            semanticFormatterCallback: (x) => '$titulo ${texto(x)}',
            onChanged: alCambiar,
            onChangeEnd: alTerminar,
          ),
        ],
      ),
    );
  }
}
