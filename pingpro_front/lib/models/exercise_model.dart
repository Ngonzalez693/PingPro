class ExerciseModel {
  final String id;
  final String name;
  final String category;
  final String image;
  bool isFavorite;
  final String description;

  ExerciseModel({
    required this.id,
    required this.name,
    required this.category,
    required this.image,
    this.isFavorite = false,
    required this.description,
  });

  factory ExerciseModel.fromJson(Map<String, dynamic> json) {
    return ExerciseModel(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      image: json['image'] as String,
      isFavorite: json['isFavorite'] as bool? ?? false,
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'image': image,
        'isFavorite': isFavorite,
        'description': description,
      };
}
