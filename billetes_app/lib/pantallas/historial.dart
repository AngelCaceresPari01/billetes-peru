import 'package:flutter/material.dart';

import '../datos/denominaciones.dart';
import '../datos/montos.dart';
import '../servicios/historial.dart';
import '../servicios/voz.dart';
import '../widgets/boton_grande.dart';

String _dosDigitos(int n) => n.toString().padLeft(2, '0');
String _fecha(DateTime f) => '${_dosDigitos(f.day)}/${_dosDigitos(f.month)} ${_dosDigitos(f.hour)}:${_dosDigitos(f.minute)}';
String _hora(DateTime f) => '${_dosDigitos(f.hour)}:${_dosDigitos(f.minute)}';

class PantallaHistorial extends StatelessWidget {
  const PantallaHistorial({super.key});

  void _leerUltimos() {
    final regs = Historial.instancia.registros.take(5).toList();
    if (regs.isEmpty) {
      Voz.instancia.decir('El historial está vacío.');
      return;
    }
    Voz.instancia.dictar([
      'Últimos ${regs.length == 1 ? 'registro' : '${numeroEnPalabras(regs.length)} registros'}.',
      for (final r in regs) '${fraseDe(r.etiqueta)}, a las ${_hora(r.fecha)}.',
    ]);
  }

  Future<void> _borrar(BuildContext context) async {
    Voz.instancia.decir('¿Borrar todo el historial?');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Borrar todo el historial?'),
        content: const Text('No se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Borrar')),
        ],
      ),
    );
    if (ok != true) return;
    await Historial.instancia.borrar();
    Voz.instancia.decir('Historial borrado.');
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Historial')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Historial.instancia,
          builder: (context, _) {
            final regs = Historial.instancia.registros;
            final hoy = Historial.instancia.deHoy;
            final sumadoHoy = hoy
                .where((r) => r.modo == 'sumador')
                .fold<int>(0, (s, r) => s + (denominaciones[r.etiqueta]?.centimos ?? 0));
            return Column(
              children: [
                Semantics(
                  label: 'Hoy: ${hoy.length} billetes reconocidos. Sumado hoy: ${montoEnPalabras(sumadoHoy)}.',
                  excludeSemantics: true,
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: tema.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text('Hoy: ${hoy.length} reconocidos', style: tema.textTheme.titleLarge),
                        Text('Sumado hoy: ${formatoSoles(sumadoHoy)}',
                            style: tema.textTheme.titleLarge?.copyWith(color: tema.colorScheme.primary)),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: regs.isEmpty
                      ? Center(child: Text('Todavía no hay registros.', style: tema.textTheme.titleLarge))
                      : ListView.separated(
                          itemCount: regs.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final r = regs[i];
                            final d = denominaciones[r.etiqueta];
                            final modo = r.modo == 'sumador' ? 'Sumador' : 'Reconocer';
                            return Semantics(
                              label: '${fraseDe(r.etiqueta)}. ${_fecha(r.fecha)}. $modo.',
                              excludeSemantics: true,
                              child: ListTile(
                                leading: Icon(r.modo == 'sumador' ? Icons.calculate : Icons.camera_alt, size: 32),
                                title: Text(d?.corto ?? r.etiqueta, style: tema.textTheme.headlineSmall),
                                subtitle: Text(
                                  '${_fecha(r.fecha)} · $modo · ${(r.confianza * 100).round()} %',
                                  style: tema.textTheme.bodyLarge,
                                ),
                              ),
                            );
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: BotonGrande(
                          icono: Icons.record_voice_over,
                          texto: 'Leer últimos',
                          confirmar: false,
                          alPresionar: _leerUltimos,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: BotonGrande(
                          icono: Icons.delete_forever,
                          texto: 'Borrar todo',
                          descripcion: 'Borra todo el historial.',
                          peligro: true,
                          alPresionar: () => _borrar(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
