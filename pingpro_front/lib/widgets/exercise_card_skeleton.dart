// Silueta de ExerciseCard mientras cargan los ejercicios. Replica sus medidas
// (imagen 56×70, márgenes, botones a la derecha) para que al llegar los datos
// la lista no salte.
import 'package:flutter/material.dart';
import 'package:pingpro_front/widgets/skeleton_box.dart';

class ExerciseCardSkeleton extends StatelessWidget {
  final bool showTopDivider;

  const ExerciseCardSkeleton({super.key, this.showTopDivider = true});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Gris y no amarillo como en la tarjeta: dentro del shimmer cualquier
        // color queda repintado por el degradado.
        if (showTopDivider)
          const SkeletonBox(width: double.infinity, height: 1, radius: 0),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SkeletonBox(width: 56, height: 70, radius: 12),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 140, height: 18),
                    SizedBox(height: 10),
                    SkeletonBox(width: 80, height: 20, radius: 16),
                  ],
                ),
              ),
              Column(
                children: [
                  SkeletonBox(width: 36, height: 36, radius: 18),
                  SizedBox(height: 8),
                  SkeletonBox(width: 44, height: 26, radius: 20),
                ],
              ),
              SizedBox(width: 12),
            ],
          ),
        ),
      ],
    );
  }
}
