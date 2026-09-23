// Editor de la secuencia de un ejercicio: se dibujan los golpes sobre la mesa.
//
// Cómo se crea un golpe:
//   1. Se pulsa uno de los "+" de tu lado (fila larga, fila corta o bandas) y
//      se arrastra. El "+" elegido da el lado (side) y la profundidad propia
//      (ownZone): fila larga, fila corta o banda.
//   2. En el campo del rival la flecha se engancha al punto de destino más
//      cercano, que se resalta. Al soltar, ese punto da la dirección y la zona.
//      Soltarla en tu propio campo no crea golpe.
//   3. Un diálogo pide el golpe y la rotación, con las opciones posibles
//      desde esa profundidad.
//
// Todas las reglas de posición → código viven en core/table_geometry.dart;
// esta pantalla solo traduce gestos y pinta.
//
// Al pulsar "Subir y ver" devuelve la List<SequenceStep> a quien abrió la
// pantalla con Navigator.pop. No guarda nada por su cuenta.
//
// Con `onReview`, "Subir y ver" llama primero a esa función, que abre la vista
// previa encima del editor. Si al volver el ejercicio no se creó, el editor
// sigue ahí con las flechas dibujadas, en vez de haberse cerrado y perderlas.
//
// Puede abrirse con una secuencia (`initialSteps`) para editarla: cada paso se
// dibuja con su flecha reconstruida (table_geometry.dart) pero conserva sus
// códigos, aunque la flecha quede en un punto aproximado. Los golpes se
// reordenan arrastrando su asa en la lista, como en el formulario de
// entrenamiento.
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/core/stroke_codes.dart';
import 'package:pingpro_front/core/table_geometry.dart';
import 'package:pingpro_front/core/text_styles.dart';
import 'package:pingpro_front/models/sequence_step_model.dart';
import 'package:pingpro_front/widgets/dragged_row_decorator.dart';
import 'package:pingpro_front/widgets/pingpong_table.dart';
import 'package:pingpro_front/widgets/plus_button.dart';
import 'package:pingpro_front/widgets/stroke_arrows_painter.dart';
import 'package:pingpro_front/widgets/stroke_picker_dialog.dart';

/// Un golpe de la lista: sus códigos, la flecha con la que se dibuja y una
/// clave estable para que reordenar no confunda una fila con otra.
typedef _Stroke = ({int key, SequenceStep step, StrokeArrow arrow});

class PingproCreateSequenceScreen extends StatefulWidget {
  /// Revisa la secuencia antes de cerrar el editor. Devuelve true si ya se
  /// usó (p. ej. se creó el ejercicio) y el editor debe cerrarse.
  final Future<bool> Function(List<SequenceStep> steps)? onReview;

  /// Golpes con los que abre el editor (al editar un ejercicio).
  final List<SequenceStep> initialSteps;

  const PingproCreateSequenceScreen({super.key, this.onReview, this.initialSteps = const []});

  @override
  State<PingproCreateSequenceScreen> createState() => _PingproCreateSequenceScreenState();
}

class _PingproCreateSequenceScreenState extends State<PingproCreateSequenceScreen> {
  /// Distancia, en píxeles, a la que un toque cuenta como sobre un "+".
  static const _originTouchRadius = 28.0;

  late List<_Stroke> _strokes;
  int _nextKey = 0;
  StrokeArrow? _dragging;

  // Rectángulo de la mesa en el lienzo. Lo fija LayoutBuilder en cada build y
  // lo leen los gestos, que siempre llegan después de un layout.
  Rect _table = Rect.zero;

  @override
  void initState() {
    super.initState();
    _strokes = [for (final step in widget.initialSteps) _savedStroke(step)];
  }

  // La flecha se reconstruye desde los códigos; el paso se guarda tal cual.
  _Stroke _savedStroke(SequenceStep step) => (
        key: _nextKey++,
        step: step,
        arrow: (
          originIndex: originIndexFor(step.side, step.ownZone),
          end: targetPositionFor(step.zone, step.direction),
        ),
      );

  void _onPanStart(DragStartDetails details) {
    final origin = originAt(details.localPosition, _table, _originTouchRadius);
    if (origin == null) return;
    setState(() => _dragging = (originIndex: origin, end: toTable(details.localPosition, _table)));
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final current = _dragging;
    if (current == null) return;
    setState(() => _dragging = (originIndex: current.originIndex, end: toTable(details.localPosition, _table)));
  }

