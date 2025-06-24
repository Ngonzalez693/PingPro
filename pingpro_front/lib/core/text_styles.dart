import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';

class TextStyles {
  static const title = TextStyle(
    color: AppColors.textWhite,
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  static const subTitle = TextStyle(
    color: AppColors.textWhite,
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );

  static const buttons = TextStyle(
    color: AppColors.textBlack,
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );

  static const paragraph = TextStyle(color: AppColors.textWhite, fontSize: 16);

  static const aditional = TextStyle(color: AppColors.textBlack, fontSize: 14);

  static const loginRegister = TextStyle(
    color: AppColors.secundary,
    fontWeight: FontWeight.bold,
  );
}
