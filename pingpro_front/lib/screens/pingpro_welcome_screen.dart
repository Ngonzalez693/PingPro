// Onboarding de 3 páginas para quien abre la app sin sesión.
//
// Solo la imagen va en el PageView; el texto y el botón se cambian con un
// AnimatedSwitcher aparte, para que el bloque inferior no se deslice junto con
// la imagen. Al terminar pasa al splash, que a su vez lleva al login.
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/core/text_styles.dart';
import 'package:pingpro_front/screens/pingpro_splash_screen.dart';

class PingproWelcomeScreen extends StatefulWidget {
  const PingproWelcomeScreen({super.key});

  @override
  State<PingproWelcomeScreen> createState() => _PingproWelcomeScreenState();
}

class _PingproWelcomeScreenState extends State<PingproWelcomeScreen> {
  final PageController _imageController = PageController();
  int _currentPage = 0;

  final List<_WelcomePageData> _pages = [
    _WelcomePageData(
      image: 'assets/images/welcome_image_1.png',
      title: 'Bienvenido a PingPro',
      description:
          'La app donde podrás encontrar los mejores ejercicios y entrenamientos del tenis de mesa',
      buttonText: 'Siguiente',
    ),
    _WelcomePageData(
      image: 'assets/images/welcome_image_2.png',
      title: 'Visualiza en 3D',
      description:
          'Mira ejercicios y entrenamientos de una manera innovadora para el tenis de mesa',
      buttonText: 'Siguiente',
    ),
    _WelcomePageData(
      image: 'assets/images/welcome_image_3.jpg',
      title: 'Crea y registra',
      description:
          'Crea tus propios ejercicios y entrenamientos personalizados',
      buttonText: 'Empecemos',
    ),
  ];

  void _onButtonPressed() {
    if (_currentPage < _pages.length - 1) {
      _imageController.nextPage(
        duration: Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PingproSplashScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Solo la imagen se mueve con swipe
            Expanded(
              child: PageView.builder(
                controller: _imageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: Image.asset(
                      _pages[index].image,
                      fit: BoxFit.contain,
                    ),
                  );
                },
              ),
            ),
            // El texto y el botón cambian con animación fade
            Container(
              color: AppColors.background,
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 32.0,
              ),
              child: AnimatedSwitcher(
                duration: Duration(milliseconds: 400),
                transitionBuilder:
                    (child, animation) =>
                        FadeTransition(opacity: animation, child: child),
                child: Column(
                  key: ValueKey(_currentPage),
                  children: [
                    Text(
                      page.title,
                      style: TextStyles.title,
                      textAlign: TextAlign.center,
                    ),
                    if (page.description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Text(
                          page.description,
                          style: TextStyles.paragraph,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    SizedBox(height: 24),
                    _buildDotsIndicator(),
                    SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textBlack,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 12,
                        ),
                      ),
                      onPressed: _onButtonPressed,
                      child: Text(
                        page.buttonText,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDotsIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _pages.length,
        (index) => Container(
          margin: EdgeInsets.symmetric(horizontal: 4),
          width: 18,
          height: 4,
          decoration: BoxDecoration(
            color:
                _currentPage == index
                    ? AppColors.widgetBackgroundSelected
                    : AppColors.widgetBackground,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

class _WelcomePageData {
  final String image;
  final String title;
  final String description;
  final String buttonText;

  _WelcomePageData({
    required this.image,
    required this.title,
    required this.description,
    required this.buttonText,
  });
}
