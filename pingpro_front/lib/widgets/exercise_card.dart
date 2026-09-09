// Fila de un ejercicio: imagen, nombre, categoría y botones de favorito y ver.
// Se reutiliza en Home, Ejercicios, Perfil y detalle de entrenamiento.
//
// No toca el store: recibe los callbacks (`onFavoritePressed`, `onViewPressed`)
// para que cada pantalla decida qué hacer y a dónde navegar. Solo pinta.
//
// INCONSISTENCIA: si no le pasan `onViewPressed` navega por su cuenta con
// _navigateToDetail, que fuerza returnRoute '/exercises' aunque la tarjeta esté
// en otra pantalla. Lo limpio sería exigir el callback y borrar ese atajo.
//
// El parámetro `done` se recibe pero no se usa en el layout: hoy la tarjeta no
// muestra de ninguna forma que el ejercicio esté completado.
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/core/text_styles.dart';
import 'package:pingpro_front/models/exercise_model.dart';
import 'package:pingpro_front/screens/pingpro_exercise_detail_screen.dart';

class ExerciseCard extends StatelessWidget {
  final ExerciseModel exercise;
  final VoidCallback onFavoritePressed;
  final VoidCallback? onViewPressed;
  final bool showTopDivider;
  final bool done;

  const ExerciseCard({
    super.key,
    required this.exercise,
    required this.onFavoritePressed,
    this.onViewPressed,
    this.showTopDivider = true,
    this.done = false,
  });

  void _navigateToDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PingproExerciseDetailScreen(
          exercise: exercise,
          returnRoute: '/exercises',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Línea amarilla arriba
        if (showTopDivider)
          Container(
            height: 1,
            width: double.infinity,
            color: AppColors.primary,
          ),
        Container(
          color: AppColors.background,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Imagen a la izquierda
              Container(
                width: 56,
                height: 70,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  // AssetImage, no NetworkImage: `image` guarda una ruta de
                  // asset empaquetada en la app. Si la ruta no existe en
                  // pubspec.yaml, la tarjeta revienta en tiempo de ejecución.
                  image: DecorationImage(
                    image: AssetImage(exercise.image),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              
              // Info central
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: TextStyles.subTitle,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        exercise.category,
                        style: TextStyles.buttons.copyWith(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Botones a la derecha
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Botón favorito
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.widgetGrayBackground,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: onFavoritePressed,
                      icon: Icon(
                        exercise.isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 20,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Botón ver
                  GestureDetector(
                    onTap: onViewPressed ?? () => _navigateToDetail(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.textGray,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Ver',
                        style: TextStyle(
                          color: AppColors.textWhite,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ],
    );
  }
}
