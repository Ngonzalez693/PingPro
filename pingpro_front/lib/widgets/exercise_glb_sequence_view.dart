// Reproductor de la secuencia 3D de un ejercicio.
//
// Recibe la lista de GlbStep que arma exercise_to_glb_steps.dart y la reproduce
// en UN SOLO ModelViewer que dura lo que dura la pantalla. Antes se creaba un
// visor nuevo en cada paso (servidor local + WebView + motor de model-viewer +
// descarga del .glb), y eso era lo que hacía lenta la carga.
//
// El WebView se crea una vez y desde Dart se le habla por JavaScript
// (ver _buildBridgeJs):
//   Dart → JS   runJavaScript('ppShow(url, clip, token)')   cambia de paso
//   JS → Dart   canal 'PingPro' con mensajes load/playing/finished/error
//
// Cada clip se reproduce una sola vez y el paso avanza cuando el motor emite
// `finished`, así que ya no hay duraciones puestas a mano. Si el paso siguiente
// está en el mismo archivo solo se cambia de clip (con el fundido automático de
// model-viewer); si está en otro, se cambia `src` dentro del mismo WebView.
//
// Por qué no se usa la prop `animationName` del widget: model_viewer_plus solo
// la lee al generar el HTML inicial (no implementa didUpdateWidget), así que
// cambiarla después no hace nada.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

/// Un paso de la secuencia: qué .glb mostrar y qué clip de ese archivo.
///
/// Hoy todos los pasos comparten `url` (un único .glb con todas las
/// animaciones), así que el visor solo descarga el archivo una vez y cambia de
/// clip.
class GlbStep {
  final String url;
  final String clip;

  const GlbStep({required this.url, required this.clip});

  @override
  bool operator ==(Object other) =>
      other is GlbStep && other.url == url && other.clip == clip;

  @override
  int get hashCode => Object.hash(url, clip);
}

class ExerciseGlbSequenceView extends StatefulWidget {
  final List<GlbStep> steps;
  final bool loop; // al terminar el último paso vuelve al primero
  final void Function(int index)? onStepChange;

  const ExerciseGlbSequenceView({
    super.key,
    required this.steps,
    this.loop = true,
    this.onStepChange,
  });

  @override
  State<ExerciseGlbSequenceView> createState() =>
      _ExerciseGlbSequenceViewState();
}

class _ExerciseGlbSequenceViewState extends State<ExerciseGlbSequenceView> {
  static const _viewerId = 'pp-viewer';
  static const _channel = 'PingPro';

  // Red de seguridad: si el motor no llegara a emitir `finished`, se avanza
  // igual pasado este margen sobre la duración real del clip.
  static const _finishedGrace = Duration(milliseconds: 1500);

  // El `src` del ModelViewer no puede cambiar después de crearlo: el paquete
  // regeneraría el WebView entero. Los cambios de archivo van por JavaScript.
  late final String _initialUrl;
  late final String _bridgeJs;
  Future<void> Function(String javaScript)? _runJs;

  int _index = 0;
  // Sube en cada cambio de paso; los mensajes del visor que traigan otro valor
  // son de un paso anterior y se descartan.
  int _token = 0;
  bool _playing = true;
  bool _ready = false; // el primer modelo cargó y el puente ya responde
  bool _loadingModel = true;
  String? _error;
  Duration _clipDuration = Duration.zero;
  Timer? _fallback;
  // Pasos seguidos cuyo clip no está en el archivo. Si llega a la longitud de
  // la secuencia, ningún paso se puede reproducir y hay que dejar de saltar.
  int _missingInARow = 0;

  GlbStep get _step => widget.steps[_index];

  @override
  void initState() {
    super.initState();
    final first = widget.steps.isEmpty ? null : widget.steps.first;
    _initialUrl = first?.url ?? '';
    _bridgeJs = _buildBridgeJs(initialUrl: _initialUrl, firstClip: first?.clip);
  }

  @override
  void didUpdateWidget(covariant ExerciseGlbSequenceView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (listEquals(oldWidget.steps, widget.steps) || widget.steps.isEmpty) {
      return;
    }
    _index = 0;
    _missingInARow = 0;
    _loadingModel = true;
    _show(widget.steps.first);
  }

