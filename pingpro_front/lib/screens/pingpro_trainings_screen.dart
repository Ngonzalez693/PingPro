import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/core/services/training_services.dart';
import 'package:pingpro_front/core/text_styles.dart';
import 'package:pingpro_front/models/training_model.dart';
import 'package:pingpro_front/widgets/training_card.dart';

class PingproTrainingsScreen extends StatefulWidget {
  const PingproTrainingsScreen({super.key});
  @override
  State<PingproTrainingsScreen> createState() => _PingproTrainingsScreenState();
}

class _PingproTrainingsScreenState extends State<PingproTrainingsScreen> {
  final _service = TrainingsService();
  late List<TrainingModel> _allTrainings;
  List<TrainingModel> _filtered = [];
  bool _loading = true;
  String _error = '';
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _loadTrainings();
  }

  Future<void> _loadTrainings() async {
    try {
      _allTrainings = await _service.fetchAll();
      _applyFilter();
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    _filtered =
        _allTrainings.where((t) {
          if (_selectedTab == 1 && t.category != 'Grado') return false;
          if (_selectedTab == 2 && t.category != 'Objetivo') return false;
          if (_selectedTab == 3 && t.category != 'Momento') return false;
          if (_selectedTab == 4 && t.category != 'Estilo') return false;
          if (_selectedTab == 5 && t.category != 'Estructura') return false;
          return true;
        }).toList();
  }

  void _onTabSelected(int index) {
    _selectedTab = index;
    _applyFilter();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error.isNotEmpty) return Center(child: Text('Error: $_error'));

    return SafeArea(
      child: Column(
        // AppBar manual
        children: [
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
                  _buildTab('All', 0),
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

          // Lista 2 Columnas
          const SizedBox(height: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                itemCount: _filtered.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.1,
                ),
                itemBuilder: (context, i) {
                  final t = _filtered[i];
                  return TrainingCard(
                    training: t,
                    onTap: () {
                      // navegar a detalle
                    },
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
    final selected = _selectedTab == index;
    return GestureDetector(
      onTap: () => _onTabSelected(index),
      child: Container(
        width: 80, // ancho fijo para cada tab, ajusta según necesites
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
    );
  }
}
