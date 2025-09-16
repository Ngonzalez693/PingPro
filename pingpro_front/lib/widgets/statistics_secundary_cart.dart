import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/core/text_styles.dart';

class StatisticsSecondaryChart extends StatelessWidget {
  final String title;

  const StatisticsSecondaryChart({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    // Reutiliza el layout de StatisticsChart pero con título dinámico
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.widgetGrayBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyles.paragraphBlack.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (index) {
                final heights = [0.3, 0.7, 0.4, 0.9, 0.6, 0.8, 0.5];
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 20,
                      height: heights[index] * 100,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ['L', 'M', 'X', 'J', 'V', 'S', 'D'][index],
                      style: TextStyles.paragraphBlack.copyWith(fontSize: 12),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
