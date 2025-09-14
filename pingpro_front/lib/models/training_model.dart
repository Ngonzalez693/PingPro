class TrainingModel {
  final String id;
  final String name;
  final String category;
  final String image;
  final String description;
  final List<String> exerciseIds;
  final int duration;

  TrainingModel({
    required this.id,
    required this.name,
    required this.category,
    required this.image,
    required this.description,
    required this.exerciseIds,
    required this.duration,
  });

  factory TrainingModel.fromJson(Map<String, dynamic> json) {
    return TrainingModel(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      image: json['image'] as String,
      description: json['description'] as String? ?? '',
      exerciseIds: List<String>.from(json['exerciseIds'] as List<dynamic>),
      duration: json['duration'] as int? ?? 0,
    );
  }
}
