// Pestaña 2: catálogo completo de ejercicios con buscador y filtro por
// categoría.
//
// El filtrado es en memoria sobre ExercisesState.all, no en el servidor: el
// catálogo es pequeño y ya está cargado, así que buscar es instantáneo.
//
// FRÁGIL: las categorías se comparan como texto literal ('Footwork',
// 'Técnico', 'Táctico', 'Estrategia') contra el campo `category` de Firestore.
// Un cambio de nombre o una tilde distinta deja la pestaña vacía sin avisar.
// Además las etiquetas visibles no coinciden con lo que se compara
// ('Técnicos' se muestra pero se filtra por 'Técnico').
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/core/text_styles.dart';
import 'package:pingpro_front/core/services/exercises_state.dart';
import 'package:pingpro_front/models/exercise_model.dart';
import 'package:pingpro_front/widgets/choice_pill.dart';
import 'package:pingpro_front/widgets/exercise_card.dart';
import 'package:pingpro_front/widgets/exercise_card_skeleton.dart';
import 'package:pingpro_front/widgets/skeleton_shimmer.dart';
import 'package:pingpro_front/widgets/staggered_entrance.dart';

class PingproExercisesScreen extends StatefulWidget {
  const PingproExercisesScreen({super.key});
  @override
  State<PingproExercisesScreen> createState() => _PingproExercisesScreenState();
}

class _PingproExercisesScreenState extends State<PingproExercisesScreen> {
  int _selectedTab = 0;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    ExercisesState.instance.load();
  }

  Future<void> _toggleFavorite(String id) async {
    try {
      await ExercisesState.instance.toggleFavorite(id);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error actualizando favorito')),
        );
      }
    }
  }

  void _onSearchChanged(String v) {
    setState(() => _searchQuery = v);
  }

  void _onTabSelected(int index) {
    setState(() => _selectedTab = index);
  }

  List<ExerciseModel> _applyFilter(List<ExerciseModel> all) {
    return all.where((ex) {
      // Tabs
      if (_selectedTab == 1 && ex.category != 'Footwork') return false;
      if (_selectedTab == 2 && ex.category != 'Técnico') return false;
      if (_selectedTab == 3 && ex.category != 'Táctico') return false;
      if (_selectedTab == 4 && ex.category != 'Estrategia') return false;

      // Search
      if (_searchQuery.isNotEmpty &&
          !ex.name.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // AppBar manual
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Ejercicios',
                    style: TextStyles.title,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

          // Buscar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Buscar',
                prefixIcon: Icon(Icons.search, color: AppColors.secundary),
                filled: true,
                fillColor: AppColors.textGray,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              style: TextStyle(color: AppColors.secundary),
            ),
          ),

          // Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTab('All', 0),
                  const SizedBox(width: 8),
                  _buildTab('Footwork', 1),
                  const SizedBox(width: 8),
                  _buildTab('Técnicos', 2),
                  const SizedBox(width: 8),
                  _buildTab('Tácticos', 3),
                  const SizedBox(width: 8),
                  _buildTab('Estrategia', 4),
                ],
              ),
            ),
          ),

          const SizedBox(height: 5),

          // Lista vertical
          Expanded(
            child: AnimatedBuilder(
              animation: ExercisesState.instance,
              builder: (context, _) {
                final s = ExercisesState.instance;

                if (s.isLoading && !s.loadedOnce) {
                  return SkeletonShimmer(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 6,
                      itemBuilder: (_, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ExerciseCardSkeleton(showTopDivider: i != 0),
                      ),
                    ),
                  );
                }
                if (s.error != null) {
                  return Center(child: Text('Error: ${s.error}'));
                }

                final all = s.all;
                final filtered = _applyFilter(all);

                if (filtered.isEmpty) {
                  return const Center(child: Text('No hay ejercicios'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final ex = filtered[i];
                    return StaggeredEntrance(
                      index: i,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ExerciseCard(
                          exercise: ex,
                          showTopDivider: i != 0,
                          onFavoritePressed: () => _toggleFavorite(ex.id),
                          onViewPressed: () {
                            Navigator.pushNamed(
                              context,
                              '/exerciseDetail',
                              arguments: {
                                'exercise': ex,
                                'returnRoute': '/exercises',
                              },
                            );
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    return ChoicePill(
      label: label,
      selected: _selectedTab == index,
      onTap: () => _onTabSelected(index),
      width: 100,
      textStyle: _tabTextStyle,
    );
  }

  // Más chico que TextStyles.buttons: con 16 px no entran en el ancho fijo.
  static const _tabTextStyle = TextStyle(
    color: AppColors.textBlack,
    fontWeight: FontWeight.bold,
  );
}
