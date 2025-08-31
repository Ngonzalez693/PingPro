class Exercise {
  constructor({ name, category, image, isFavorite, description }) {
    this.name = name;
    this.category = category;
    this.image = image;
    this.isFavorite = isFavorite ?? false;
    this.description = description ?? '';
  }
}
module.exports = Exercise;
