// Creación de ejercicios y entrenamientos.
//
// Solo elige qué se crea. Cada formulario vive en su widget:
//   - widgets/create_exercise_form.dart
//   - widgets/create_training_form.dart
//
// Se usa de dos formas, según `scope`:
//   - own: la pestaña 3 de la barra inferior. Lo creado es privado.
//   - catalog: el acceso de admin desde el perfil. Lo creado va al catálogo y
//     lo ve todo el mundo; se abre encima del perfil, con flecha para volver.
//
// Los formularios van en un PageView: se cambia tocando la pestaña o
// deslizando, y la línea amarilla sigue a la página mientras se mueve.
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/core/text_styles.dart';
import 'package:pingpro_front/models/content_scope.dart';
import 'package:pingpro_front/widgets/create_exercise_form.dart';
import 'package:pingpro_front/widgets/create_training_form.dart';
import 'package:pingpro_front/widgets/keep_alive_page.dart';

enum CreateType { exercises, trainings }

class PingproCreateScreen extends StatefulWidget {
  final ContentScope scope;

  const PingproCreateScreen({super.key, this.scope = ContentScope.own});

  @override
  State<PingproCreateScreen> createState() => _PingproCreateScreenState();
}

class _PingproCreateScreenState extends State<PingproCreateScreen> {
  CreateType _selectedType = CreateType.exercises;
  final _pageController = PageController();

  bool get _isCatalog => widget.scope == ContentScope.catalog;

  void _onTabTapped(CreateType type) {
    if (MediaQuery.of(context).disableAnimations) {
      _pageController.jumpToPage(type.index);
      return;
    }
    _pageController.animateToPage(
      type.index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  void _onPageChanged(int index) {
    setState(() => _selectedType = CreateType.values[index]);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _isCatalog ? _buildCatalogHeader() : const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildTab('Ejercicios', CreateType.exercises)),
                      Expanded(child: _buildTab('Entrenamientos', CreateType.trainings)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildIndicator(),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // KeepAlivePage: cambiar de página no borra lo que ya se había
            // escrito en el otro formulario.
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                children: [
                  KeepAlivePage(child: CreateExerciseForm(scope: widget.scope)),
                  KeepAlivePage(child: CreateTrainingForm(scope: widget.scope)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCatalogHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textWhite),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(child: Text('Crear para el catálogo', style: TextStyles.title)),
        ],
      ),
    );
  }

  Widget _buildTab(String label, CreateType type) {
    final selected = _selectedType == type;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onTabTapped(type),
      child: Center(
        child: Text(
          label,
          style: TextStyles.paragraph.copyWith(
            color: selected ? AppColors.textWhite : AppColors.textGray,
          ),
        ),
      ),
    );
  }

  // Línea gris de fondo con el tramo amarillo encima. La posición sale de
  // `page`, que es fraccionaria mientras se desliza: así el tramo acompaña
  // al dedo en vez de saltar al soltar.
  Widget _buildIndicator() {
    return SizedBox(
      height: 2,
      child: Stack(
        children: [
          Container(color: AppColors.secundary),
          AnimatedBuilder(
            animation: _pageController,
            builder: (context, _) {
              final page = _pageController.hasClients
                  ? (_pageController.page ?? _selectedType.index.toDouble())
                  : _selectedType.index.toDouble();
              return Align(
                alignment: Alignment(-1 + 2 * page, 0),
                child: FractionallySizedBox(
                  widthFactor: 0.5,
                  child: Container(color: AppColors.primary),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
