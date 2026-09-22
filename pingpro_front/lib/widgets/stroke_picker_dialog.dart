// Diálogo que aparece al soltar una flecha en la mesa: pide el golpe y su
// rotación.
//
// Dirección, zona y lado ya salen del gesto (core/table_geometry.dart); aquí
// solo falta lo que no se puede dibujar. Las opciones son los códigos de
// core/stroke_codes.dart, así que nunca produce un valor que el backend no
// acepte.
//
// También aplica las reglas de cada golpe (core/stroke_codes.dart): solo
// ofrece los golpes posibles desde la profundidad del origen y, para el golpe
// elegido, solo sus rotaciones.
//
// Son dos desplegables y no una rejilla de chips: con 12 golpes y 7 rotaciones,
// los chips ocupaban unos 900 px y en un móvil había que hacer scroll dentro
// del diálogo.
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/core/stroke_codes.dart';
import 'package:pingpro_front/core/text_styles.dart';

/// Lo que elige el usuario en el diálogo.
typedef StrokeChoice = ({int hit, int rotation});

/// Abre el diálogo para un golpe que sale desde la profundidad [ownZone].
/// Devuelve null si el usuario cancela.
Future<StrokeChoice?> showStrokePicker(BuildContext context, {required int ownZone}) {
  return showDialog<StrokeChoice>(
    context: context,
    builder: (_) => StrokePickerDialog(ownZone: ownZone),
  );
}

class StrokePickerDialog extends StatefulWidget {
  /// Profundidad propia del golpe (ZoneCode): decide qué golpes se ofrecen.
  final int ownZone;

  const StrokePickerDialog({super.key, required this.ownZone});

  @override
  State<StrokePickerDialog> createState() => _StrokePickerDialogState();
}

class _StrokePickerDialogState extends State<StrokePickerDialog> {
  int? _hit;
  int? _rotation;

  bool get _isComplete => _hit != null && _rotation != null;

  void _confirm() => Navigator.pop<StrokeChoice>(context, (hit: _hit!, rotation: _rotation!));

  void _selectHit(int hit) {
    final rotations = allowedRotations(hit);
    setState(() {
      _hit = hit;
      // Con una sola rotación posible no queda nada que elegir, y una rotación
      // que el golpe nuevo no admite no puede quedarse marcada.
      if (rotations.length == 1) {
        _rotation = rotations.single;
      } else if (!rotations.contains(_rotation)) {
        _rotation = null;
      }
    });
  }

  Map<int, String> _rotationOptions() {
    final hit = _hit;
    if (hit == null) return rotationLabels;
    return _only(rotationLabels, allowedRotations(hit));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.widgetBackground,
      title: const Text('Elegir golpe', style: TextStyles.subTitleBlack),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDropdown('Golpe', _only(hitLabels, hitsAvailableFrom(widget.ownZone)), _hit, _selectHit),
          const SizedBox(height: 16),
          // La clave cambia con el golpe: así el campo se rehace con la
          // rotación autoelegida o vaciada, en vez de conservar la anterior.
          _buildDropdown(
            'Rotación',
            _rotationOptions(),
            _rotation,
            (code) => setState(() => _rotation = code),
            key: ValueKey(_hit),
          ),
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
    ValueChanged<int> onSelected, {
    Key? key,
  }) {
    return DropdownButtonFormField<int>(
      key: key,
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

/// Las entradas de [labels] cuyos códigos están en [codes], en ese orden.
Map<int, String> _only(Map<int, String> labels, List<int> codes) => {
      for (final code in codes) code: labels[code]!,
    };
