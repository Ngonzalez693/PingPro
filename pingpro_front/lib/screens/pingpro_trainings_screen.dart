// Pestaña 4: catálogo de entrenamientos en cuadrícula de dos columnas.
//
// Filtra en memoria por categoría, igual que la pantalla de ejercicios. Aquí
// las categorías sí coinciden con las etiquetas visibles ('Grado', 'Objetivo',
// 'Momento', 'Estilo', 'Estructura') y con el desplegable de creación.
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/core/text_styles.dart';
import 'package:pingpro_front/models/training_model.dart';
import 'package:pingpro_front/widgets/choice_pill.dart';
import 'package:pingpro_front/widgets/skeleton_shimmer.dart';
import 'package:pingpro_front/widgets/staggered_entrance.dart';
import 'package:pingpro_front/widgets/training_card.dart';
import 'package:pingpro_front/widgets/training_card_skeleton.dart';
import 'package:pingpro_front/core/services/trainings_state.dart';

class PingproTrainingsScreen extends StatefulWidget {
  const PingproTrainingsScreen({super.key});
  @override
  State<PingproTrainingsScreen> createState() => _PingproTrainingsScreenState();
}

class _PingproTrainingsScreenState extends State<PingproTrainingsScreen> {
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    TrainingsState.instance.load();
  }

  void _onTabSelected(int index) {
    setState(() => _selectedTab = index);
  }

  List<TrainingModel> _applyFilter(List<TrainingModel> all) {
    return all.where((t) {
      if (_selectedTab == 1 && t.category != 'Grado') return false;
      if (_selectedTab == 2 && t.category != 'Objetivo') return false;
      if (_selectedTab == 3 && t.category != 'Momento') return false;
      if (_selectedTab == 4 && t.category != 'Estilo') return false;
      if (_selectedTab == 5 && t.category != 'Estructura') return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AnimatedBuilder(
        animation: TrainingsState.instance,
        builder: (context, _) {
          final s = TrainingsState.instance;

          if (s.error != null) {
            return Center(child: Text('Error: ${s.error}'));
          }

          final all = s.all;
          final filtered = _applyFilter(all);

          return Column(
            children: [
              // AppBar manual
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Entrenamientos',
                  style: TextStyles.title,
                  textAlign: TextAlign.center,
                ),
              ),

              // Tabs
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildTab('Todos', 0),
                      const SizedBox(width: 8),
                      _buildTab('Grado', 1),
                      const SizedBox(width: 8),
                      _buildTab('Objetivo', 2),
                      const SizedBox(width: 8),
                      _buildTab('Momento', 3),
                      const SizedBox(width: 8),
                      _buildTab('Estilo', 4),
                      const SizedBox(width: 8),
                      _buildTab('Estructura', 5),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Grid 2 columnas
              const SizedBox(height: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  // Título y pestañas se ven desde el principio; mientras
                  // carga, solo la cuadrícula es skeleton.
                  child: s.isLoading && !s.loadedOnce
                      ? _buildSkeletonGrid()
                      : _buildGrid(filtered),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static const _gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    crossAxisSpacing: 12,
    mainAxisSpacing: 12,
    childAspectRatio: 1.1,
  );

  Widget _buildGrid(List<TrainingModel> trainings) {
    return GridView.builder(
      itemCount: trainings.length,
      gridDelegate: _gridDelegate,
      itemBuilder: (context, i) {
        final t = trainings[i];
        return StaggeredEntrance(
          index: i,
          child: TrainingCard(
            training: t,
            onTap: () {
              Navigator.pushNamed(context, '/trainingDetail', arguments: t);
            },
          ),
        );
      },
    );
  }

  Widget _buildSkeletonGrid() {
    return SkeletonShimmer(
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 6,
        gridDelegate: _gridDelegate,
        itemBuilder: (_, __) => const TrainingCardSkeleton(),
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    return ChoicePill(
      label: label,
      selected: _selectedTab == index,
      onTap: () => _onTabSelected(index),
      width: 80,
      textStyle: _tabTextStyle,
    );
  }

  // Más chico que TextStyles.buttons: con 16 px "Estructura" no entra en 80.
  static const _tabTextStyle = TextStyle(
    color: AppColors.textBlack,
    fontWeight: FontWeight.bold,
  );
}
