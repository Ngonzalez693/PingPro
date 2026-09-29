// Achica un poco a su hijo mientras se mantiene presionado y lo devuelve con
// un pequeño rebote al soltar.
//
// Usa un Listener y no un GestureDetector para no competir con el onPressed
// del botón que envuelve: solo observa el dedo, no se queda con el toque.
import 'package:flutter/material.dart';

class PressableScale extends StatefulWidget {
  final Widget child;

  const PressableScale({super.key, required this.child});

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1,
        duration: const Duration(milliseconds: 150),
        curve: _pressed ? Curves.easeOut : Curves.easeOutBack,
        child: widget.child,
      ),
    );
  }
}
