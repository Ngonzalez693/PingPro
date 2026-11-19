// Cabecera de la sección Estadísticas de la pestaña Perfil. "Ver detalle" es
// una entrada a la vista que se ve sin tener que adivinar que la gráfica y los
// círculos también se pueden tocar.
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_theme.dart';

class StatsSectionHeader extends StatelessWidget {
  final String caption;
  final VoidCallback onSeeDetail;

  const StatsSectionHeader({super.key, required this.caption, required this.onSeeDetail});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Estadísticas', style: context.text.subTitle),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(child: Text(caption, style: context.text.caption)),
            const SizedBox(width: 8),
            TextButton(
              onPressed: onSeeDetail,
              style: TextButton.styleFrom(
                foregroundColor: colors.brand,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Ver detalle', style: context.text.caption.copyWith(color: colors.brand)),
                  Icon(Icons.chevron_right, size: 18, color: colors.brand),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
