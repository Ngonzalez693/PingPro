// Tarjeta de entrenamiento: imagen arriba, nombre abajo. Se usa en carrusel
// horizontal (Home, Perfil) y en cuadrícula (Entrenamientos).
//
// Como ExerciseCard, es puramente presentacional: la navegación llega por
// `onTap`. La imagen también es un asset local, con la misma limitación.
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/core/text_styles.dart';
import 'package:pingpro_front/models/training_model.dart';

class TrainingCard extends StatelessWidget {
  final TrainingModel training;
  final VoidCallback onTap;

  const TrainingCard({
    super.key,
    required this.training,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.background,
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: Image.asset(
                training.image,      // asume modelo tiene campo `image`
                width: double.infinity,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),
            Container(
              height: 40,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.widgetGrayBackground,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                training.name,       // usa `name` o `type` según tu modelo
                style: TextStyles.aditional,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
