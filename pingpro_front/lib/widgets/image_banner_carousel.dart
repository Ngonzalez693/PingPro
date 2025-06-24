import 'dart:async';
import 'package:flutter/material.dart';

class ImageBannerCarousel extends StatefulWidget {
  const ImageBannerCarousel({super.key});

  @override
  State<ImageBannerCarousel> createState() => _ImageBannerCarouselState();
}

class _ImageBannerCarouselState extends State<ImageBannerCarousel> {
  late final PageController _pageController;
  late final List<String> _bannerImages;
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();

    final originalBanners = [
      'assets/images/banner_1.jpg',
      'assets/images/banner_1.jpg',
      'assets/images/banner_1.jpg',
    ];

    _bannerImages = [...originalBanners, originalBanners[0]];
    _pageController = PageController();
    _startAutoSlide();
  }

  void _startAutoSlide() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      int nextPage = _currentPage + 1;

      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: _bannerImages.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });

                if (index == _bannerImages.length - 1) {
                  Future.delayed(const Duration(milliseconds: 450), () {
                    _pageController.jumpToPage(0);
                    setState(() {
                      _currentPage = 0;
                    });
                  });
                }
              },
              itemBuilder: (context, index) {
                return Image.asset(
                  _bannerImages[index],
                  fit: BoxFit.cover,
                  width: double.infinity,
                );
              },
            ),
            // Indicadores en la parte inferior dentro del banner
            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _buildIndicators(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildIndicators() {
    int totalIndicators = _bannerImages.length - 1;

    return List.generate(totalIndicators, (index) {
      bool isActive = _currentPage % totalIndicators == index;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: isActive ? 12 : 8,
        height: 8,
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.grey[400],
          borderRadius: BorderRadius.circular(4),
        ),
      );
    });
  }
}
