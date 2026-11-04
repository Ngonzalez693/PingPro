import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/core/app_theme.dart';
import 'package:pingpro_front/core/pingpro_colors.dart';
import 'package:pingpro_front/widgets/always_dark.dart';

void main() {
  // Login, registro y bienvenida usan imágenes dibujadas sobre negro: se
  // quedan oscuras aunque el resto de la app esté en claro.
  testWidgets('dentro siempre es oscuro aunque la app esté en claro', (tester) async {
    late PingProColors seen;
    await tester.pumpWidget(MaterialApp(
      theme: buildAppTheme(PingProColors.light),
      home: AlwaysDark(child: Builder(builder: (context) {
        seen = context.colors;
        return const SizedBox();
      })),
    ));

    expect(seen, PingProColors.dark);
  });

  testWidgets('un diálogo abierto desde dentro también es oscuro', (tester) async {
    late PingProColors seen;
    await tester.pumpWidget(MaterialApp(
      theme: buildAppTheme(PingProColors.light),
      home: AlwaysDark(child: Builder(builder: (context) {
        return TextButton(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (dialogContext) {
              seen = dialogContext.colors;
              return const SizedBox();
            },
          ),
          child: const Text('abrir'),
        );
      })),
    ));

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(seen, PingProColors.dark);
  });
}
