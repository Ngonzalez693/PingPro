import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/core/text_styles.dart';
import 'package:pingpro_front/widgets/statistics_chart.dart';
import 'package:pingpro_front/widgets/statistics_secundary_cart.dart';
import 'package:pingpro_front/widgets/summary_icon_row.dart';

enum StatType { exercises, trainings, created }

enum StatPeriod { daily, weekly, monthly }

class PingproStatsScreen extends StatefulWidget {
  const PingproStatsScreen({super.key});

  @override
  State<PingproStatsScreen> createState() => _PingproStatsScreenState();
}

class _PingproStatsScreenState extends State<PingproStatsScreen> {
  StatPeriod _period = StatPeriod.weekly;
  StatType _activeType = StatType.exercises;

  void _onPeriodSelected(StatPeriod p) {
    setState(() => _period = p);
  }

  void _onTypeSelected(StatType t) {
    setState(() => _activeType = t);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.textWhite,
                    ),
                    onPressed: () {
                      FocusScope.of(context).unfocus();
                      Navigator.pop(context);
                    },
                  ),

                  const Spacer(),
                  Text('Estadísticas', style: TextStyles.title),
                  const Spacer(),
                  const SizedBox(width: 48), // placeholder for symmetry
                ],
              ),
            ),

            // Period tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildPeriodTab('Diario', StatPeriod.daily),
                  const SizedBox(width: 8),
                  _buildPeriodTab('Semanal', StatPeriod.weekly),
                  const SizedBox(width: 8),
                  _buildPeriodTab('Mensual', StatPeriod.monthly),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Main statistics chart
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: StatisticsChart(),
            ),

            const SizedBox(height: 16),

            // Summary icons
            SummaryIconRow(
              active: _activeType,
              onSelected: _onTypeSelected,
              exercisesCount: 0,
              trainingsCount: 0,
              createdCount: 0,
            ),

            const SizedBox(height: 8),

            // Secondary chart based on selection
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16),
              child: SizedBox(
                height: 200,
                child: StatisticsSecondaryChart(
                  title:
                      _activeType == StatType.exercises
                          ? 'Ejercicios últimos 7 días'
                          : _activeType == StatType.trainings
                          ? 'Entrenamientos últimos 7 días'
                          : 'Creados últimos 7 días',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodTab(String label, StatPeriod p) {
    final selected = _period == p;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onPeriodSelected(p),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.secundary,
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Text(label, style: TextStyles.buttons),
        ),
      ),
    );
  }
}
