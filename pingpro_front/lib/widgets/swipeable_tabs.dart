// Las pestañas principales, que se cambian deslizando de lado.
//
// Lo que se mueve de lado dentro de una pestaña (tarjetas, filtros, los
// formularios de Crear) va primero: una lista gana el gesto y el PageView de
// aquí no lo llega a ver. Por eso, cuando la lista llega a su borde y avisa que
// le sobra movimiento, ese arrastre se le pasa a mano al PageView y continúa
// como un cambio de pestaña. Solo con el dedo encima: un lanzamiento que llega
// solo al borde se queda ahí.
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:pingpro_front/widgets/keep_alive_page.dart';

class SwipeableTabs extends StatefulWidget {
  final int index;
  final ValueChanged<int> onIndexChanged;
  final List<Widget> children;

  const SwipeableTabs({
    super.key,
    required this.index,
    required this.onIndexChanged,
    required this.children,
  });

  @override
  State<SwipeableTabs> createState() => _SwipeableTabsState();
}

class _SwipeableTabsState extends State<SwipeableTabs> {
  late final PageController _pages = PageController(initialPage: widget.index);
  late int _shownIndex;
  // El arrastre pasado al PageView, dónde empezó y hacia qué lado va.
  Drag? _drag;
  double _dragStart = 0;
  double _dragDirection = 0;

  @override
  void initState() {
    super.initState();
    _shownIndex = widget.index;
  }

  @override
  void didUpdateWidget(SwipeableTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index == _shownIndex) return;
    _shownIndex = widget.index;
    _pages.jumpToPage(widget.index);
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    if (index == _shownIndex) return;
    _shownIndex = index;
    // El teclado de un campo de la pestaña anterior taparía la nueva.
    FocusManager.instance.primaryFocus?.unfocus();
    widget.onIndexChanged(index);
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification.depth == 0 || notification.metrics.axis != Axis.horizontal) return false;
    switch (notification) {
      case OverscrollNotification(:final dragDetails?):
        _follow(dragDetails);
      case ScrollUpdateNotification(:final dragDetails?) when _drag != null:
        _follow(dragDetails);
      case ScrollEndNotification(:final dragDetails):
        _drag?.end(dragDetails ?? DragEndDetails(primaryVelocity: 0));
    }
    return false;
  }

  void _follow(DragUpdateDetails details) {
    final position = _pages.position;
    if (_drag == null) {
      _dragStart = position.pixels;
      _dragDirection = -details.primaryDelta!.sign;
      _drag = position.drag(
        DragStartDetails(globalPosition: details.globalPosition),
        () => _drag = null,
      );
    }
    _drag!.update(details);
    // Si el dedo vuelve atrás, la pestaña llega a donde estaba y ahí para: de
    // seguir, se iría hacia la pestaña del otro lado mientras la lista se mueve.
    if ((position.pixels - _dragStart) * _dragDirection < 0) {
      position.jumpTo(_dragStart);
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: PageView(
        controller: _pages,
        // Deja lista la pestaña de al lado, que se ve desde el primer píxel
        // del deslizamiento.
        allowImplicitScrolling: true,
        onPageChanged: _onPageChanged,
        children: [for (final child in widget.children) KeepAlivePage(child: child)],
      ),
    );
  }
}
