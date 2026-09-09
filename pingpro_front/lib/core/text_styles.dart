/// Tipografías de la app, emparejadas con AppColors.
///
/// Cada estilo viene en dos versiones (`title` / `titleBlack`) porque la app
/// alterna fondo negro y tarjetas claras, y el color del texto tiene que
/// invertirse en cada caso.
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';

class TextStyles {
  static const title = TextStyle(
    color: AppColors.textWhite,
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  static const titleBlack = TextStyle(
    color: AppColors.textBlack,
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  static const subTitle = TextStyle(
    color: AppColors.textWhite,
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );

  static const subTitleBlack = TextStyle(
    color: AppColors.textBlack,
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );

  static const buttons = TextStyle(
    color: AppColors.textBlack,
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );

  static const paragraph = TextStyle(color: AppColors.textWhite, fontSize: 16);

  static const paragraphBlack = TextStyle(color: AppColors.textBlack, fontSize: 16);

  static const aditional = TextStyle(color: AppColors.textBlack, fontSize: 14);

  static const loginRegister = TextStyle(
    color: AppColors.secundary,
    fontWeight: FontWeight.bold,
  );
}
