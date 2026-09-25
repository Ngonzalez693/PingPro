// Estadísticas en detalle: constancia, reparto por categoría y por
// golpe/rotación (con lo que toca reforzar) y los ejercicios más repetidos y
// descuidados, para el periodo elegido.
//
// Todo el cálculo está en core/stats_breakdown.dart; aquí solo se elige el
// periodo y el aspecto del golpe, y se pinta.
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/core/services/exercises_state.dart';
import 'package:pingpro_front/core/services/stats_state.dart';
import 'package:pingpro_front/core/stats_breakdown.dart';
import 'package:pingpro_front/core/stats_buckets.dart';
import 'package:pingpro_front/core/text_styles.dart';
import 'package:pingpro_front/models/exercise_model.dart';
import 'package:pingpro_front/models/stats_events_model.dart';
import 'package:pingpro_front/widgets/consistency_card.dart';
import 'package:pingpro_front/widgets/count_bars.dart';
import 'package:pingpro_front/widgets/exercise_rank_list.dart';
import 'package:pingpro_front/widgets/labeled_tabs.dart';

class PingproStatsDetailScreen extends StatefulWidget {
  const PingproStatsDetailScreen({super.key});

  @override
  State<PingproStatsDetailScreen> createState() =>
      _PingproStatsDetailScreenState();
}

class _PingproStatsDetailScreenState extends State<PingproStatsDetailScreen> {
  StatPeriod _period = StatPeriod.weekly;
  StrokeAspect _aspect = StrokeAspect.hit;

  @override
  void initState() {
    super.initState();
    StatsState.instance.load();
    ExercisesState.instance.load();
  }

  void _openExercise(ExerciseModel exercise) {
    Navigator.pushNamed(
      context,
      '/exerciseDetail',
      arguments: {'exercise': exercise, 'returnRoute': '/statsDetail'},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: Listenable.merge([
            StatsState.instance,
            ExercisesState.instance,
          ]),
          builder:
              (context, _) => Column(
                children: [
                  _buildHeader(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: LabeledTabs<StatPeriod>(
                      options: statPeriodOptions,
                      selected: _period,
                      onSelected: (period) => setState(() => _period = period),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(child: _buildBody()),
                ],
              ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textWhite),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          Text('Detalle', style: TextStyles.title),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final stats = StatsState.instance;
    if (stats.isLoading && !stats.loadedOnce) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (stats.error != null && !stats.loadedOnce) {
      return Center(
        child: Text(
          'No se pudieron cargar las estadísticas',
          style: TextStyles.paragraph,
        ),
      );
    }
    final inPeriod = eventsInPeriod(stats.events, _period);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        _buildConsistency(stats.events, inPeriod),
        const SizedBox(height: 16),
        CountBars(
          title: 'Por categoría',
          entries: countByCategory(inPeriod.exerciseCompletions),
        ),
        const SizedBox(height: 16),
        _buildStrokes(inPeriod),
        const SizedBox(height: 16),
        ..._buildExerciseLists(inPeriod),
      ],
    );
  }

  Widget _buildConsistency(StatsEvents all, StatsEvents inPeriod) {
    return ConsistencyCard(
      streak: currentStreak(all),
      activeDays: activeDays(inPeriod),
      minutes: minutesTrained(inPeriod),
      perSession: sessionsPerBucket(inPeriod, _period),
      labels: [
        for (final bucket in dateRange(_period)) labelFor(bucket, _period),
      ],
    );
  }

  Widget _buildStrokes(StatsEvents inPeriod) {
    return CountBars(
      title: 'Por golpe',
      entries: countByStroke(inPeriod.exerciseCompletions, _aspect),
      header: LabeledTabs<StrokeAspect>(
        options: const [
          (StrokeAspect.hit, 'Golpe'),
          (StrokeAspect.rotation, 'Rotación'),
        ],
        selected: _aspect,
        onSelected: (aspect) => setState(() => _aspect = aspect),
      ),
    );
  }

  List<Widget> _buildExerciseLists(StatsEvents inPeriod) {
    final exercises = ExercisesState.instance.all;
    return [
      ExerciseRankList(
        title: 'Más repetidos',
        rows: [
          for (final top in topExercises(
            inPeriod.exerciseCompletions,
            exercises,
          ))
            (top.exercise, '×${top.count}'),
        ],
        emptyText: 'Aún no hay repeticiones en este periodo',
        onTap: _openExercise,
      ),
      const SizedBox(height: 16),
      ExerciseRankList(
        title: 'Descuidados',
        rows: [
          for (final neglected in neglectedExercises(exercises))
            (neglected.exercise, neglectLabel(neglected.daysSince)),
        ],
        emptyText: 'No hay ejercicios',
        onTap: _openExercise,
      ),
    ];
  }
}
