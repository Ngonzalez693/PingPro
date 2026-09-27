// Silueta de TrainingCard mientras cargan los entrenamientos: bloque de
// imagen arriba y franja del nombre abajo, con las mismas medidas (100 + 40).
import 'package:flutter/material.dart';
import 'package:pingpro_front/widgets/skeleton_box.dart';

class TrainingCardSkeleton extends StatelessWidget {
  const TrainingCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SkeletonBox(width: double.infinity, height: 98, radius: 0),
          SizedBox(height: 2),
          SkeletonBox(width: double.infinity, height: 40, radius: 0),
        ],
      ),
    );
  }
}
