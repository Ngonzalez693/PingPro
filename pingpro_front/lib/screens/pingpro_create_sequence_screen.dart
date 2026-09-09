// Segundo paso del flujo de creación: dibujar la secuencia de golpes sobre la
// mesa.
//
// ESTADO: prototipo. Funciona la mecánica de interfaz (mantener pulsado un
// botón de la mesa abre un diálogo de destino, dibuja una flecha y pide el
// golpe), pero no produce datos reales:
//   - Los golpes son dos literales de prueba ("Top Der", "Top Izq") en vez de
//     los códigos de SequenceStep.
//   - Los destinos son coordenadas fijas escritas a mano, no zonas de la mesa.
//   - Las posiciones de la mesa y los botones son píxeles absolutos: no se
//     adaptan al tamaño de pantalla y se descuadran en otros dispositivos.
//   - El botón "Subir y ver" no hace nada.
//
// Para terminarlo hay que producir List<SequenceStep> con los códigos de
// pingpro_back/src/utils/enums.ts y enviarlo con POST /api/exercises.
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/widgets/pingpong_table.dart';
//import 'package:pingpro_front/models/sequence_step_model.dart';

class PingproCreateSequenceScreen extends StatefulWidget {
  const PingproCreateSequenceScreen({super.key});

  @override
  State<PingproCreateSequenceScreen> createState() => _PingproCreateSequenceScreenState();
}

class _PingproCreateSequenceScreenState extends State<PingproCreateSequenceScreen> {
  //final List<SequenceStep> _steps = [];

  final List<Offset?> _arrows = List<Offset?>.filled(10, null);

  // Menú de golpe + rotación para cada flecha
  final List<String> _selectedHits = List<String>.filled(5, "Top Der");
  final List<String> _hitsList = ["Top Der", "Top Izq"]; // Completa con tus opciones reales

  // Demo: puntos "finales" posibles (al otro lado de la mesa, ajusta coordenadas reales)
  final List<Offset> _targetPoints = [
    Offset(30, 50),   // Ejemplo: izq
    Offset(75, 50),   // centro izq
    Offset(120, 50),  // centro
    Offset(170, 50),  // centro der
    Offset(220, 50),  // der
  ];

  // Devuelve el widget de la flecha, si ya hay
  Widget _buildArrow(int i, double x, double y) {
    if (_arrows[i] == null) return const SizedBox();
    return CustomPaint(
      painter: _ArrowPainter(
        start: Offset(x, y),
        end: _arrows[i]!,
        color: AppColors.primary,
      ),
    );
  }

  // Acción de arrastrar flecha (real y UX demo, deberás mejorarla para arrastre libre si quieres)
  void _onStartArrow(int i, Offset origin) async {
    final dst = await showDialog<Offset>(
      context: context,
      builder: (context) => _ArrowDestinationDialog(targets: _targetPoints),
    );
    if (dst != null) {
      setState(() => _arrows[i] = dst);
      // Al soltar, pide seleccionar golpe+rotación
      final result = await showDialog<String>(
        // ignore: use_build_context_synchronously
        context: context,
        builder: (context) => SimpleDialog(
          title: const Text("Elegir golpe"),
          children: _hitsList.map((h) => SimpleDialogOption(
            child: Text(h),
            onPressed: () => Navigator.pop(context, h),
          )).toList(),
        ),
      );
      if (result != null) setState(() => _selectedHits[i] = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double tableLeft = 45; // posición en X de la mesa en pantalla
    final double tableTop = 90;  // posición en Y de la mesa, ajustar según layout final
    final double buttonY = tableTop + 300; // Y desde donde salen las flechas (posición de plus_buttons abajo)
    final List<double> buttonX = [
      tableLeft + 30,
      tableLeft + 75,
      tableLeft + 120,
      tableLeft + 170,
      tableLeft + 220
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Flecha volver
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.textWhite),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(height: 10),
                // Mesa con plus_buttons (no interactivos aquí)
                Center(child: PingPongTable()),
                // Lista de pasos agregados
                if (_arrows.any((e) => e != null)) ...[
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (int j = 0; j < _arrows.length; j++)
                          if (_arrows[j] != null)
                            Text("${j+1}. ${_selectedHits[j]}"),
                      ],
                    ),
                  ),
                ],
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 30),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textBlack,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
                    ),
                    onPressed: () {
                      // Acción subir y ver
                    },
                    child: const Text("Subir y ver"),
                  ),
                ),
              ],
            ),
            // Dibuja flechas encima de la mesa según estén agregadas
            ...List.generate(5, (i) {
              if (_arrows[i] == null) return const SizedBox.shrink();
              return Positioned.fill(
                child: _buildArrow(i, buttonX[i], buttonY),
              );
            }),
            // Overlay: detecta long press en los botones plus para comenzar la flecha
            ...List.generate(5, (i) => Positioned(
              left: buttonX[i]-14, top: buttonY-14,
              child: GestureDetector(
                onLongPress: () => _onStartArrow(i, Offset(buttonX[i], buttonY)),
                child: Container(
                  width: 28, height: 28,
                  color: Colors.transparent,
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}

/// Dibuja una flecha desde start hasta end
class _ArrowPainter extends CustomPainter {
  final Offset start;
  final Offset end;
  final Color color;
  _ArrowPainter({required this.start, required this.end, this.color = Colors.yellow});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(start, end, paint);
    // Flecha (pico)
    final angle = (end - start).direction;
    const arrowSize = 10.0;
    final p1 = end - Offset.fromDirection(angle - 0.3, arrowSize);
    final p2 = end - Offset.fromDirection(angle + 0.3, arrowSize);
    canvas.drawLine(end, p1, paint);
    canvas.drawLine(end, p2, paint);
  }
  @override
  bool shouldRepaint(_ArrowPainter old) => start != old.start || end != old.end || color != old.color;
}

/// Menú modal para elegir el destino final de la flecha (puntos predeterminados)
class _ArrowDestinationDialog extends StatelessWidget {
  final List<Offset> targets;
  const _ArrowDestinationDialog({required this.targets});
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Selecciona destino"),
      content: SizedBox(
        width: 250,
        height: 80,
        child: Row(
          children: List.generate(targets.length, (i) => 
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.pop(context, targets[i]),
                child: Container(
                  width: 32, height: 32,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.textGray, width: 1),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
