import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';

class PlusButton extends StatelessWidget {
  const PlusButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: AppColors.widgetGrayBackground,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.add,
        color: AppColors.textWhite,
        size: 20,
      ),
    );
  }
}
