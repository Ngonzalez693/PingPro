// Barras horizontales de un desglose (categorías, golpes o rotaciones) con la
// etiqueta "a reforzar". Son widgets simples y no fl_chart: con etiquetas
// largas ("Side Spin Izquierda") una gráfica de barras horizontal de fl_chart
// no deja sitio al texto.
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/core/stats_breakdown.dart';
import 'package:pingpro_front/core/text_styles.dart';

class CountBars extends StatelessWidget {
  final String title;
  final List<CountEntry> entries;
  final Widget? header;

  const CountBars({super.key, required this.title, required this.entries, this.header});

  @override
  Widget build(BuildContext context) {
    final max = entries.fold(0, (m, e) => e.count > m ? e.count : m);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.widgetGrayBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyles.subTitleBlack),
          if (header != null) ...[const SizedBox(height: 8), header!],
          const SizedBox(height: 8),
          for (final entry in entries) _buildRow(entry, max),
        ],
      ),
    );
  }

  Widget _buildRow(CountEntry entry, int max) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(entry.label, style: TextStyles.aditional)),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: max == 0 ? 0 : entry.count / max,
                minHeight: 10,
                backgroundColor: AppColors.secundary,
                color: AppColors.primary,
              ),
            ),
          ),
          SizedBox(
            width: 32,
            child: Text('${entry.count}', style: TextStyles.aditional, textAlign: TextAlign.right),
          ),
          SizedBox(
            width: 72,
            child: entry.reinforce
                ? Text(
                    'a reforzar',
                    style: TextStyles.aditional.copyWith(color: AppColors.accent),
                    textAlign: TextAlign.right,
                  )
                : null,
          ),
        ],
      ),
    );
  }
}
