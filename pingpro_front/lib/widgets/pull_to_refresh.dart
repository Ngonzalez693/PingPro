// "Tirar para recargar": desde arriba de una lista, tirar hacia abajo vuelve a
// pedir los datos al servidor.
//
// Hecho a mano en vez de con RefreshIndicator: con ese, si al tirar el dedo
// vuelve hacia arriba sin soltar, el indicador se recoge pero la lista también
// se desplaza a la vez. Aquí, como en el indicador nativo de Android, mientras
// el indicador está fuera el movimiento solo lo recoge; la lista se mueve con
// lo que sobre cuando ya ha desaparecido.
//
// Cómo: PullToRefresh mete por ScrollConfiguration una física (_PullPhysics)
// bajo la de todas las listas de su interior. Esa física se queda con el
// arrastre vertical que corresponde al indicador y deja pasar el resto; al
// terminar el arrastre (ScrollEndNotification) se decide si recargar.
//
// Todas las pantallas pasan por aquí, así que el indicador (está previsto uno
// propio, con la raqueta y la pelota) se cambia solo en este archivo.
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/core/motion.dart';

/// Cuánto hay que tirar (ya con la resistencia aplicada) para recargar.
const double _triggerDistance = 70;
const double _maxDistance = 140;

/// El indicador baja la mitad de lo que baja el dedo, como en Android.
const double _resistance = 0.5;

const double _indicatorSize = 40;

class PullToRefresh extends StatefulWidget {
  /// Para el scroll de `child`: con poco contenido la lista no tiene scroll
  /// propio y, sin esto, el gesto de tirar no llegaría al indicador.
  static const ScrollPhysics physics = AlwaysScrollableScrollPhysics();

  final Future<void> Function() onRefresh;
  final Widget child;

  const PullToRefresh({super.key, required this.onRefresh, required this.child});

  @override
  State<PullToRefresh> createState() => _PullToRefreshState();
}

class _PullToRefreshState extends State<PullToRefresh> with SingleTickerProviderStateMixin {
  late final _PullTracker _tracker = _PullTracker(onDrag: _settle.stop);
  late final AnimationController _settle = AnimationController.unbounded(vsync: this)
    ..addListener(() => _tracker.distance = _settle.value);
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _tracker.addListener(_onDistanceChanged);
  }

  void _onDistanceChanged() => setState(() {});

  @override
  void dispose() {
    _settle.dispose();
    _tracker.dispose();
    super.dispose();
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollEndNotification && notification.metrics.axis == Axis.vertical) {
      _release();
    }
    return false;
  }

  Future<void> _release() async {
    if (_refreshing || _tracker.distance == 0) return;
    if (_tracker.distance < _triggerDistance) {
      await _animateTo(0);
      return;
    }
    setState(() => _refreshing = true);
    _tracker.enabled = false;
    // La carga empieza al soltar; el indicador se coloca mientras tanto.
    final settling = _animateTo(_triggerDistance);
    try {
      await widget.onRefresh();
    } finally {
      await settling;
      if (mounted) {
        await _animateTo(0);
        _tracker.enabled = true;
        if (mounted) setState(() => _refreshing = false);
      }
    }
  }

  Future<void> _animateTo(double target) {
    _settle.value = _tracker.distance;
    return _settle.animateTo(
      target,
      duration: motionDuration(context, const Duration(milliseconds: 200)),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final configuration = ScrollConfiguration.of(context);
    final distance = _tracker.distance;
    return NotificationListener<ScrollNotification>(
      onNotification: _onScrollNotification,
      child: ScrollConfiguration(
        behavior: configuration.copyWith(
          physics: _PullPhysics(_tracker, parent: configuration.getScrollPhysics(context)),
        ),
        child: Stack(
          children: [
            widget.child,
            if (distance > 0 || _refreshing)
              Positioned(
                top: distance - _indicatorSize,
                left: 0,
                right: 0,
                child: Center(
                  child: _Indicator(
                    progress: _refreshing ? null : (distance / _triggerDistance).clamp(0, 1),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Cuánto está fuera el indicador, y el reparto del arrastre entre él y la
/// lista. Lo usa la física en cada movimiento del dedo.
class _PullTracker extends ChangeNotifier {
  final VoidCallback onDrag;

  _PullTracker({required this.onDrag});

  double _distance = 0;
  double get distance => _distance;
  set distance(double value) {
    if (value == _distance) return;
    _distance = value;
    notifyListeners();
  }

  /// Mientras recarga, tirar o volver no mueve el indicador.
  bool enabled = true;

  /// Recibe el desplazamiento del dedo (positivo hacia abajo) y devuelve la
  /// parte que debe mover la lista.
  double take(double offset, {required bool atTop}) {
    if (!enabled) return offset;
    if (offset > 0 && atTop) {
      onDrag();
      distance = (_distance + offset * _resistance).clamp(0, _maxDistance);
      return 0;
    }
    if (offset < 0 && _distance > 0) {
      onDrag();
      final back = -offset * _resistance;
      if (back <= _distance) {
        distance = _distance - back;
        return 0;
      }
      final leftover = (back - _distance) / _resistance;
      distance = 0;
      return -leftover;
    }
    return offset;
  }
}

class _PullPhysics extends ScrollPhysics {
  final _PullTracker tracker;

  const _PullPhysics(this.tracker, {super.parent});

  @override
  _PullPhysics applyTo(ScrollPhysics? ancestor) => _PullPhysics(tracker, parent: buildParent(ancestor));

  // Solo las listas verticales: las horizontales de dentro (tarjetas, banner)
  // siguen como siempre.
  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    if (position.axis != Axis.vertical) return super.applyPhysicsToUserOffset(position, offset);
    final rest = tracker.take(offset, atTop: position.pixels <= position.minScrollExtent);
    return super.applyPhysicsToUserOffset(position, rest);
  }
}

/// Mientras se tira, el círculo se completa según lo que falta para recargar;
/// al recargar gira sin fin.
class _Indicator extends StatelessWidget {
  final double? progress;

  const _Indicator({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _indicatorSize,
      height: _indicatorSize,
      padding: const EdgeInsets.all(10),
      decoration: const BoxDecoration(
        color: AppColors.tab,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: CircularProgressIndicator(
        value: progress,
        strokeWidth: 2.5,
        color: AppColors.primary,
      ),
    );
  }
}
