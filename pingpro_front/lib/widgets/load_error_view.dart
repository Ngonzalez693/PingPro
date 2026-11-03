// Lo que se ve cuando una carga de datos falla: el mensaje amable que dejan
// los stores (core/load_errors.dart) y un botón para volver a intentarlo.
//
// `compact` es para las secciones pequeñas (las de Inicio): una sola fila en
// vez del bloque centrado que ocupa la pantalla.
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_theme.dart';

class LoadErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final bool compact;

  const LoadErrorView({super.key, required this.message, required this.onRetry, this.compact = false});

  @override
  Widget build(BuildContext context) => compact ? _buildRow(context) : _buildBlock(context);

  Widget _buildBlock(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, color: context.colors.muted, size: 48),
            const SizedBox(height: 12),
            Text(message, style: context.text.paragraph, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            _buildRetry(context),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.cloud_off, color: context.colors.muted, size: 24),
        const SizedBox(width: 12),
        Expanded(child: Text(message, style: context.text.caption)),
        _buildRetry(context),
      ],
    );
  }

  Widget _buildRetry(BuildContext context) {
    return TextButton.icon(
      onPressed: onRetry,
      icon: Icon(Icons.refresh, color: context.colors.brand),
      label: Text('Reintentar', style: TextStyle(color: context.colors.brand)),
    );
  }
}
