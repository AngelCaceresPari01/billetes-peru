import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'ajustes.dart';

/// Sonidos cortos de aviso (`assets/sonidos/<nombre>.wav`).
enum Sonido { detectado, sumado, aviso }

/// Voz con estilo de dictado: ritmo pausado, frases cortas y una pausa entre cada parte.
/// Cada dictado nuevo interrumpe al anterior, así la app nunca habla "atrasada".
class Voz {
  Voz._();
  static final instancia = Voz._();

  final _tts = FlutterTts();
  final _player = AudioPlayer();
  int _turno = 0;

  Future<void> iniciar() async {
    await _tts.awaitSpeakCompletion(true);
    if (Platform.isIOS) {
      // Que hable aunque el iPhone esté en modo silencio
      await _tts.setSharedInstance(true);
      await _tts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [IosTextToSpeechAudioCategoryOptions.duckOthers],
        IosTextToSpeechAudioMode.voicePrompt,
      );
    }
    await aplicarAjustes();
  }

  Future<void> aplicarAjustes() async {
    final a = Ajustes.instancia;
    if (a.vozNombre != null && a.vozLocale != null) {
      await _tts.setVoice({'name': a.vozNombre!, 'locale': a.vozLocale!});
    } else {
      await _elegirIdioma();
    }
    await _tts.setSpeechRate(a.velocidad);
    await _tts.setPitch(a.tono);
    await _tts.setVolume(1.0);
  }

  // Preferencia: español de Perú, luego latinoamericano, luego de España
  Future<void> _elegirIdioma() async {
    for (final idioma in ['es-PE', 'es-US', 'es-419', 'es-MX', 'es-ES']) {
      if (await _tts.isLanguageAvailable(idioma) == true) {
        await _tts.setLanguage(idioma);
        return;
      }
    }
  }

  /// Voces en español instaladas en el teléfono, para elegir en Ajustes.
  Future<List<Map<String, String>>> vocesEnEspanol() async {
    final voces = await _tts.getVoices;
    if (voces is! List) return [];
    return voces
        .whereType<Map>()
        .map((v) => {'name': '${v['name']}', 'locale': '${v['locale']}'})
        .where((v) => v['locale']!.toLowerCase().startsWith('es'))
        .toList()
      ..sort((a, b) => '${a['locale']} ${a['name']}'.compareTo('${b['locale']} ${b['name']}'));
  }

  /// Dicta por partes, p. ej. ['Billete de veinte soles.', 'Total: setenta soles.'].
  Future<void> dictar(List<String> partes, {Sonido? sonido, bool vibrar = false}) async {
    final turno = ++_turno;
    final a = Ajustes.instancia;
    await _tts.stop();
    if (vibrar && a.vibracion) HapticFeedback.heavyImpact();
    if (sonido != null && a.sonidos) {
      await _player.stop();
      await _player.play(AssetSource('sonidos/${sonido.name}.wav'));
      await Future.delayed(const Duration(milliseconds: 280));
    }
    final bloques = a.estiloDictado ? partes : [partes.join(' ')];
    for (final b in bloques) {
      if (turno != _turno) return;
      await _tts.speak(b);
      if (a.estiloDictado && turno == _turno) await Future.delayed(Duration(milliseconds: a.pausaMs));
    }
  }

  Future<void> decir(String texto, {Sonido? sonido}) => dictar([texto], sonido: sonido);

  Future<void> callar() async {
    _turno++;
    await _tts.stop();
  }
}
