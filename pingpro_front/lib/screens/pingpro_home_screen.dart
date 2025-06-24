import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/core/text_styles.dart';
import 'package:pingpro_front/widgets/custom_bottom_navigation.dart';
import 'package:pingpro_front/widgets/exercise_card.dart';
import 'package:pingpro_front/widgets/image_banner_carousel.dart';
import 'package:pingpro_front/widgets/statistics_chart.dart';
import 'package:pingpro_front/widgets/training_card.dart';

class PingproHomeScreen extends StatefulWidget {
  const PingproHomeScreen({super.key});

  @override
  State<PingproHomeScreen> createState() => _PingproHomeScreenState();
}

class _PingproHomeScreenState extends State<PingproHomeScreen> {
  int _currentTab = 0;
  final String userName = "Juan";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Contenido scrolleable
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20),

                    // Nombre de la aplicación
                    Center(
                      child: Text(
                        'PingPro',
                        style: TextStyles.title.copyWith(
                          fontSize: 28,
                          color: AppColors.primary,
                        ),
                      ),
                    ),

                    SizedBox(height: 16),

                    // Bienvenida
                    Text(
                      'Bienvenido, $userName',
                      style: TextStyles.paragraph.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 20),

                    // Banner carousel
                    ImageBannerCarousel(),

                    SizedBox(height: 32),

                    // Sección Recomendaciones
                    Text('Recomendaciones', style: TextStyles.subTitle),

                    SizedBox(height: 16),

                    // Entrenamientos
                    Text(
                      'Entrenamientos',
                      style: TextStyles.paragraph.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 16),

                    SizedBox(
                      height: 160,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _mockTrainings.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          return TrainingCard(
                            training: _mockTrainings[index],
                            onTap: () {},
                          );
                        },
                      ),
                    ),

                    SizedBox(height: 24),
                    Text(
                      "Ejercicios",
                      style: TextStyles.paragraph.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    // Ejercicios
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _mockExercises.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ExerciseCard(
                            exercise: _mockExercises[index],
                            onFavoritePressed: () {
                              // Lógica para favoritos
                            },
                            onViewPressed: () {
                              // Navegar al detalle del ejercicio
                            },
                          ),
                        );
                      },
                    ),

                    SizedBox(height: 24),

                    // Sección Estadísticas
                    Text('Estadísticas', style: TextStyles.subTitle),

                    SizedBox(height: 16),

                    // Gráfico de estadísticas
                    StatisticsChart(),

                    SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // Bottom Navigation fijo
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: _currentTab,
        onTap: (index) {
          setState(() {
            _currentTab = index;
          });
          // Aquí navegarías a las otras pantallas
        },
      ),
    );
  }
}

// Mock data
final List<Training> _mockTrainings = [
  Training(id: '1', type: 'Regular', imageUrl: 'assets/images/training_1.jpg'),
  Training(
    id: '2',
    type: 'Irregular',
    imageUrl: 'assets/images/training_2.jpg',
  ),
  Training(id: '3', type: 'Técnico', imageUrl: 'assets/images/training_3.jpg'),
];

final List<Exercise> _mockExercises = [
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
