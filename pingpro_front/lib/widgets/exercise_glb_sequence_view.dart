import 'dart:async';
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

class GlbStep {
  final String url;                 // URL del .glb
  final Duration duration;          // duración (aprox. si no tienes exacta)
  final String? animationName;      // si el glb trae varias animaciones
  GlbStep({required this.url, required this.duration, this.animationName});
}

class ExerciseGlbSequenceView extends StatefulWidget {
  final List<GlbStep> steps;
  final bool autoPlay;
  final void Function(int index)? onStepChange;

  const ExerciseGlbSequenceView({
    super.key,
    required this.steps,
    this.autoPlay = true,
    this.onStepChange,
  });

  @override
  State<ExerciseGlbSequenceView> createState() => _ExerciseGlbSequenceViewState();
}

class _ExerciseGlbSequenceViewState extends State<ExerciseGlbSequenceView> {
  int _index = 0;
  bool _playing = true;
  Timer? _timer;

  GlbStep get _step => widget.steps[_index];

  @override
  void initState() {
    super.initState();
    if (widget.steps.isNotEmpty && widget.autoPlay) {
      _scheduleNext();
    }
  }

  @override
  void didUpdateWidget(covariant ExerciseGlbSequenceView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.steps != widget.steps) {
      _timer?.cancel();
      _index = 0;
      _playing = widget.autoPlay;
      if (_playing && widget.steps.isNotEmpty) _scheduleNext();
      setState(() {});
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _scheduleNext() {
    _timer?.cancel();
    _timer = Timer(_step.duration, _next);
  }

  void _next() {
    if (_index + 1 >= widget.steps.length) {
      setState(() => _playing = false);
      _timer?.cancel();
      return;
    }
    setState(() => _index++);
    widget.onStepChange?.call(_index);
    if (_playing) _scheduleNext();
  }

  void _prev() {
    if (_index == 0) return;
    setState(() => _index--);
    widget.onStepChange?.call(_index);
    if (_playing) _scheduleNext();
  }

  void _playPause() {
    setState(() => _playing = !_playing);
    if (_playing) {
      _scheduleNext();
    } else {
      _timer?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.steps.isEmpty) {
      return const Center(child: Text('Sin modelos 3D', style: TextStyle(color: Colors.white70)));
    }

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: ModelViewer(
              key: ValueKey('glb_${_index}_${_step.url}'),
              src: _step.url,
              autoPlay: true,
              cameraControls: true,
              animationName: _step.animationName,
              backgroundColor: Colors.transparent,
            ),
          ),
        ),
        // Controles básicos
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
                    _playing ? Icons.pause_circle_filled : Icons.play_circle_fill,
                    color: Colors.white, size: 28,
                  ),
                ),
                IconButton(
                  onPressed: _next,
                  icon: const Icon(Icons.skip_next, color: Colors.white),
                ),
                const Spacer(),
                Text('${_index + 1}/${widget.steps.length}',
                    style: const TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
