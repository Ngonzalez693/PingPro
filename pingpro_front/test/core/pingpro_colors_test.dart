import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/core/pingpro_colors.dart';

const _other = PingProColors(
  page: Color(0xFF123456),
  tabBar: Color(0xFF123456),
  onPage: Color(0xFF123456),
  card: Color(0xFF123456),
  onCard: Color(0xFF123456),
  muted: Color(0xFF123456),
  brand: Color(0xFF123456),
  brandFill: Color(0xFF123456),
  onBrandFill: Color(0xFF123456),
  softFill: Color(0xFF123456),
  softText: Color(0xFF123456),
  skeletonBase: Color(0xFF123456),
  skeletonHighlight: Color(0xFF123456),
  danger: Color(0xFF123456),
);

void main() {
  // El modo oscuro no debe cambiar ni un píxel: cada rol vale lo que valía el
  // color al que reemplaza.
  test('los valores oscuros son los colores de hoy', () {
    const dark = PingProColors.dark;

    expect(dark.page, AppColors.background);
    expect(dark.tabBar, AppColors.tab);
    expect(dark.onPage, AppColors.textWhite);
    expect(dark.card, AppColors.widgetGrayBackground);
    expect(dark.onCard, AppColors.textBlack);
    expect(dark.muted, AppColors.textGray);
    expect(dark.brand, AppColors.primary);
    expect(dark.brandFill, AppColors.primary);
    expect(dark.onBrandFill, AppColors.textBlack);
    expect(dark.softFill, AppColors.secundary);
    expect(dark.softText, AppColors.secundary);
    expect(dark.skeletonBase, AppColors.skeletonBase);
    expect(dark.skeletonHighlight, AppColors.skeletonHighlight);
    expect(dark.danger, AppColors.danger);
  });

  test('lerp en los extremos devuelve cada paleta', () {
    expect(PingProColors.dark.lerp(_other, 0).page, PingProColors.dark.page);
    expect(PingProColors.dark.lerp(_other, 1).page, _other.page);
  });
}
