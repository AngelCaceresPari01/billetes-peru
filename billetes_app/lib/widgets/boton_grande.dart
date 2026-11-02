import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../servicios/ajustes.dart';
import '../servicios/voz.dart';

/// Botón grande y accesible.
///
/// Sin lector de pantalla y con [confirmar]: el primer toque dice qué hace el botón
/// y el segundo (dentro de 3 s) lo activa. Con TalkBack/VoiceOver activo se usa el
/// gesto normal del lector, que ya anuncia el botón.
class BotonGrande extends StatefulWidget {
  const BotonGrande({
    super.key,
    required this.icono,
    required this.texto,
    required this.alPresionar,
    this.descripcion,
    this.confirmar = true,
    this.peligro = false,
  });

  final IconData icono;
  final String texto;
  final String? descripcion;
  final VoidCallback alPresionar;
  final bool confirmar;
  final bool peligro;

  @override
  State<BotonGrande> createState() => _BotonGrandeState();
}

class _BotonGrandeState extends State<BotonGrande> {
  static String? _pendiente;
  static DateTime _cuando = DateTime(2000);

  void _tocar() {
    final lector = MediaQuery.accessibleNavigationOf(context);
    if (!widget.confirmar || lector || !Ajustes.instancia.dobleToque) {
      HapticFeedback.selectionClick();
      widget.alPresionar();
      return;
    }
    final ahora = DateTime.now();
    if (_pendiente == widget.texto && ahora.difference(_cuando).inSeconds < 3) {
      _pendiente = null;
      HapticFeedback.mediumImpact();
      widget.alPresionar();
    } else {
      _pendiente = widget.texto;
      _cuando = ahora;
      HapticFeedback.selectionClick();
      Voz.instancia.dictar([
        '${widget.texto}.',
        if (widget.descripcion != null) widget.descripcion!,
        'Toca otra vez para confirmar.',
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final fondo = widget.peligro ? esquema.error : esquema.primary;
    final texto = widget.peligro ? esquema.onError : esquema.onPrimary;
    return Semantics(
      button: true,
      label: widget.texto,
      hint: widget.descripcion,
      onTap: _tocar,
      excludeSemantics: true,
      child: Material(
        color: fondo,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: _tocar,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 84),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(widget.icono, size: 40, color: texto),
                  const SizedBox(height: 6),
                  Text(
                    widget.texto,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: texto),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
