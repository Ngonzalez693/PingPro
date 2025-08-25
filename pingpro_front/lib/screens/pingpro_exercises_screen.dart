import 'package:flutter/material.dart';
import 'package:pingpro_front/widgets/exercise_card.dart';
import 'package:pingpro_front/widgets/custom_bottom_navigation.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/core/text_styles.dart';

class PingproExercisesScreen extends StatefulWidget {
  const PingproExercisesScreen({super.key});

  @override
  State<PingproExercisesScreen> createState() => _PingproExercisesScreenState();
}

class _PingproExercisesScreenState extends State<PingproExercisesScreen> {
  int selectedTab = 0; // 0: All, 1: Footwork, 2: Técnicos
  String searchQuery = '';
  List<Exercise> allExercises = [
    // Aquí irían tus ejercicios
  ];

  @override
  Widget build(BuildContext context) {
    // Filtrado por tab
    List<Exercise> filtered = allExercises.where((ex) {
      if (selectedTab == 1 && ex.category != 'Footwork') return false;
      if (selectedTab == 2 && ex.category != 'Técnicos') return false;
      if (searchQuery.isNotEmpty && !ex.name.toLowerCase().contains(searchQuery.toLowerCase())) return false;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Ejercicios', style: TextStyles.title),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              onChanged: (value) => setState(() => searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Buscar',
                prefixIcon: Icon(Icons.search, color: AppColors.secundary),
                filled: true,
                fillColor: AppColors.textGray,
                contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              style: TextStyle(color: AppColors.secundary),
            ),
          ),
          // Tabs personalizados
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _buildTabButton('All', 0),
                SizedBox(width: 8),
                _buildTabButton('Footwork', 1),
                SizedBox(width: 8),
                _buildTabButton('Técnicos', 2),
              ],
            ),
          ),
          // Lista de ejercicios
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                return ExerciseCard(
                  exercise: filtered[index],
                  onFavoritePressed: () {
                    setState(() {
                      filtered[index].isFavorite = !filtered[index].isFavorite;
                    });
                  },
                  onViewPressed: () {
                    // Acción al presionar "ver"
                  },
                  showTopDivider: index != 0,
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: 1, 
        onTap: (index) {
          // Navegación entre tabs
        },
      ),
    );
  }

  Widget _buildTabButton(String label, int tabIndex) {
    final bool selected = selectedTab == tabIndex;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedTab = tabIndex),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 8),
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
