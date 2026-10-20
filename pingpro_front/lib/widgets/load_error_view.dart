// Lo que se ve cuando una carga de datos falla: el mensaje amable que dejan
// los stores (core/load_errors.dart) y un botón para volver a intentarlo.
//
// `compact` es para las secciones pequeñas (las de Inicio): una sola fila en
// vez del bloque centrado que ocupa la pantalla.
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/core/text_styles.dart';

class LoadErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final bool compact;

  const LoadErrorView({super.key, required this.message, required this.onRetry, this.compact = false});

  @override
  Widget build(BuildContext context) => compact ? _buildRow() : _buildBlock();

  Widget _buildBlock() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, color: AppColors.textGray, size: 48),
            const SizedBox(height: 12),
            Text(message, style: TextStyles.paragraph, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            _buildRetry(),
          ],
        ),
      ),
    );
  }

  Widget _buildRow() {
    return Row(
      children: [
        const Icon(Icons.cloud_off, color: AppColors.textGray, size: 24),
        const SizedBox(width: 12),
        Expanded(child: Text(message, style: TextStyles.caption)),
        _buildRetry(),
      ],
    );
  }

  Widget _buildRetry() {
    return TextButton.icon(
      onPressed: onRetry,
      icon: const Icon(Icons.refresh, color: AppColors.primary),
      label: const Text('Reintentar', style: TextStyle(color: AppColors.primary)),
    );
  }
}
