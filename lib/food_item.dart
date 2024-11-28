class FoodItem {
  final int? id;
  final String name;
  final String category;
  final double price;

  FoodItem({this.id, required this.name, required this.category, required this.price});

  // Convert a FoodItem into a Map. The keys must correspond to the column names in the database.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'price': price,
    };
  }

  // A method to create a FoodItem from a Map (retrieved from the database)
  factory FoodItem.fromMap(Map<String, dynamic> map) {
    return FoodItem(
      id: map['id'],
      name: map['name'],
      category: map['category'],
      price: map['price'],
    );
  }
}
