// Diálogo que aparece al soltar una flecha en la mesa: pide el golpe y su
// rotación.
//
// Dirección, zona y lado ya salen del gesto (core/table_geometry.dart); aquí
// solo falta lo que no se puede dibujar. Las opciones son los códigos de
// core/stroke_codes.dart, así que nunca produce un valor que el backend no
// acepte.
//
// Son dos desplegables y no una rejilla de chips: con 9 golpes y 7 rotaciones,
// los chips ocupaban unos 900 px y en un móvil había que hacer scroll dentro
// del diálogo.
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/core/stroke_codes.dart';
import 'package:pingpro_front/core/text_styles.dart';

/// Lo que elige el usuario en el diálogo.
typedef StrokeChoice = ({int hit, int rotation});

/// Abre el diálogo. Devuelve null si el usuario cancela.
Future<StrokeChoice?> showStrokePicker(BuildContext context) {
  return showDialog<StrokeChoice>(
    context: context,
    builder: (_) => const StrokePickerDialog(),
  );
}

class StrokePickerDialog extends StatefulWidget {
  const StrokePickerDialog({super.key});

  @override
  State<StrokePickerDialog> createState() => _StrokePickerDialogState();
}

class _StrokePickerDialogState extends State<StrokePickerDialog> {
  int? _hit;
  int? _rotation;

  bool get _isComplete => _hit != null && _rotation != null;

  void _confirm() => Navigator.pop<StrokeChoice>(context, (hit: _hit!, rotation: _rotation!));

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.widgetBackground,
      title: const Text('Elegir golpe', style: TextStyles.subTitleBlack),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDropdown('Golpe', hitLabels, _hit, (code) => setState(() => _hit = code)),
          const SizedBox(height: 16),
          _buildDropdown('Rotación', rotationLabels, _rotation, (code) => setState(() => _rotation = code)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyles.paragraphBlack),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          onPressed: _isComplete ? _confirm : null,
          child: const Text('Añadir', style: TextStyles.buttons),
        ),
      ],
    );
  }

  Widget _buildDropdown(
    String label,
    Map<int, String> labels,
    int? selected,
    ValueChanged<int> onSelected,
  ) {
    return DropdownButtonFormField<int>(
      value: selected,
      isExpanded: true,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      items: [
        for (final entry in labels.entries)
          DropdownMenuItem(value: entry.key, child: Text(entry.value)),
      ],
      onChanged: (code) {
        if (code != null) onSelected(code);
      },
    );
  }
}
