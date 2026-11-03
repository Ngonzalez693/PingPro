// Constancia del periodo: racha, días activos y minutos, más la gráfica de
// sesiones por cubo.
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_theme.dart';
import 'package:pingpro_front/widgets/sessions_chart.dart';

class ConsistencyCard extends StatelessWidget {
  final int streak;
  final int activeDays;
  final int minutes;
  final Map<int?, List<int>> perSession;
  final List<String> labels;

  const ConsistencyCard({
    super.key,
    required this.streak,
    required this.activeDays,
    required this.minutes,
    required this.perSession,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Constancia', style: context.text.subTitleBlack),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildFigure(context, '$streak', streak == 1 ? 'día de racha' : 'días de racha'),
              _buildFigure(context, '$activeDays', activeDays == 1 ? 'día activo' : 'días activos'),
              _buildFigure(context, '$minutes', 'minutos'),
            ],
          ),
          const SizedBox(height: 16),
          Text('Sesiones', style: context.text.aditional),
          const SizedBox(height: 8),
          SessionsChart(perSession: perSession, labels: labels),
        ],
      ),
    );
  }

  Widget _buildFigure(BuildContext context, String value, String caption) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: context.text.titleBlack),
          Text(caption, style: context.text.aditional, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
