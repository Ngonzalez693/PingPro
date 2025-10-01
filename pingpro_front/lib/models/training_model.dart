class TrainingModel {
  final String id;
  final String name;
  final String category;
  final String image;
  final String description;
  final List<String> exerciseIds;
  final int duration;
  DateTime? completedAt;

  TrainingModel({
    required this.id,
    required this.name,
    required this.category,
    required this.image,
    required this.description,
    required this.exerciseIds,
    required this.duration,
    this.completedAt,
  });

  factory TrainingModel.fromJson(Map<String, dynamic> json) {
    return TrainingModel(
      id: json['id'] ?? json['_id'],
      name: json['name'],
      category: json['category'] ?? '',
      image: json['image'] as String,
      description: json['description'] ?? '',
      exerciseIds: (json['exerciseIds'] as List).cast<String>(),
      duration: (json['duration'] ?? 0) as int,
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.tryParse(json['completedAt']),
    );
  }
}