  Future<void> _onPanEnd(DragEndDetails _) async {
    final released = _dragging;
    setState(() => _dragging = null);
    if (released == null) return;

    final target = snapTarget(released.end);
    if (target == null) return;

    final origin = strokeOrigins[released.originIndex];
    final choice = await showStrokePicker(context, ownZone: origin.ownZone);
    if (choice == null || !mounted) return;

    final step = SequenceStep(
      hit: choice.hit,
      rotation: choice.rotation,
      zone: target.zone,
      direction: target.direction,
      side: origin.side,
      ownZone: origin.ownZone,
    );
    // La flecha guardada termina en el destino, no donde se levantó el dedo.
    final arrow = (originIndex: released.originIndex, end: target.position);
    setState(() => _strokes = [..._strokes, (key: _nextKey++, step: step, arrow: arrow)]);
  }

  void _removeStroke(int index) {
    setState(() => _strokes = [..._strokes]..removeAt(index));
  }

  void _reorderStroke(int oldIndex, int newIndex) {
    // ReorderableListView da el destino contando todavía el golpe movido.
    final target = newIndex > oldIndex ? newIndex - 1 : newIndex;
    setState(() {
      final strokes = [..._strokes];
      strokes.insert(target, strokes.removeAt(oldIndex));
      _strokes = strokes;
    });
  }

  Future<void> _submit() async {
    final steps = [for (final s in _strokes) s.step];
    final review = widget.onReview;
    if (review != null) {
      final done = await review(steps);
      if (!done || !mounted) return;
    }
    Navigator.pop<List<SequenceStep>>(context, steps);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(flex: 3, child: _buildCanvas()),
            Expanded(flex: 2, child: _buildStrokeList()),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textWhite),
          onPressed: () => Navigator.pop(context),
        ),
        const Text('Secuencia', style: TextStyles.subTitle),
      ],
    );
  }

  Widget _buildCanvas() {
    return LayoutBuilder(
      builder: (context, constraints) {
        _table = tableRectFor(constraints.biggest);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          child: Stack(
            children: [
              Positioned.fromRect(rect: _table, child: const PingPongTable()),
              for (var i = 0; i < strokeOrigins.length; i++) _buildOrigin(i),
              Positioned.fill(child: CustomPaint(painter: _arrowsPainter())),
            ],
          ),
        );
      },
    );
  }

  StrokeArrowsPainter _arrowsPainter() {
    final dragging = _dragging;
    return StrokeArrowsPainter(
      table: _table,
      arrows: [for (final s in _strokes) s.arrow],
      dragging: dragging,
      snapped: dragging == null ? null : snapTarget(dragging.end),
    );
  }

  Widget _buildOrigin(int index) {
    const size = PlusButton.size;
    final center = toCanvas(strokeOrigins[index].position, _table);
    return Positioned(
      key: ValueKey('origin-$index'),
      left: center.dx - size / 2,
      top: center.dy - size / 2,
      child: const PlusButton(),
    );
  }

  Widget _buildStrokeList() {
    if (_strokes.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'Arrastra desde un + de tu lado hasta un punto del campo del rival',
            style: TextStyles.paragraph,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      buildDefaultDragHandles: false,
      proxyDecorator: (_, i, __) => draggedRowBackground(_buildStrokeRow(i, dragging: true)),
      itemCount: _strokes.length,
      onReorder: _reorderStroke,
      itemBuilder: (context, i) => _buildStrokeRow(i),
    );
  }

  Widget _buildStrokeRow(int i, {bool dragging = false}) {
    final foreground = rowForeground(dragging: dragging);
    return ListTile(
      key: ValueKey(_strokes[i].key),
      dense: true,
      leading: ReorderableDragStartListener(
        index: i,
        child: Icon(Icons.drag_handle, color: dragging ? foreground : AppColors.textGray),
      ),
      title: Text(
        '${i + 1}. ${describeStep(_strokes[i].step)}',
        style: TextStyles.paragraph.copyWith(color: foreground),
      ),
      trailing: IconButton(
        icon: Icon(Icons.close, color: dragging ? foreground : AppColors.textGray),
        tooltip: 'Quitar golpe ${i + 1}',
        onPressed: () => _removeStroke(i),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textBlack,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
        ),
        onPressed: _strokes.isEmpty ? null : _submit,
        child: const Text('Subir y ver', style: TextStyles.buttons),
      ),
    );
  }
}