  @override
  void dispose() {
    _fallback?.cancel();
    super.dispose();
  }

  /// Script que se inyecta junto al `<model-viewer>`. Es la mitad JavaScript
  /// del puente: recibe órdenes de Dart y le avisa de lo que pasa en el motor.
  ///
  /// Los valores que vienen de Dart se insertan con jsonEncode, que produce
  /// literales JavaScript válidos y escapados.
  static String _buildBridgeJs({
    required String initialUrl,
    required String? firstClip,
  }) {
    return '''
(() => {
  const mv = document.getElementById('$_viewerId');
  const send = (msg) => $_channel.postMessage(JSON.stringify(msg));
  let currentUrl = ${jsonEncode(initialUrl)};
  let wantedClip = ${jsonEncode(firstClip)};
  let token = 0;
  let awaitingFinish = false;

  const playCurrent = async () => {
    const myToken = token;
    const clips = mv.availableAnimations || [];
    if (!clips.includes(wantedClip)) {
      send({ type: 'missing', token: myToken, clip: wantedClip });
      return;
    }
    mv.animationName = wantedClip;
    // Cambiar animationName arranca el clip en bucle infinito en la siguiente
    // actualización del componente. Hay que esperarla antes de pedir una sola
    // repetición, o esa actualización pisaría nuestro play().
    await mv.updateComplete;
    if (myToken !== token) return;
    mv.currentTime = 0;
    mv.play({ repetitions: 1 });
    awaitingFinish = true;
    send({ type: 'playing', token: myToken, clip: wantedClip, duration: mv.duration });
  };

  mv.addEventListener('load', () => {
    send({ type: 'load', token: token, clips: mv.availableAnimations });
    playCurrent();
  });
  mv.addEventListener('finished', () => {
    if (!awaitingFinish) return;
    awaitingFinish = false;
    send({ type: 'finished', token: token });
  });
  mv.addEventListener('error', (e) => {
    const reason = (e.detail && e.detail.type) || 'no se pudo cargar el modelo';
    send({ type: 'error', token: token, message: String(reason) });
  });

  window.ppShow = (url, clip, newToken) => {
    token = newToken;
    wantedClip = clip;
    awaitingFinish = false;
    if (url === currentUrl) {
      playCurrent();
      return;
    }
    currentUrl = url;
    mv.src = url; // el evento 'load' reproducirá el clip cuando termine
  };
  window.ppPause = () => mv.pause();
  window.ppResume = () => mv.play({ repetitions: 1 });
})();
''';
  }

  Future<void> _callJs(String code) async {
    final run = _runJs;
    if (run == null) return;
    try {
      await run(code);
    } on Exception catch (e) {
      if (kDebugMode) debugPrint('PingPro 3D: fallo al ejecutar JS: $e');
    }
  }

  void _onBridgeMessage(String raw) {
    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException catch (e) {
      if (kDebugMode) debugPrint('PingPro 3D: mensaje ilegible del visor: $e');
      return;
    }
    if (decoded is! Map<String, dynamic> || !mounted) return;
    if (decoded['token'] != _token) return;

    switch (decoded['type']) {
      case 'load':
        if (kDebugMode) {
          debugPrint('PingPro 3D: modelo cargado, clips ${decoded['clips']}');
        }
        setState(() {
          _ready = true;
          _loadingModel = false;
        });
      case 'playing':
        _missingInARow = 0;
        final seconds = (decoded['duration'] as num?)?.toDouble() ?? 0;
        _clipDuration = Duration(milliseconds: (seconds * 1000).round());
        setState(() {
          _loadingModel = false;
          _error = null;
        });
        _armFallback();
        if (kDebugMode) {
          debugPrint(
            'PingPro 3D: paso ${_index + 1}/${widget.steps.length} → '
            '${decoded['clip']} (${seconds.toStringAsFixed(2)} s)',
          );
        }
      case 'finished':
        _fallback?.cancel();
        if (_playing) _next();
      case 'missing':
        _onMissingClip(decoded['clip']);
      case 'error':
        _fallback?.cancel();
        setState(() {
          _loadingModel = false;
          _playing = false;
          _error = 'No se pudo cargar la animación';
        });
        if (kDebugMode) {
          debugPrint('PingPro 3D: error del visor: ${decoded['message']}');
        }
    }
  }

