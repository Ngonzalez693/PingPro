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
  hairline: Color(0xFF123456),
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
    // En oscuro la línea fina no se ve: el modo oscuro queda como estaba.
    expect(dark.hairline.a, 0);
  });

  test('los valores claros son los del diseño', () {
    const light = PingProColors.light;

    expect(light.page, const Color(0xFFFBFFEA));
    expect(light.tabBar, const Color(0xFFFBFFEA));
    expect(light.onPage, const Color(0xFF1B1D00));
    expect(light.card, const Color(0xFFFFFFFF));
    expect(light.onCard, const Color(0xFF1B1D00));
    expect(light.muted, const Color(0xFF6B6F55));
    expect(light.brand, const Color(0xFF5C6300));
    expect(light.brandFill, const Color(0xFFECFF17));
    expect(light.onBrandFill, const Color(0xFF000000));
    expect(light.softFill, const Color(0xFFFFFFFF));
    expect(light.softText, const Color(0xFF5C6300));
    expect(light.skeletonBase, const Color(0xFFECEEDD));
    expect(light.skeletonHighlight, const Color(0xFFF7F8EE));
    expect(light.danger, const Color(0xFFB3261E));
    expect(light.hairline, const Color(0x335C6300));
  });

  // 4,5 es el mínimo para leer texto chico cómodo (WCAG AA).
  test('en claro el texto se lee', () {
    const light = PingProColors.light;
    double contrast(Color a, Color b) {
      final la = a.computeLuminance(), lb = b.computeLuminance();
      return ((la > lb ? la : lb) + 0.05) / ((la > lb ? lb : la) + 0.05);
    }

    final pairs = {
      'onPage/page': (light.onPage, light.page),
      'onCard/card': (light.onCard, light.card),
      'muted/page': (light.muted, light.page),
      'muted/card': (light.muted, light.card),
      'brand/page': (light.brand, light.page),
      'brand/card': (light.brand, light.card),
      'onBrandFill/brandFill': (light.onBrandFill, light.brandFill),
      'danger/page': (light.danger, light.page),
      'softText/page': (light.softText, light.page),
    };
    for (final MapEntry(:key, value: (fg, bg)) in pairs.entries) {
      expect(contrast(fg, bg), greaterThanOrEqualTo(4.5), reason: key);
    }
  });

  test('lerp en los extremos devuelve cada paleta', () {
    expect(PingProColors.dark.lerp(_other, 0).page, PingProColors.dark.page);
    expect(PingProColors.dark.lerp(_other, 1).page, _other.page);
  });
}
