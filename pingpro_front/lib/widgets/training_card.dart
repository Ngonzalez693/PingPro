// Tarjeta de entrenamiento: imagen arriba, nombre abajo. Se usa en carrusel
// horizontal (Home, Perfil) y en cuadrícula (Entrenamientos).
//
// Como ExerciseCard, es puramente presentacional: la navegación llega por
// `onTap`. La imagen también es un asset local, con la misma limitación.
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_theme.dart';
import 'package:pingpro_front/models/training_model.dart';
import 'package:pingpro_front/widgets/pressable_scale.dart';

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
    final outline = surfaceOutline(context.colors);
    // El carrusel y la cuadrícula dan más alto que el de la tarjeta: arriba y
    // con su propio alto, el contorno de claro no deja una franja vacía bajo
    // el nombre. El ancho sigue siendo el del hueco.
    return Align(
      alignment: Alignment.topCenter,
      child: PressableScale(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: context.colors.page,
            ),
            // Por delante, para rodear la imagen y la franja del nombre juntas.
            foregroundDecoration: outline == null
                ? null
                : BoxDecoration(border: outline, borderRadius: BorderRadius.circular(16)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                  decoration: BoxDecoration(
                    color: context.colors.card,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    training.name,       // usa `name` o `type` según tu modelo
                    style: context.text.aditional,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
