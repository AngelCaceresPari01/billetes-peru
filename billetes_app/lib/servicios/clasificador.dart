import 'dart:math';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class Prediccion {
  const Prediccion(this.etiqueta, this.confianza, this.brillo);

  final String etiqueta;
  final double confianza;
  final double brillo; // 0-255, para encender la linterna si hay poca luz
}

/// Modelo TFLite entrenado en Colab (assets/modelo). Se carga una sola vez para toda la app.
class Clasificador {
  Clasificador._();
  static final instancia = Clasificador._();
  static const tam = 224;

  late Interpreter _interp;
  late IsolateInterpreter _iso; // la inferencia corre fuera del hilo de la interfaz
  List<String> etiquetas = [];
  Future<void>? _carga;

  Future<void> cargar() => _carga ??= _cargar();

  Future<void> _cargar() async {
    _interp = await Interpreter.fromAsset('assets/modelo/soles.tflite');
    _iso = await IsolateInterpreter.create(address: _interp.address);
    final txt = await rootBundle.loadString('assets/modelo/labels.txt');
    etiquetas = txt.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  Future<Prediccion> clasificar(CameraImage img) async {
    final (entrada, brillo) = _preprocesar(img);
    final salida = List.filled(etiquetas.length, 0.0).reshape([1, etiquetas.length]);
    await _iso.run(entrada.buffer.asUint8List(), salida);
    final probs = (salida[0] as List).cast<double>();
    var mejor = 0;
    for (var i = 1; i < probs.length; i++) {
      if (probs[i] > probs[mejor]) mejor = i;
    }
    return Prediccion(etiquetas[mejor], probs[mejor], brillo);
  }

  // Recorte cuadrado central + redimensionado a 224, convirtiendo a RGB en un solo paso,
  // igual que en el entrenamiento. Píxeles 0-255: el modelo normaliza por dentro.
  (Float32List, double) _preprocesar(CameraImage img) {
    final out = Float32List(tam * tam * 3);
    final lado = min(img.width, img.height);
    final x0 = (img.width - lado) ~/ 2, y0 = (img.height - lado) ~/ 2;
    final escala = lado / tam;
    final esYuv = img.format.group == ImageFormatGroup.yuv420;
    var i = 0;
    var luz = 0.0;
    for (var oy = 0; oy < tam; oy++) {
      final sy = y0 + (oy * escala).toInt();
      for (var ox = 0; ox < tam; ox++) {
        final sx = x0 + (ox * escala).toInt();
        double r, g, b;
        if (esYuv) {
          // Android
          final yv = img.planes[0].bytes[sy * img.planes[0].bytesPerRow + sx].toDouble();
          final uvIdx = (sy >> 1) * img.planes[1].bytesPerRow + (sx >> 1) * (img.planes[1].bytesPerPixel ?? 1);
          final u = img.planes[1].bytes[uvIdx] - 128.0;
          final v = img.planes[2].bytes[uvIdx] - 128.0;
          r = _c(yv + 1.402 * v);
          g = _c(yv - 0.344 * u - 0.714 * v);
          b = _c(yv + 1.772 * u);
          luz += yv;
        } else {
          // iOS, BGRA8888
          final p = img.planes[0];
          final idx = sy * p.bytesPerRow + sx * 4;
          b = p.bytes[idx].toDouble();
          g = p.bytes[idx + 1].toDouble();
          r = p.bytes[idx + 2].toDouble();
          luz += 0.299 * r + 0.587 * g + 0.114 * b;
        }
        out[i++] = r;
        out[i++] = g;
        out[i++] = b;
      }
    }
    return (out, luz / (tam * tam));
  }

  double _c(double x) => x < 0 ? 0 : (x > 255 ? 255 : x);
}
