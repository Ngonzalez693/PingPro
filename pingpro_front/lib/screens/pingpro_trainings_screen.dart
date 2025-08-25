import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/core/text_styles.dart';
import 'package:pingpro_front/widgets/training_card.dart';

class PingproTrainingsScreen extends StatefulWidget {
  const PingproTrainingsScreen({super.key});

  @override
  State<PingproTrainingsScreen> createState() => _PingproTrainingsScreenState();
}

class _PingproTrainingsScreenState extends State<PingproTrainingsScreen> {
  int selectedTab = 0; // 0: All, 1: Regular, 2: Técnicos

  // Mock data — reemplazar por datos reales
  final List<Training> allTrainings = [
    Training(id: '1', type: 'Regular', imageUrl: 'assets/images/training_1.jpg'),
    Training(id: '2', type: 'Regular', imageUrl: 'assets/images/training_2.jpg'),
    Training(id: '3', type: 'Técnico', imageUrl: 'assets/images/training_3.jpg'),
    Training(id: '4', type: 'Regular', imageUrl: 'assets/images/training_1.jpg'),
    Training(id: '5', type: 'Técnico', imageUrl: 'assets/images/training_2.jpg'),
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = allTrainings.where((t) {
      if (selectedTab == 1 && t.type != 'Regular') return false;
      if (selectedTab == 2 && t.type != 'Técnico') return false;
      return true;
    }).toList();

    return SafeArea(
      child: Column(
        children: [
          // Título
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Text(
              'Entrenamientos',
              style: TextStyles.title,
              textAlign: TextAlign.center,
            ),
          ),

          // Pestañas
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildTab('All', 0),
                const SizedBox(width: 8),
                _buildTab('Regular', 1),
                const SizedBox(width: 8),
                _buildTab('Técnicos', 2),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Grid de trainings que maneja su propio scroll
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                itemCount: filtered.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 4, // separación entre filas
                  childAspectRatio: 0.75,
                ),
                itemBuilder: (context, i) {
                  final t = filtered[i];
                  final topPadding = i < 2 ? 12.0 : 0.0;
                  return Padding(
                    padding: EdgeInsets.only(top: topPadding),
                    child: TrainingCard(training: t, onTap: () {}),
                  );
                },
              ),
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