import 'package:billetes_peru/datos/denominaciones.dart';
import 'package:billetes_peru/datos/montos.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('montos en palabras', () {
    expect(montoEnPalabras(0), 'cero soles');
    expect(montoEnPalabras(100), 'un sol');
    expect(montoEnPalabras(1000), 'diez soles');
    expect(montoEnPalabras(2100), 'veintiún soles');
    expect(montoEnPalabras(3100), 'treinta y un soles');
    expect(montoEnPalabras(10000), 'cien soles');
    expect(montoEnPalabras(17000), 'ciento setenta soles');
    expect(montoEnPalabras(20000), 'doscientos soles');
    expect(montoEnPalabras(350), 'tres soles con cincuenta céntimos');
    expect(montoEnPalabras(50), 'cincuenta céntimos');
    expect(montoEnPalabras(101), 'un sol con un céntimo');
    expect(montoEnPalabras(100000), 'mil soles');
    expect(montoEnPalabras(2150000), 'veintiún mil quinientos soles');
  });

  test('formato y lectura de montos', () {
    expect(formatoSoles(5050), 'S/ 50.50');
    expect(formatoSoles(2000, decimales: false), 'S/ 20');
    expect(leerMonto('12,5'), 1250);
    expect(leerMonto('100'), 10000);
    expect(leerMonto('abc'), isNull);
    expect(leerMonto('-3'), isNull);
  });

  test('frases de las denominaciones', () {
    expect(denominaciones['b50']!.hablado, 'Billete de cincuenta soles');
    expect(denominaciones['m050']!.hablado, 'Moneda de cincuenta céntimos');
    expect(fraseDe('moneda_escudo'), startsWith('Es una moneda'));
    expect(esAnunciable('fondo'), isFalse);
  });
}
