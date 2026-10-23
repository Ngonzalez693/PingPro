// Reproductor 3D de la secuencia de un ejercicio, como un vídeo continuo.
//
// Antes de mostrar nada prepara todo lo que se puede probar sin WebView:
//   1. el archivo de animaciones en el teléfono (AnimationFileCache),
//   2. la pista del suelo de cada clip, leída del propio archivo,
//   3. el plan encadenado (dónde empieza cada paso y la zona que cubre).
// Después levanta el servidor local y abre la página del visor
// (assets/viewer/viewer.js), que reproduce el plan. Con ella habla por los
// mensajes de core/viewer/viewer_bridge.dart.
//
// Ninguna espera es eterna: si el archivo no se puede bajar o leer, si el
// servidor o la página fallan, o si la página no empieza a reproducir en
// _startLimit, se ve el aviso con "Reintentar". Un archivo guardado que no se
// puede leer se borra antes, para que el reintento lo vuelva a bajar. Solo si
// ningún golpe del ejercicio está en el archivo se ve un aviso sin reintento:
// volver a bajarlo no lo arreglaría.
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pingpro_front/core/load_errors.dart';
import 'package:pingpro_front/core/mappers/exercise_to_glb_steps.dart';
import 'package:pingpro_front/core/viewer/animation_file_cache.dart';
import 'package:pingpro_front/core/viewer/chain_plan.dart';
import 'package:pingpro_front/core/viewer/glb_floor_tracks.dart';
import 'package:pingpro_front/core/viewer/viewer_bridge.dart';
import 'package:pingpro_front/core/viewer/viewer_server.dart';
import 'package:pingpro_front/widgets/load_error_view.dart';
import 'package:webview_flutter/webview_flutter.dart';

const _animationError = 'No se pudo cargar la animación';

/// Desde que se abre la página hasta que reproduce el primer paso.
const _startLimit = Duration(seconds: 15);

class ExerciseSequenceViewer extends StatefulWidget {
  final List<GlbStep> steps;
  final ValueChanged<int>? onStepChange;
  final Future<File> Function(String url) _obtainFile;
  final Future<void> Function(String url) _evictFile;

  ExerciseSequenceViewer({
    super.key,
    required this.steps,
    this.onStepChange,
    @visibleForTesting Future<File> Function(String url)? obtainFile,
    @visibleForTesting Future<void> Function(String url)? evictFile,
  })  : _obtainFile = obtainFile ?? AnimationFileCache.instance.fileFor,
        _evictFile = evictFile ?? AnimationFileCache.instance.evict;

  @override
  State<ExerciseSequenceViewer> createState() => _ExerciseSequenceViewerState();
}

class _ExerciseSequenceViewerState extends State<ExerciseSequenceViewer> {
  ChainPlan? _plan;
  ViewerServer? _server;
  WebViewController? _controller;
  Timer? _startWatchdog;

  // Antes de que la página empiece el primer paso.
  bool _loading = true;
  bool _playing = true;
  int _index = 0;

  /// Error con "Reintentar".
  String? _retryError;

  /// Error sin reintento: ningún golpe del ejercicio está en el archivo.
  String? _fatalError;

  String get _url => widget.steps.first.url;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  @override
  void dispose() {
    _stopViewer();
    super.dispose();
  }

  void _restart() {
    _stopViewer();
    setState(() {
      _loading = true;
      _playing = true;
      _index = 0;
      _retryError = null;
      _fatalError = null;
    });
    _prepare();
  }

  Future<void> _prepare() async {
    final File file;
    try {
      file = await widget._obtainFile(_url);
    } on Object catch (e) {
      debugPrint('Visor 3D: no se pudo obtener el archivo: $e');
      _fail(loadErrorMessage(e));
      return;
    }
    final ChainPlan plan;
    try {
      plan = await _readPlan(file);
    } on Object catch (e) {
      debugPrint('Visor 3D: archivo ilegible, se borra: $e');
      await _evict();
      _fail(_animationError);
      return;
    }
    if (!plan.playable) {
      if (mounted) setState(() => _fatalError = _animationError);
      return;
    }
    try {
      await _openViewer(plan, file);
    } on Object catch (e) {
      debugPrint('Visor 3D: no se pudo abrir el visor: $e');
      _fail(_animationError);
    }
  }

