// Montos en soles: siempre en céntimos (int) para evitar errores de redondeo.

const _unidades = [
  'cero', 'uno', 'dos', 'tres', 'cuatro', 'cinco', 'seis', 'siete', 'ocho', 'nueve',
  'diez', 'once', 'doce', 'trece', 'catorce', 'quince', 'dieciséis', 'diecisiete', 'dieciocho', 'diecinueve',
  'veinte', 'veintiuno', 'veintidós', 'veintitrés', 'veinticuatro', 'veinticinco', 'veintiséis', 'veintisiete',
  'veintiocho', 'veintinueve',
];
const _decenas = ['', '', '', 'treinta', 'cuarenta', 'cincuenta', 'sesenta', 'setenta', 'ochenta', 'noventa'];
const _centenas = [
  '', 'ciento', 'doscientos', 'trescientos', 'cuatrocientos', 'quinientos', 'seiscientos', 'setecientos',
  'ochocientos', 'novecientos',
];

/// 0..999 en palabras. Con [apocope], "uno" final pasa a "un" (un sol, veintiún soles).
String _hasta999(int n, {bool apocope = false}) {
  if (n == 100) return 'cien';
  final c = n ~/ 100, r = n % 100;
  final partes = <String>[];
  if (c > 0) partes.add(_centenas[c]);
  if (r > 0) {
    var t = r < 30 ? _unidades[r] : (r % 10 == 0 ? _decenas[r ~/ 10] : '${_decenas[r ~/ 10]} y ${_unidades[r % 10]}');
    if (apocope) {
      if (t == 'veintiuno') {
        t = 'veintiún';
      } else if (t.endsWith('uno')) {
        t = '${t.substring(0, t.length - 3)}un';
      }
    }
    partes.add(t);
  }
  return partes.join(' ');
}

/// Número entero en palabras (hasta 999 999).
String numeroEnPalabras(int n, {bool apocope = false}) {
  if (n == 0) return 'cero';
  if (n < 1000) return _hasta999(n, apocope: apocope);
  if (n < 1000000) {
    final miles = n ~/ 1000, resto = n % 1000;
    final m = miles == 1 ? 'mil' : '${_hasta999(miles, apocope: true)} mil';
    return resto == 0 ? m : '$m ${_hasta999(resto, apocope: apocope)}';
  }
  return '$n';
}

/// 5050 -> "cincuenta soles con cincuenta céntimos"
String montoEnPalabras(int centimos) {
  final soles = centimos ~/ 100, cent = centimos % 100;
  final partes = <String>[
    if (soles > 0) '${numeroEnPalabras(soles, apocope: true)} ${soles == 1 ? 'sol' : 'soles'}',
    if (cent > 0) '${numeroEnPalabras(cent, apocope: true)} ${cent == 1 ? 'céntimo' : 'céntimos'}',
  ];
  return partes.isEmpty ? 'cero soles' : partes.join(' con ');
}

/// 5050 -> "S/ 50.50". Sin [decimales], los montos exactos quedan como "S/ 50".
String formatoSoles(int centimos, {bool decimales = true}) {
  final soles = centimos ~/ 100, cent = centimos % 100;
  if (!decimales && cent == 0) return 'S/ $soles';
  return 'S/ $soles.${cent.toString().padLeft(2, '0')}';
}

/// "12,50" o "12.5" -> 1250 céntimos. Devuelve null si no es un monto válido.
int? leerMonto(String texto) {
  final v = double.tryParse(texto.trim().replaceAll(',', '.'));
  if (v == null || v <= 0 || v > 999999) return null;
  return (v * 100).round();
}
