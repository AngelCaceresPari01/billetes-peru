import 'montos.dart';

/// Un billete o moneda que el modelo puede reconocer (nombre = línea de labels.txt).
class Denominacion {
  const Denominacion(this.etiqueta, this.centimos, {this.esMoneda = false});

  final String etiqueta;
  final int centimos;
  final bool esMoneda;

  String get tipo => esMoneda ? 'Moneda' : 'Billete';

  /// "Billete de cincuenta soles"
  String get hablado => '$tipo de ${montoEnPalabras(centimos)}';

  /// "S/ 50" o "S/ 0.50"
  String get corto => formatoSoles(centimos, decimales: esMoneda);
}

/// Todas las clases previstas. El modelo v1 solo trae b10, b20, b50 y b100;
/// las demás se activan solas cuando aparezcan en labels.txt.
const denominaciones = <String, Denominacion>{
  'b10': Denominacion('b10', 1000),
  'b20': Denominacion('b20', 2000),
  'b50': Denominacion('b50', 5000),
  'b100': Denominacion('b100', 10000),
  'b200': Denominacion('b200', 20000),
  'm010': Denominacion('m010', 10, esMoneda: true),
  'm020': Denominacion('m020', 20, esMoneda: true),
  'm050': Denominacion('m050', 50, esMoneda: true),
  'm1': Denominacion('m1', 100, esMoneda: true),
  'm2': Denominacion('m2', 200, esMoneda: true),
  'm5': Denominacion('m5', 500, esMoneda: true),
};

/// Clases que no son dinero pero merecen un aviso hablado. 'fondo' no está: ahí la app calla.
const avisos = <String, String>{
  'moneda_escudo': 'Es una moneda. Dale la vuelta para saber su valor.',
};

bool esAnunciable(String etiqueta) => denominaciones.containsKey(etiqueta) || avisos.containsKey(etiqueta);

String fraseDe(String etiqueta) => denominaciones[etiqueta]?.hablado ?? avisos[etiqueta] ?? etiqueta;
