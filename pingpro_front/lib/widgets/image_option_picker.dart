// Fila de imágenes para elegir una, con la elegida recuadrada en amarillo.
//
// La usan los formularios de crear ejercicio y entrenamiento: en los dos la
// imagen es un asset de la app, no una foto subida.
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';

class ImageOptionPicker extends StatelessWidget {
  final List<String> images;
  final String selected;
  final ValueChanged<String> onSelected;

  const ImageOptionPicker({
    super.key,
    required this.images,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < images.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(child: _buildOption(images[i], i + 1)),
        ],
      ],
    );
  }

  Widget _buildOption(String path, int number) {
    final isSelected = path == selected;
    return Semantics(
      label: 'Imagen $number',
      selected: isSelected,
      button: true,
      child: GestureDetector(
        key: ValueKey(path),
        onTap: () => onSelected(path),
        child: AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSelected ? AppColors.primary : AppColors.tab, width: 3),
              image: DecorationImage(image: AssetImage(path), fit: BoxFit.cover),
            ),
          ),
        ),
      ),
    );
  }
}
