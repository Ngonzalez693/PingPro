// Brillo que recorre en bucle los SkeletonBox que tenga debajo.
//
// Un solo AnimationController por grupo de skeletons: así todas las cajas
// brillan sincronizadas, como si fueran una sola superficie.
// Con animaciones reducidas no brilla: queda el gris de las cajas.
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';

class SkeletonShimmer extends StatefulWidget {
  final Widget child;

  const SkeletonShimmer({super.key, required this.child});

  @override
  State<SkeletonShimmer> createState() => _SkeletonShimmerState();
}

class _SkeletonShimmerState extends State<SkeletonShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  // Con animaciones reducidas el skeleton queda gris y quieto. Se decide aquí
  // y no en initState para reaccionar si el ajuste cambia con él a la vista.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      // Las cajas ya son grises (SkeletonBox): sin el degradado no hay brillo.
      return Semantics(label: 'Cargando', child: widget.child);
    }
    return Semantics(
      label: 'Cargando',
      child: AnimatedBuilder(
        animation: _controller,
        child: widget.child,
        builder: (context, child) {
          return ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (bounds) => _gradientAt(_controller.value)
                .createShader(bounds),
            child: child,
          );
        },
      ),
    );
  }

  // La franja clara entra por la izquierda y sale por la derecha: los stops
  // van de -1 a 2 para que empiece y termine fuera de la caja.
  LinearGradient _gradientAt(double t) {
    final center = -1 + 3 * t;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: const [
        AppColors.skeletonBase,
        AppColors.skeletonHighlight,
        AppColors.skeletonBase,
      ],
      stops: [center - 0.3, center, center + 0.3],
      tileMode: TileMode.clamp,
    );
  }
}
