import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/core/text_styles.dart';
import 'package:pingpro_front/widgets/exercise_card.dart';

class PingproExercisesScreen extends StatefulWidget {
  const PingproExercisesScreen({super.key});

  @override
  State<PingproExercisesScreen> createState() => _PingproExercisesScreenState();
}

class _PingproExercisesScreenState extends State<PingproExercisesScreen> {
  int selectedTab = 0; // 0: All, 1: Footwork, 2: Técnicos
  String searchQuery = '';

  // Mock data — reemplazar por datos reales
  final List<Exercise> allExercises = [
    Exercise(
      id: '1',
      name: 'Falkenberg',
      category: 'Footwork',
      imageUrl: 'assets/images/exercise_1.jpg',
      isFavorite: false,
    ),
    Exercise(
      id: '2',
      name: 'Tres Puntos',
      category: 'Footwork',
      imageUrl: 'assets/images/exercise_1.jpg',
      isFavorite: true,
    ),
    // Agregar más ejercicios aquí...
  ];

  @override
  Widget build(BuildContext context) {
    // Filtrado por pestaña y búsqueda
    final filtered = allExercises.where((ex) {
      if (selectedTab == 1 && ex.category != 'Footwork') return false;
      if (selectedTab == 2 && ex.category != 'Técnicos') return false;
      if (searchQuery.isNotEmpty &&
          !ex.name.toLowerCase().contains(searchQuery.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();

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
              onChanged: (v) => setState(() => searchQuery = v),
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
            child: Row(
              children: [
                _buildTab('All', 0),
                const SizedBox(width: 8),
                _buildTab('Footwork', 1),
                const SizedBox(width: 8),
                _buildTab('Técnicos', 2),
              ],
            ),
          ),

          // Lista de ejercicios
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: filtered.length,
              itemBuilder: (context, i) {
                final ex = filtered[i];
                return ExerciseCard(
                  exercise: ex,
                  showTopDivider: i != 0,
                  onFavoritePressed: () {
                    setState(() => ex.isFavorite = !ex.isFavorite);
                  },
                  onViewPressed: () {
                    // Navegar a detalle
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
    final selected = selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.secundary,
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.textBlack,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
