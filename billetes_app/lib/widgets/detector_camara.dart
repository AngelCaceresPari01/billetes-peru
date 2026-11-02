import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../datos/denominaciones.dart';
import '../servicios/ajustes.dart';
import '../servicios/clasificador.dart';
import '../servicios/voz.dart';

/// Cámara que reconoce billetes de forma continua.
///
/// Solo avisa con [alDetectar] cuando la misma clase sale en 4 de los últimos 5 cuadros
/// con confianza sobre el umbral, y no repite el mismo valor antes de 5 segundos.
class DetectorCamara extends StatefulWidget {
  const DetectorCamara({super.key, required this.alDetectar, this.alNoVerNada});

  final void Function(String etiqueta, double confianza) alDetectar;

  /// Se llama si pasan 8 segundos sin reconocer nada.
  final VoidCallback? alNoVerNada;

  @override
  State<DetectorCamara> createState() => DetectorCamaraState();
}

class DetectorCamaraState extends State<DetectorCamara> with WidgetsBindingObserver {
  CameraController? _cam;
  bool _iniciando = false;
  String? _error;

  bool _ocupado = false;
  DateTime _ultimoCuadro = DateTime(2000);
  final _votos = <String>[];
  String? _ultimaDicha;
  DateTime _ultimaVez = DateTime(2000);
  DateTime _ultimaEstable = DateTime.now();
  DateTime _ultimoAvisoVacio = DateTime.now();
  String? _visible; // lo que muestra la pantalla en grande

  bool _linterna = false;
  bool _avisoLuz = false;
  int _cuadrosOscuros = 0;

