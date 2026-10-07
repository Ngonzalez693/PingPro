// Corazón de favorito con un "pop" al cambiar de estado. Lo comparten
// ExerciseCard y el detalle del ejercicio.
//
// La key del icono cambia con el estado, así AnimatedSwitcher hace la
// transición al marcar y al desmarcar.
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/core/motion.dart';

class FavoriteIcon extends StatelessWidget {
  final bool isFavorite;
  final double size;

  const FavoriteIcon({super.key, required this.isFavorite, required this.size});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: motionDuration(context, const Duration(milliseconds: 250)),
      switchInCurve: Curves.easeOutBack,
      transitionBuilder: (child, animation) =>
          ScaleTransition(scale: animation, child: child),
      child: Icon(
        isFavorite ? Icons.favorite : Icons.favorite_border,
        key: ValueKey(isFavorite),
        color: AppColors.primary,
        size: size,
      ),
    );
  }
}
