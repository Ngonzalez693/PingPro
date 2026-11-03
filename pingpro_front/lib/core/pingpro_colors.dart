// Colores de la app por rol (fondo de pantalla, texto sobre tarjeta…) en vez
// de por valor: `textWhite` deja de ser blanco en modo claro. Los widgets los
// leen del tema con `context.colors` (ver app_theme.dart).
//
// `dark` es el aspecto de siempre, tomado de AppColors. La lima tiene dos
// roles con el mismo valor en oscuro: `brandFill` cuando es un fondo (botones,
// etiquetas) y `brand` cuando es texto o línea, que en claro no se vería.
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';

class PingProColors extends ThemeExtension<PingProColors> {
  final Color page;
  final Color tabBar;
  final Color onPage;
  final Color card;
  final Color onCard;
  final Color muted;
  final Color brand;
  final Color brandFill;
  final Color onBrandFill;
  final Color softFill;
  final Color softText;
  final Color skeletonBase;
  final Color skeletonHighlight;
  final Color danger;

  const PingProColors({
    required this.page,
    required this.tabBar,
    required this.onPage,
    required this.card,
    required this.onCard,
    required this.muted,
    required this.brand,
    required this.brandFill,
    required this.onBrandFill,
    required this.softFill,
    required this.softText,
    required this.skeletonBase,
    required this.skeletonHighlight,
    required this.danger,
  });

  static const dark = PingProColors(
    page: AppColors.background,
    tabBar: AppColors.tab,
    onPage: AppColors.textWhite,
    card: AppColors.widgetGrayBackground,
    onCard: AppColors.textBlack,
    muted: AppColors.textGray,
    brand: AppColors.primary,
    brandFill: AppColors.primary,
    onBrandFill: AppColors.textBlack,
    softFill: AppColors.secundary,
    softText: AppColors.secundary,
    skeletonBase: AppColors.skeletonBase,
    skeletonHighlight: AppColors.skeletonHighlight,
    danger: AppColors.danger,
  );

  @override
  PingProColors copyWith({
    Color? page,
    Color? tabBar,
    Color? onPage,
    Color? card,
    Color? onCard,
    Color? muted,
    Color? brand,
    Color? brandFill,
    Color? onBrandFill,
    Color? softFill,
    Color? softText,
    Color? skeletonBase,
    Color? skeletonHighlight,
    Color? danger,
  }) {
    return PingProColors(
      page: page ?? this.page,
      tabBar: tabBar ?? this.tabBar,
      onPage: onPage ?? this.onPage,
      card: card ?? this.card,
      onCard: onCard ?? this.onCard,
      muted: muted ?? this.muted,
      brand: brand ?? this.brand,
      brandFill: brandFill ?? this.brandFill,
      onBrandFill: onBrandFill ?? this.onBrandFill,
      softFill: softFill ?? this.softFill,
      softText: softText ?? this.softText,
      skeletonBase: skeletonBase ?? this.skeletonBase,
      skeletonHighlight: skeletonHighlight ?? this.skeletonHighlight,
      danger: danger ?? this.danger,
    );
  }

  // Lo usa el fundido de Theme al cambiar de tema.
  @override
  PingProColors lerp(PingProColors? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return PingProColors(
      page: mix(page, other.page),
      tabBar: mix(tabBar, other.tabBar),
      onPage: mix(onPage, other.onPage),
      card: mix(card, other.card),
      onCard: mix(onCard, other.onCard),
      muted: mix(muted, other.muted),
      brand: mix(brand, other.brand),
      brandFill: mix(brandFill, other.brandFill),
      onBrandFill: mix(onBrandFill, other.onBrandFill),
      softFill: mix(softFill, other.softFill),
      softText: mix(softText, other.softText),
      skeletonBase: mix(skeletonBase, other.skeletonBase),
      skeletonHighlight: mix(skeletonHighlight, other.skeletonHighlight),
      danger: mix(danger, other.danger),
    );
  }
}
