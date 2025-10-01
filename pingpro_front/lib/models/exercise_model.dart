import 'package:pingpro_front/models/sequence_step_model.dart';

class ExerciseModel {
  final String id;
  final String name;
  final String category;
  final String image;
  bool isFavorite;
  final String description;
  final List<SequenceStep> sequence;
  DateTime? completedAt;

  ExerciseModel({
    required this.id,
    required this.name,
    required this.category,
    required this.image,
    this.isFavorite = false,
    required this.description,
    required this.sequence,
    this.completedAt,
  });

  factory ExerciseModel.fromJson(Map<String, dynamic> json) {
    return ExerciseModel(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      image: json['image'] as String,
      isFavorite: json['isFavorite'] as bool? ?? false,
      description: json['description'] as String? ?? '',
      sequence: (json['sequence'] as List<dynamic>?)
          ?.map((step) => SequenceStep.fromJson(step as Map<String, dynamic>))
          .toList() ?? [],
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'image': image,
    'isFavorite': isFavorite,
    'description': description,
    'sequence': sequence.map((step) => step.toJson()).toList(),
    'completedAt': completedAt?.toIso8601String(),
  };
}