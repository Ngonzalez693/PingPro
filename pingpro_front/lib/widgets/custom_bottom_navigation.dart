import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
      child: SizedBox(
        height: 90,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            // Fondo de la tab bar
            Container(
              height: 70,
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
            ),

            // Tabs
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 70,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
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
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        child: Transform.translate(
          offset: Offset(0, isSelected ? -8 : 0),
          child: Container(
            padding: const EdgeInsets.all(12),
            child: SvgPicture.asset(
              isSelected ? assetSelected : assetUnselected,
              height: 26,
            ),
          ),
        ),
      ),
    );
  }
}
