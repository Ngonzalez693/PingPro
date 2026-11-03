import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/core/app_theme.dart';
import 'package:pingpro_front/core/pingpro_colors.dart';

final _custom = PingProColors.dark.copyWith(page: const Color(0xFF112233), onPage: const Color(0xFF445566));

void main() {
  // Muchos tests montan un widget suelto, sin MaterialApp: tiene que seguir
  // funcionando y verse como hoy.
  testWidgets('sin tema encima usa la paleta oscura', (tester) async {
    late PingProColors seen;
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Builder(builder: (context) {
        seen = context.colors;
        return const SizedBox();
      }),
    ));

    expect(seen, PingProColors.dark);
  });

  testWidgets('lee la paleta del tema', (tester) async {
    late PingProColors seen;
    late Color titleColor;
    await tester.pumpWidget(MaterialApp(
      theme: buildAppTheme(_custom),
      home: Builder(builder: (context) {
        seen = context.colors;
        titleColor = context.text.title.color!;
        return const SizedBox();
      }),
    ));

    expect(seen, _custom);
    expect(titleColor, _custom.onPage);
  });

  test('el fondo de las pantallas es el de la paleta', () {
    expect(buildAppTheme(PingProColors.dark).scaffoldBackgroundColor, AppColors.background);
  });
}