  bool get linterna => _linterna;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WakelockPlus.enable();
    _iniciar();
  }

  Future<void> _iniciar() async {
    if (_iniciando) return;
    _iniciando = true;
    try {
      await Clasificador.instancia.cargar();
      final camaras = await availableCameras();
      if (camaras.isEmpty) throw CameraException('SinCamara', 'No hay cámaras');
      final trasera = camaras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => camaras.first,
      );
      final cam = CameraController(
        trasera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.yuv420 : ImageFormatGroup.bgra8888,
      );
      await cam.initialize();
      if (!mounted) {
        await cam.dispose();
        return;
      }
      _cam = cam;
      _linterna = false;
      _ultimaEstable = DateTime.now();
      _ultimoAvisoVacio = DateTime.now();
      await cam.startImageStream(_procesar);
      setState(() {});
    } on CameraException catch (e) {
      _fallar(e.code.startsWith('CameraAccess')
          ? 'No tengo permiso para usar la cámara. Actívalo en los ajustes del teléfono.'
          : 'No pude abrir la cámara.');
    } catch (_) {
      _fallar('No pude cargar el modelo de reconocimiento.');
    } finally {
      _iniciando = false;
    }
  }

  void _fallar(String mensaje) {
    if (!mounted) return;
    setState(() => _error = mensaje);
    Voz.instancia.decir(mensaje, sonido: Sonido.aviso);
  }

  Future<void> _procesar(CameraImage img) async {
    final ahora = DateTime.now();
    if (_ocupado || ahora.difference(_ultimoCuadro).inMilliseconds < 150) return;
    _ocupado = true;
    _ultimoCuadro = ahora;
    try {
      final p = await Clasificador.instancia.clasificar(img);
      if (!mounted || _cam == null) return;
      _revisarLuz(p.brillo);

      final umbral = Ajustes.instancia.umbral;
      _votos.add(p.confianza >= umbral ? p.etiqueta : '-');
      if (_votos.length > 5) _votos.removeAt(0);
      final estable = p.confianza >= umbral &&
          esAnunciable(p.etiqueta) &&
          _votos.where((e) => e == p.etiqueta).length >= 4;

      if (estable) {
        _ultimaEstable = ahora;
        _ultimoAvisoVacio = ahora;
        if (_visible != p.etiqueta) setState(() => _visible = p.etiqueta);
        final repetida = p.etiqueta == _ultimaDicha && ahora.difference(_ultimaVez).inSeconds < 5;
        if (!repetida) {
          _ultimaDicha = p.etiqueta;
          _ultimaVez = ahora;
          widget.alDetectar(p.etiqueta, p.confianza);
        }
      } else {
        if (_visible != null && ahora.difference(_ultimaEstable).inMilliseconds > 1500) {
          setState(() => _visible = null);
        }
        if (ahora.difference(_ultimoAvisoVacio).inSeconds >= 8) {
          _ultimoAvisoVacio = ahora;
          widget.alNoVerNada?.call();
        }
      }
    } catch (_) {
      // Un cuadro fallido no detiene el detector
    } finally {
      _ocupado = false;
    }
  }

  void _revisarLuz(double brillo) {
    if (!Ajustes.instancia.linternaAuto || _linterna || _avisoLuz) return;
    _cuadrosOscuros = brillo < 45 ? _cuadrosOscuros + 1 : 0;
    if (_cuadrosOscuros >= 10) {
      _avisoLuz = true; // solo una vez cada vez que se abre la cámara
      alternarLinterna(anunciar: false);
      Voz.instancia.dictar(['Hay poca luz.', 'Encendí la linterna.'], sonido: Sonido.aviso);
    }
  }

  Future<void> alternarLinterna({bool anunciar = true}) async {
    final cam = _cam;
    if (cam == null) return;
    try {
      _linterna = !_linterna;
      await cam.setFlashMode(_linterna ? FlashMode.torch : FlashMode.off);
      if (anunciar) Voz.instancia.decir(_linterna ? 'Linterna encendida.' : 'Linterna apagada.');
      if (mounted) setState(() {});
    } on CameraException {
      _linterna = false;
      Voz.instancia.decir('Este teléfono no tiene linterna.');
    }
  }

  /// Evita que el mismo valor se vuelva a anunciar enseguida (p. ej. justo después de sumarlo).
  void silenciar(String etiqueta) {
    _ultimaDicha = etiqueta;
    _ultimaVez = DateTime.now();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cam = _cam;
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      if (cam != null) {
        _cam = null;
        cam.dispose();
        if (mounted) setState(() {});
      }
    } else if (state == AppLifecycleState.resumed && _cam == null && _error == null) {
      _iniciar();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    WakelockPlus.disable();
    final cam = _cam;
    _cam = null;
    cam?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!, textAlign: TextAlign.center, style: tema.textTheme.headlineSmall),
        ),
      );
    }
    final cam = _cam;
    if (cam == null || !cam.value.isInitialized || cam.value.previewSize == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final tamano = cam.value.previewSize!;
    final d = _visible == null ? null : denominaciones[_visible];
    return Stack(
      fit: StackFit.expand,
      children: [
        ExcludeSemantics(
          child: ClipRect(
            child: FittedBox(
              fit: BoxFit.cover,
              // previewSize viene en horizontal; la app está fija en vertical
              child: SizedBox(width: tamano.height, height: tamano.width, child: CameraPreview(cam)),
            ),
          ),
        ),
        // Guía: el modelo mira el cuadrado central de la imagen
        Center(
          child: FractionallySizedBox(
            widthFactor: 0.8,
            child: AspectRatio(
              aspectRatio: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: tema.colorScheme.primary, width: 4),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(16)),
            child: Text(
              d?.corto ?? (_visible != null ? fraseDe(_visible!) : 'Buscando…'),
              textAlign: TextAlign.center,
              style: tema.textTheme.displaySmall?.copyWith(
                color: d != null ? tema.colorScheme.primary : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        if (_linterna)
          const Positioned(top: 12, right: 12, child: Icon(Icons.flashlight_on, color: Colors.white, size: 36)),
      ],
    );
  }
}
