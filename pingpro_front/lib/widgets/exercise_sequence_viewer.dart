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
// Si el archivo no se puede bajar se ve el aviso amable con "Reintentar";
// si se baja pero ningún golpe del ejercicio está dentro, un aviso sin más.
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

class ExerciseSequenceViewer extends StatefulWidget {
  final List<GlbStep> steps;
  final ValueChanged<int>? onStepChange;
  final Future<File> Function(String url) _obtainFile;

  ExerciseSequenceViewer({
    super.key,
    required this.steps,
    this.onStepChange,
    @visibleForTesting Future<File> Function(String url)? obtainFile,
  }) : _obtainFile = obtainFile ?? AnimationFileCache.instance.fileFor;

  @override
  State<ExerciseSequenceViewer> createState() => _ExerciseSequenceViewerState();
}

class _ExerciseSequenceViewerState extends State<ExerciseSequenceViewer> {
  ChainPlan? _plan;
  ViewerServer? _server;
  WebViewController? _controller;

  // Antes de que la página empiece el primer paso.
  bool _loading = true;
  bool _playing = true;
  int _index = 0;

  /// Error con "Reintentar" (no se pudo bajar el archivo).
  String? _loadError;

  /// Error sin reintento (el archivo no sirve para este ejercicio).
  String? _fatalError;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  @override
  void dispose() {
    _server?.close();
    super.dispose();
  }

  Future<void> _prepare() async {
    setState(() {
      _loading = true;
      _loadError = null;
      _fatalError = null;
    });
    final File file;
    try {
      file = await widget._obtainFile(widget.steps.first.url);
    } on Object catch (e) {
      debugPrint('Visor 3D: no se pudo obtener el archivo: $e');
      if (mounted) setState(() => _loadError = loadErrorMessage(e));
      return;
    }
    final ChainPlan plan;
    try {
      final tracks = readFloorTracks(await file.readAsBytes());
      plan = buildChainPlan([for (final s in widget.steps) s.clip], tracks);
    } on FormatException catch (e) {
      debugPrint('Visor 3D: archivo ilegible: $e');
      if (mounted) setState(() => _fatalError = _animationError);
      return;
    }
    if (!mounted) return;
    if (!plan.playable) {
      setState(() => _fatalError = _animationError);
      return;
    }
    final server = await ViewerServer.start(loadAsset: rootBundle.load, animationFile: file);
    if (!mounted) {
      await server.close();
      return;
    }
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..addJavaScriptChannel(viewerChannel, onMessageReceived: (m) => _onEvent(m.message))
      ..loadRequest(server.pageUri);
    setState(() {
      _plan = plan;
      _server = server;
      _controller = controller;
    });
  }

  void _onEvent(String raw) {
    final event = parseViewerEvent(raw);
    if (!mounted || event == null) return;
    switch (event) {
      case ViewerReady():
        _run(loadCommand(_plan!));
      case ViewerPlaying(:final index):
        setState(() {
          _loading = false;
          _index = index;
        });
        widget.onStepChange?.call(index);
      case ViewerError(:final message):
        debugPrint('Visor 3D: $message');
        setState(() => _fatalError = _animationError);
    }
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
    if (_loadError case final message?) {
      return LoadErrorView(message: message, onRetry: _prepare);
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
