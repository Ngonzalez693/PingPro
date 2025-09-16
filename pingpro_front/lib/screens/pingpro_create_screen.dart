// lib/screens/pingpro_create_screen.dart

import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/core/text_styles.dart';
import 'package:pingpro_front/widgets/pingpong_table.dart';

enum CreateType { exercises, trainings }

class PingproCreateScreen extends StatefulWidget {
  const PingproCreateScreen({super.key});

  @override
  State<PingproCreateScreen> createState() => _PingproCreateScreenState();
}

class _PingproCreateScreenState extends State<PingproCreateScreen> {
  CreateType _selectedType = CreateType.exercises;
  final TextEditingController _nameController = TextEditingController();

  void _onTypeSelected(CreateType type) {
    setState(() => _selectedType = type);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),

            // Header con tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTab('Ejercicios', CreateType.exercises),
                  ),
                  Expanded(
                    child: _buildTab('Entrenamientos', CreateType.trainings),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            if (_selectedType == CreateType.exercises) ...[
              // Mesa de ping pong con botones
              Expanded(
                child: Center(
                  child: const PingPongTable()
                )
              ),

              const SizedBox(height: 40),

              // Campo de nombre
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 100),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.textGray,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextField(
                    controller: _nameController,
                    style: TextStyles.paragraph,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: 'Nombrar ejercicio',
                      hintStyle: TextStyles.paragraph,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Botón continuar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Align(
                  alignment: Alignment.center,
                  child: GestureDetector(
                    onTap: () {
                      // TODO: continuar al siguiente paso
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.textGray,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward,
                        color: AppColors.textWhite,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ] else ...[
              // Vista para entrenamientos (por implementar)
              const Expanded(
                child: Center(
                  child: Text(
                    'Vista de entrenamientos por implementar',
                    style: TextStyles.paragraph,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, CreateType type) {
    final selected = _selectedType == type;
    return GestureDetector(
      onTap: () => _onTypeSelected(type),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyles.paragraph.copyWith(
              color: selected ? AppColors.textWhite : AppColors.textGray,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 2,
            color: selected ? AppColors.primary : AppColors.secundary,
          ),
        ],
      ),
    );
  }
}
