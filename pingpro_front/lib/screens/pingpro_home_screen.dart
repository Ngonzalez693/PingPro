import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/core/text_styles.dart';
import 'package:pingpro_front/widgets/exercise_card.dart';
import 'package:pingpro_front/widgets/image_banner_carousel.dart';
import 'package:pingpro_front/widgets/statistics_chart.dart';
import 'package:pingpro_front/widgets/training_card.dart';

class PingproHomeScreen extends StatelessWidget {
  const PingproHomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Center(
              child: Text(
                'PingPro',
                style: TextStyles.title.copyWith(
                  fontSize: 28,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Bienvenido, Juan',
              style: TextStyles.paragraph.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const ImageBannerCarousel(),
            const SizedBox(height: 32),
            Text('Recomendaciones', style: TextStyles.subTitle),
            const SizedBox(height: 16),
            // Entrenamientos horizontales
            SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _mockTrainings.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) => TrainingCard(
                  training: _mockTrainings[i],
                  onTap: () {},
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Ejercicios',
              style: TextStyles.paragraph.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _mockExercises.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ExerciseCard(
                  exercise: _mockExercises[i],
                  onFavoritePressed: () {},
                  onViewPressed: () {},
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Estadísticas', style: TextStyles.subTitle),
            const SizedBox(height: 16),
            const StatisticsChart(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // Mock data
  static final _mockTrainings = [
    Training(id: '1', type: 'Regular', imageUrl: 'assets/images/training_1.jpg'),
    Training(id: '2', type: 'Irregular', imageUrl: 'assets/images/training_2.jpg'),
    Training(id: '3', type: 'Técnico', imageUrl: 'assets/images/training_3.jpg'),
  ];

  static final _mockExercises = [
    Exercise(
      id: '1',
      name: 'Falkenberg',
      category: 'Footwork',
      imageUrl: 'assets/images/exercise_1.jpg',
      isFavorite: false,
    ),
    Exercise(
      id: '2',
      name: 'Tres Puntos',
      category: 'Footwork',
      imageUrl: 'assets/images/exercise_1.jpg',
      isFavorite: true,
    ),
  ];
}
