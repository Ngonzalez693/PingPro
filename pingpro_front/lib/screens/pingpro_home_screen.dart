import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/core/text_styles.dart';
import 'package:pingpro_front/core/services/exercises_service.dart';
import 'package:pingpro_front/models/exercise_model.dart';
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
  final _exService = ExercisesService();
  late List<ExerciseModel> _allExercises;
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    try {
      _allExercises = await _exService.fetchAll();
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? 'Usuario';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 20),
          Center(child: Text('PingPro', style: TextStyles.title.copyWith(fontSize: 28, color: AppColors.primary))),
          const SizedBox(height: 16),
          Text('Bienvenido, $displayName', style: TextStyles.paragraph.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          const ImageBannerCarousel(),
          const SizedBox(height: 32),

          Text('Recomendaciones', style: TextStyles.subTitle),
          const SizedBox(height: 16),

          if (_loading) 
            const Center(child: CircularProgressIndicator())
          else if (_error.isNotEmpty)
            Center(child: Text('Error: $_error'))
          else ...[
            // Mostrar hasta 2 ejercicios en columna
            for (var ex in _allExercises.take(2))
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ExerciseCard(
                  exercise: ex,
                  onFavoritePressed: () => setState(() => ex.isFavorite = !ex.isFavorite),
                  onViewPressed: () {
                    // navegar a detalle con ex.id
                  },
                ),
              ),
          ],

          const SizedBox(height: 24),
          Text('Entrenamientos', style: TextStyles.subTitle),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _mockTrainings.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => TrainingCard(training: _mockTrainings[i], onTap: () {}),
            ),
          ),

          const SizedBox(height: 24),
          Text('Estadísticas', style: TextStyles.subTitle),
          const SizedBox(height: 16),
          const StatisticsChart(),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  static final _mockTrainings = [
    Training(id: '1', type: 'Regular', imageUrl: 'assets/images/training_1.jpg'),
    Training(id: '2', type: 'Irregular', imageUrl: 'assets/images/training_2.jpg'),
    Training(id: '3', type: 'Técnico', imageUrl: 'assets/images/training_3.jpg'),
  ];
}
