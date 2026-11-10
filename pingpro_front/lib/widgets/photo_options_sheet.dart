// Menú del botón de cámara del perfil. "Quitar foto" solo sale si hay una.
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_theme.dart';

enum PhotoAction { pick, remove }

Future<PhotoAction?> showPhotoOptions(BuildContext context, {required bool hasPhoto}) {
  return showModalBottomSheet<PhotoAction>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      final colors = sheetContext.colors;
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo_library_outlined, color: colors.onPage),
              title: Text('Elegir de la galería', style: sheetContext.text.paragraph),
              onTap: () => Navigator.pop(sheetContext, PhotoAction.pick),
            ),
            if (hasPhoto)
              ListTile(
                leading: Icon(Icons.delete_outline, color: colors.danger),
                title: Text('Quitar foto', style: sheetContext.text.paragraph.copyWith(color: colors.danger)),
                onTap: () => Navigator.pop(sheetContext, PhotoAction.remove),
              ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}
