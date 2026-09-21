// Barra de navegación inferior de las 5 pestañas.
//
// Hecha a mano en vez de con BottomNavigationBar para poder usar los SVG de
// assets/icons/ (cada pestaña tiene versión seleccionada y sin seleccionar) y
// elevar el icono activo 8 px.
//
// Cada pestaña ocupa un quinto del ancho y todo el alto de la barra, y esa
// celda entera es el área pulsable.
//
// Sin estado propio: `currentIndex` y `onTap` los controla HomeNavigation.
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Alto de la barra. Es también el alto del área pulsable de cada pestaña.
const double _barHeight = 70;

class CustomBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: _barHeight,
        decoration: BoxDecoration(
          color: AppColors.tab,
          boxShadow: [
            BoxShadow(
              color: Colors.black,
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildNavItem(
              'assets/icons/home_unselected.svg',
              'assets/icons/home_selected.svg',
              0,
            ),
            _buildNavItem(
              'assets/icons/exercise_unselected.svg',
              'assets/icons/exercise_selected.svg',
              1,
            ),
            _buildNavItem(
              'assets/icons/create_unselected.svg',
              'assets/icons/create_selected.svg',
              2,
            ),
            _buildNavItem(
              'assets/icons/training_unselected.svg',
              'assets/icons/training_selected.svg',
              3,
            ),
            _buildNavItem(
              'assets/icons/profile_unselected.svg',
              'assets/icons/profile_selected.svg',
              4,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    String assetUnselected,
    String assetSelected,
    int index,
  ) {
    final isSelected = currentIndex == index;
    // El área pulsable es la celda entera (alto completo de la barra), no el
    // icono: con `opaque` el GestureDetector responde también donde no hay
    // nada pintado. Antes dependía del SVG de 26 px, así que la mayoría de la
    // celda no reaccionaba.
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(index),
        child: SizedBox(
          height: _barHeight,
          child: Center(
            // El desplazamiento del icono activo es solo visual: queda dentro
            // de la celda, que sigue siendo pulsable de arriba abajo.
            child: Transform.translate(
              offset: Offset(0, isSelected ? -8 : 0),
              child: SvgPicture.asset(
                isSelected ? assetSelected : assetUnselected,
                height: 26,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
