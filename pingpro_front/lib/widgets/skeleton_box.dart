// Bloque gris que ocupa el lugar de un contenido mientras carga.
//
// El color solo importa como máscara: dentro de un SkeletonShimmer el
// degradado lo repinta encima.
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';

class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.skeletonBase,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
