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
import 'package:pingpro_front/core/app_theme.dart';
import 'package:pingpro_front/models/exercise_model.dart';
import 'package:pingpro_front/screens/pingpro_exercise_detail_screen.dart';
import 'package:pingpro_front/widgets/favorite_icon.dart';
import 'package:pingpro_front/widgets/pressable_scale.dart';

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
            color: context.colors.brand,
          ),
        Container(
          color: context.colors.page,
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
                      style: context.text.subTitle,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: context.colors.brandFill,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        exercise.category,
                        style: context.text.buttons.copyWith(fontSize: 14),
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
                      color: context.colors.card,
                      shape: BoxShape.circle,
                      border: surfaceOutline(context.colors),
                    ),
                    child: IconButton(
                      onPressed: onFavoritePressed,
                      icon: FavoriteIcon(
                        isFavorite: exercise.isFavorite,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 20,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Botón ver
                  PressableScale(
                    child: GestureDetector(
                      onTap: onViewPressed ?? () => _navigateToDetail(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: context.colors.pillFill,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Ver',
                          style: TextStyle(
                            color: context.colors.onPill,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
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
