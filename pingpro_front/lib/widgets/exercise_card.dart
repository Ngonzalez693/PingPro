import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/core/text_styles.dart';

class ExerciseCard extends StatelessWidget {
  final Exercise exercise;
  final VoidCallback onFavoritePressed;
  final VoidCallback onViewPressed;
  final bool showTopDivider;

  const ExerciseCard({
    super.key,
    required this.exercise,
    required this.onFavoritePressed,
    required this.onViewPressed,
    this.showTopDivider = true,
  });

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
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
          child: Row(
            children: [
              // Imagen a la izquierda
              Container(
                width: 56,
                height: 70,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: AssetImage(exercise.imageUrl),
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
                    SizedBox(height: 20),
                    // Categoría
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
                        style: TextStyles.buttons.copyWith(
                          fontSize: 14,
                        ),
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
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.widgetGrayBackground,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: onFavoritePressed,
                      icon: Icon(
                        exercise.isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: exercise.isFavorite ? AppColors.primary : AppColors.primary,
                        size: 22,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                      splashRadius: 24, 
                    ),
                  ),
                  SizedBox(height: 10),
                  // Botón ver
                  GestureDetector(
                    onTap: onViewPressed,
                    child: Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.textGray,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
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

class Exercise {
  final String id;
  final String name;
  final String category;
  final String imageUrl;
  bool isFavorite;

  Exercise({
    required this.id,
    required this.name,
    required this.category,
    required this.imageUrl,
    required this.isFavorite,
  });
}