  Future<ChainPlan> _readPlan(File file) async {
    final tracks = readFloorTracks(await file.readAsBytes());
    return buildChainPlan([for (final s in widget.steps) s.clip], tracks);
  }

  Future<void> _evict() async {
    try {
      await widget._evictFile(_url);
    } on FileSystemException catch (e) {
      debugPrint('Visor 3D: no se pudo borrar el archivo ilegible: $e');
    }
  }

  Future<void> _openViewer(ChainPlan plan, File file) async {
    final server = await ViewerServer.start(loadAsset: rootBundle.load, animationFile: file);
    if (!mounted) {
      await server.close();
      return;
    }
    _server = server;
    final controller = WebViewController();
    await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await controller.setBackgroundColor(Colors.transparent);
    await controller.addJavaScriptChannel(viewerChannel, onMessageReceived: (m) => _onEvent(m.message));
    await controller.setNavigationDelegate(NavigationDelegate(onWebResourceError: _onWebError));
    if (!mounted || _server != server) return;
    setState(() {
      _plan = plan;
      _controller = controller;
    });
    _startWatchdog = Timer(_startLimit, () => _fail(_animationError));
    await controller.loadRequest(server.pageUri);
  }

  void _onWebError(WebResourceError error) {
    debugPrint('Visor 3D: error de la página: ${error.description}');
    if (error.isForMainFrame ?? true) _fail(_animationError);
  }

  void _onEvent(String raw) {
    final event = parseViewerEvent(raw);
    if (!mounted || event == null) return;
    switch (event) {
      case ViewerReady():
        _run(loadCommand(_plan!));
      case ViewerPlaying(:final index):
        _startWatchdog?.cancel();
        setState(() {
          _loading = false;
          _index = index;
        });
        widget.onStepChange?.call(index);
      case ViewerError(:final message):
        debugPrint('Visor 3D: $message');
        _fail(_animationError);
    }
  }

  void _fail(String message) {
    if (!mounted) return;
    _stopViewer();
    setState(() => _retryError = message);
  }

  void _stopViewer() {
    _startWatchdog?.cancel();
    _startWatchdog = null;
    final server = _server;
    _server = null;
    _controller = null;
    if (server != null) unawaited(server.close());
  }

  Future<void> _run(String command) async {
    final controller = _controller;
    if (controller == null) return;
    try {
      await controller.runJavaScript(command);
    } on PlatformException catch (e) {
      debugPrint('Visor 3D: fallo al ejecutar $command: $e');
    }
  }

  void _goTo(int index) {
    final count = widget.steps.length;
    setState(() => _playing = true);
    _run(goToCommand((index + count) % count));
  }

  void _playPause() {
    setState(() => _playing = !_playing);
    _run(_playing ? resumeCommand : pauseCommand);
  }

  @override
  Widget build(BuildContext context) {
    if (_retryError case final message?) {
      return LoadErrorView(message: message, onRetry: _restart);
    }
    if (_fatalError case final message?) {
      return Center(
        child: Text(message, style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
      );
    }
    final controller = _controller;
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        if (controller != null)
          // Eager: el arrastre para girar la cámara es del visor, no de la
          // pantalla que lo contiene.
          WebViewWidget(
            controller: controller,
            gestureRecognizers: {Factory<OneSequenceGestureRecognizer>(EagerGestureRecognizer.new)},
          ),
        if (_loading) const Center(child: CircularProgressIndicator()),
        if (!_loading) _buildControls(),
      ],
    );
  }

  Widget _buildControls() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            IconButton(
              onPressed: () => _goTo(_index - 1),
              icon: const Icon(Icons.skip_previous, color: Colors.white),
            ),
            IconButton(
              onPressed: _playPause,
              icon: Icon(
                _playing ? Icons.pause_circle_filled : Icons.play_circle_fill,
                color: Colors.white,
                size: 28,
              ),
            ),
            IconButton(
              onPressed: () => _goTo(_index + 1),
              icon: const Icon(Icons.skip_next, color: Colors.white),
            ),
            const Spacer(),
            Text('${_index + 1}/${widget.steps.length}', style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
