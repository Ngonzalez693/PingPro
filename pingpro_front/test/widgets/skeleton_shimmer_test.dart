import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/widgets/skeleton_box.dart';
import 'package:pingpro_front/widgets/skeleton_shimmer.dart';

void main() {
  Future<void> pumpShimmer(WidgetTester tester, {required bool disableAnimations}) {
    return tester.pumpWidget(MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: const Directionality(
        textDirection: TextDirection.ltr,
        child: SkeletonShimmer(child: SkeletonBox(height: 20)),
      ),
    ));
  }

  testWidgets('normalmente el brillo recorre las cajas en bucle', (tester) async {
    await pumpShimmer(tester, disableAnimations: false);

    expect(tester.hasRunningAnimations, isTrue);
    expect(find.byType(ShaderMask), findsOneWidget);
  });

  testWidgets('con animaciones reducidas queda gris y quieto', (tester) async {
    await pumpShimmer(tester, disableAnimations: true);

    expect(tester.hasRunningAnimations, isFalse);
    expect(find.byType(ShaderMask), findsNothing);
  });

  testWidgets('si se reducen con el skeleton a la vista, se detiene', (tester) async {
    await pumpShimmer(tester, disableAnimations: false);

    await pumpShimmer(tester, disableAnimations: true);

    expect(tester.hasRunningAnimations, isFalse);
  });
}
