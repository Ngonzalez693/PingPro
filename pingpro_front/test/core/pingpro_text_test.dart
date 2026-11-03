import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/core/pingpro_colors.dart';
import 'package:pingpro_front/core/pingpro_text.dart';
import 'package:pingpro_front/core/text_styles.dart';

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
);

void main() {
  test('con la paleta oscura cada estilo es igual al de hoy', () {
    const text = PingProText(PingProColors.dark);

    expect(text.title, TextStyles.title);
    expect(text.titleBlack, TextStyles.titleBlack);
    expect(text.subTitle, TextStyles.subTitle);
    expect(text.subTitleBlack, TextStyles.subTitleBlack);
    expect(text.buttons, TextStyles.buttons);
    expect(text.paragraph, TextStyles.paragraph);
    expect(text.paragraphBlack, TextStyles.paragraphBlack);
    expect(text.aditional, TextStyles.aditional);
    expect(text.caption, TextStyles.caption);
    expect(text.brandTitle, TextStyles.brandTitle);
    expect(text.loginRegister, TextStyles.loginRegister);
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
