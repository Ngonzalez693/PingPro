// lib/screens/pingpro_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/core/text_styles.dart';
import 'package:pingpro_front/widgets/statistics_chart.dart';
import 'package:pingpro_front/widgets/exercise_card.dart';
import 'package:pingpro_front/widgets/summary_icon.dart';
import 'package:pingpro_front/widgets/training_card.dart';
import 'package:pingpro_front/models/exercise_model.dart';
import 'package:pingpro_front/models/training_model.dart';

class PingproProfileScreen extends StatefulWidget {
  const PingproProfileScreen({super.key});

  @override
  State<PingproProfileScreen> createState() => _PingproProfileScreenState();
}

class _PingproProfileScreenState extends State<PingproProfileScreen> {
  // TODO: replace with real data sources
  final List<ExerciseModel> _recentExercises = [];
  final List<TrainingModel> _recentTrainings = [];

  @override
  void initState() {
    super.initState();
    // TODO: load recent exercises and trainings from backend
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName ?? 'Usuario';
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header: avatar, name, settings icon
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: AssetImage(
                      'assets/images/avatar_placeholder.png',
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: TextStyles.title),
                        Text('Ver perfil', style: TextStyles.paragraph),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.settings,
                      color: AppColors.textWhite,
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, '/editProfile');
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Estadísticas
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Estadísticas', style: TextStyles.subTitle),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/stats');
                },
                child: const StatisticsChart(),
              ),
            ),

            const SizedBox(height: 20),

            // Iconos resumen: ejercicios, entrenamientos, creados
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/stats');
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    SummaryIcon(
                      assetPath: 'assets/icons/exercise_unselected.svg',
                      count: 0,
                      label: 'Ejercicios',
                    ),
                    SummaryIcon(
                      assetPath: 'assets/icons/training_unselected.svg',
                      count: 0,
                      label: 'Entrenamientos',
                    ),
                    SummaryIcon(
                      assetPath: 'assets/icons/create_unselected.svg',
                      count: 0,
                      label: 'Creados',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Actividad reciente
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Actividad reciente', style: TextStyles.title),
              ),
            ),

            const SizedBox(height: 16),

            // Últimos ejercicios
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Últimos ejercicios', style: TextStyles.subTitle),
              ),
            ),

            const SizedBox(height: 8),

            if (_recentExercises.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Aún no has hecho ningún ejercicio. ¡Comienza ahora!',
                  style: TextStyles.paragraph,
                ),
              )
            else
              SizedBox(
                height: 100,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: _recentExercises.length.clamp(0, 5),
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) {
                    final ex = _recentExercises[i];
                    return SizedBox(
                      width: 160,
                      child: ExerciseCard(
                        exercise: ex,
                        onFavoritePressed:
                            () =>
                                setState(() => ex.isFavorite = !ex.isFavorite),
                        onViewPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/exerciseDetail',
                            arguments: {
                              'exercise': ex,
                              'returnRoute': '/profile',
                            },
                          );
                        },
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 16),

            // Últimos entrenamientos
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Últimos entrenamientos',
                  style: TextStyles.subTitle,
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (_recentTrainings.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Aún no has realizado ningún entrenamiento. ¡Pruébalos ahora!',
                  style: TextStyles.paragraph,
                ),
              )
            else
              SizedBox(
                height: 140,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: _recentTrainings.length.clamp(0, 3),
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) {
                    final t = _recentTrainings[i];
                    return SizedBox(
                      width: 120,
                      child: TrainingCard(
                        training: t,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/trainingDetail',
                            arguments: t,
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