  // Un nombre de clip que no está en el .glb es un error de datos (el archivo
  // se resubió sin ese clip), no de red: se avisa y se sigue con el siguiente.
  void _onMissingClip(Object? clip) {
    if (kDebugMode) debugPrint('PingPro 3D: el archivo no trae el clip $clip');
    _missingInARow++;
    if (_missingInARow < widget.steps.length) {
      _next();
      return;
    }
    _fallback?.cancel();
    setState(() {
      _loadingModel = false;
      _playing = false;
      _error = 'No se pudo cargar la animación';
    });
  }

  void _armFallback() {
    _fallback?.cancel();
    if (!_playing) return;
    _fallback = Timer(_clipDuration + _finishedGrace, () {
      if (kDebugMode) {
        debugPrint('PingPro 3D: no llegó `finished`, avanzo por tiempo');
      }
      _next();
    });
  }

  void _show(GlbStep step) {
    _fallback?.cancel();
    _token++;
    _callJs('ppShow(${jsonEncode(step.url)}, ${jsonEncode(step.clip)}, $_token)');
  }

  void _goTo(int index) {
    final changesFile = widget.steps[index].url != _step.url;
    setState(() {
      _index = index;
      _playing = true; // navegar a mano reanuda la reproducción
      _error = null;
      if (changesFile) _loadingModel = true;
    });
    widget.onStepChange?.call(index);
    _show(widget.steps[index]);
  }

  void _next() {
    if (!_ready || widget.steps.isEmpty) return;
    final isLast = _index + 1 >= widget.steps.length;
    if (isLast && !widget.loop) {
      _fallback?.cancel();
      setState(() => _playing = false);
      return;
    }
    _goTo(isLast ? 0 : _index + 1);
  }

  void _prev() {
    if (!_ready || widget.steps.isEmpty) return;
    if (_index == 0) {
      if (widget.loop) _goTo(widget.steps.length - 1);
      return;
    }
    _goTo(_index - 1);
  }

  void _playPause() {
    if (!_ready) return;
    final willPlay = !_playing;
    setState(() => _playing = willPlay);
    if (willPlay) {
      _callJs('ppResume()');
      _armFallback();
    } else {
      _fallback?.cancel();
      _callJs('ppPause()');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.steps.isEmpty) {
      return const Center(
        child: Text('Sin modelos 3D', style: TextStyle(color: Colors.white70)),
      );
    }

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        // El visor ocupa todo el contenedor padre
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox.expand(
            child: ModelViewer(
              id: _viewerId,
              src: _initialUrl,
              autoPlay: false, // la reproducción la controla el puente
              animationCrossfadeDuration: 300,
              cameraControls: true,
              backgroundColor: Colors.transparent,

              // Encuadre calibrado contra el rig de los .glb actuales: si se
              // reexportan los modelos con otro origen, hay que reajustar estos
              // tres valores o el muñeco saldrá fuera de cuadro.
              cameraOrbit: '0deg 70deg 2m',
              cameraTarget: '1m 1m -5.5m',
              fieldOfView: '60deg',
              interactionPrompt: InteractionPrompt.none,

              // Por defecto el paquete imprime el HTML entero en cada carga.
              debugLogging: false,
              relatedJs: _bridgeJs,
              javascriptChannels: {
                JavascriptChannel(
                  _channel,
                  onMessageReceived: (message) =>
                      _onBridgeMessage(message.message),
                ),
              },
              onWebViewCreated: (controller) {
                _runJs = controller.runJavaScript;
              },
            ),
          ),
        ),

        if (_loadingModel) const Center(child: CircularProgressIndicator()),

        if (_error != null)
          Center(
            child: Text(
              _error!,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ),

        // Controles
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                IconButton(
                  onPressed: _prev,
                  icon: const Icon(Icons.skip_previous, color: Colors.white),
                ),
                IconButton(
                  onPressed: _playPause,
                  icon: Icon(
                    _playing
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_fill,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                IconButton(
                  onPressed: _next,
                  icon: const Icon(Icons.skip_next, color: Colors.white),
                ),
                const Spacer(),
                Text(
                  '${_index + 1}/${widget.steps.length}',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
