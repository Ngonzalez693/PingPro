import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/core/pingpro_colors.dart';
import 'package:pingpro_front/core/pingpro_text.dart';

// Un color distinto por rol: así se ve qué rol tomó cada estilo.
const _distinct = PingProColors(
  page: Color(0xFF000001),
  tabBar: Color(0xFF000002),
  onPage: Color(0xFF000003),
  card: Color(0xFF000004),
  onCard: Color(0xFF000005),
  muted: Color(0xFF000006),
  brand: Color(0xFF000007),
  brandFill: Color(0xFF000008),
  onBrandFill: Color(0xFF000009),
  softFill: Color(0xFF00000A),
  softText: Color(0xFF00000B),
  skeletonBase: Color(0xFF00000C),
  skeletonHighlight: Color(0xFF00000D),
  danger: Color(0xFF00000E),
  hairline: Color(0xFF00000F),
);

void main() {
  // Los tamaños y pesos de siempre: el cambio a roles solo tocó el color.
  test('cada estilo conserva su tamaño y su peso', () {
    const text = PingProText(PingProColors.dark);

    for (final style in [text.title, text.titleBlack]) {
      expect((style.fontSize, style.fontWeight), (24, FontWeight.bold));
    }
    for (final style in [text.subTitle, text.subTitleBlack]) {
      expect((style.fontSize, style.fontWeight), (20, FontWeight.bold));
    }
    expect((text.buttons.fontSize, text.buttons.fontWeight), (16, FontWeight.bold));
    for (final style in [text.paragraph, text.paragraphBlack]) {
      expect((style.fontSize, style.fontWeight), (16, null));
    }
    for (final style in [text.aditional, text.caption]) {
      expect((style.fontSize, style.fontWeight), (14, null));
    }
    expect((text.brandTitle.fontFamily, text.brandTitle.fontSize), ('Anta', 28));
    expect((text.loginRegister.fontSize, text.loginRegister.fontWeight), (null, FontWeight.bold));
  });

  test('cada estilo toma su rol', () {
    const text = PingProText(_distinct);

    for (final style in [text.title, text.subTitle, text.paragraph]) {
      expect(style.color, _distinct.onPage);
    }
    for (final style in [text.titleBlack, text.subTitleBlack, text.paragraphBlack, text.aditional]) {
      expect(style.color, _distinct.onCard);
    }
    expect(text.buttons.color, _distinct.onBrandFill);
    expect(text.caption.color, _distinct.muted);
    expect(text.brandTitle.color, _distinct.brand);
    expect(text.loginRegister.color, _distinct.softText);
  });
}
