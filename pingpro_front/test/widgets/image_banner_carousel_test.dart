import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/widgets/image_banner_carousel.dart';

void main() {
  Future<PageController> pumpCarousel(WidgetTester tester, {required bool disableAnimations}) async {
    await tester.pumpWidget(MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: const Directionality(
        textDirection: TextDirection.ltr,
        child: ImageBannerCarousel(),
      ),
    ));
    return tester.widget<PageView>(find.byType(PageView)).controller!;
  }

  // Al final se quita el carrusel para que cancele su Timer.
  Future<void> dispose(WidgetTester tester) => tester.pumpWidget(const SizedBox());

  testWidgets('avanza solo cada 4 segundos', (tester) async {
    final controller = await pumpCarousel(tester, disableAnimations: false);

    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 500));

    expect(controller.page, closeTo(1, 0.01));
    await dispose(tester);
  });

  testWidgets('con animaciones reducidas no avanza solo', (tester) async {
    final controller = await pumpCarousel(tester, disableAnimations: true);

    await tester.pump(const Duration(seconds: 9));
    await tester.pump(const Duration(milliseconds: 500));

    expect(controller.page, 0);
    await dispose(tester);
  });
}
