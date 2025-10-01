import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/core/services/training_services.dart';
import 'package:pingpro_front/core/text_styles.dart';
import 'package:pingpro_front/core/services/exercises_service.dart';
import 'package:pingpro_front/models/exercise_model.dart';
import 'package:pingpro_front/models/training_model.dart';
import 'package:pingpro_front/screens/pingpro_exercise_detail_screen.dart';
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
  final _trService = TrainingsService();

  late List<ExerciseModel> _allExercises = [];
  late List<TrainingModel> _allTrainings = [];
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      _allExercises = await _exService.fetchAll();
      _allTrainings = await _trService.fetchAll();
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _toggleFavorite(String id) async {
    final i = _allExercises.indexWhere((e) => e.id == id);
    if (i == -1) return;
    final old = _allExercises[i].isFavorite;
    setState(() => _allExercises[i].isFavorite = !old);
    try {
      await _exService.setFavorite(id: id, isFavorite: !old);
    } catch (e) {
      setState(() => _allExercises[i].isFavorite = old);
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error actualizando favorito')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error.isNotEmpty) {
      return Center(child: Text('Error: $_error'));
    }

    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? 'Usuario';

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
              'Bienvenido, $displayName',
              style: TextStyles.paragraph.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const ImageBannerCarousel(),
            const SizedBox(height: 32),

            // Recomendaciones
            Text('Recomendaciones', style: TextStyles.title),
            const SizedBox(height: 12),

            // Entrenamientos
            Text('Entrenamientos', style: TextStyles.paragraph),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _allTrainings.take(4).length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) {
                  final t = _allTrainings.take(4).toList()[i];
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

            const SizedBox(height: 24),

            //Ejercicios
            Text('Ejercicios', style: TextStyles.paragraph),
            const SizedBox(height: 16),
            for (var ex in _allExercises.take(2))
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ExerciseCard(
                  exercise: ex,
                  onFavoritePressed: () => _toggleFavorite(ex.id),
                  onViewPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => PingproExerciseDetailScreen(
                              exercise: ex,
                              returnRoute: '/home',
                            ),
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 24),

            // Estadísticas
            Text('Estadísticas', style: TextStyles.subTitle),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/stats');
              },
              child: const StatisticsChart(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
