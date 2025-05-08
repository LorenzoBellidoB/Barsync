import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  String id = '';
  String name;
  String image = '';
  String description = '';
  List<String> eatTimes;
  List<String> addOns;
  List<double> prices;
  DocumentReference<Object?> idRestaurant;
  DocumentReference<Object?> idCategory;

  ProductModel({
    this.id = '',
    required this.name,
    this.image = '',
    this.description = '',
    required this.idRestaurant,
    this.addOns = const [],
    this.eatTimes = const [],
    this.prices = const [],
    required this.idCategory,
  });

  // Convertir objeto a JSON (para Firebase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image': image,
      'add_ons': addOns,
      'eat_times': eatTimes,
      'prices': prices,
      'restaurant': idRestaurant, // Aquí mantenemos la referencia
      'id_category': idCategory, // Aquí mantenemos la referencia
    };
  }

  // Crear objeto desde JSON (desde Firebase)
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      image: json['image'] ?? '',
      addOns:
          (json['addOns'] != null && json['addOns'] is List)
              ? (json['addOns'] as List<dynamic>)
                  .map((item) => item as String)
                  .toList()
              : [],
      eatTimes:
          (json['eat_times'] != null && json['eat_times'] is List)
              ? (json['eat_times'] as List<dynamic>)
                  .map((item) => item as String)
                  .toList()
              : [],
      prices:
          (json['prices'] != null && json['prices'] is List)
              ? (json['prices'] as List)
                  .map((item) => (item as num).toDouble())
                  .toList()
              : [],
      // Cambiar esta parte para que maneje DocumentReference correctamente
      idRestaurant:
          json['restaurant'] is DocumentReference
              ? json['restaurant'] as DocumentReference<Object?>
              : FirebaseFirestore.instance.doc(json['restaurant'] ?? ''),
      idCategory:
          json['id_category'] is DocumentReference
              ? json['id_category'] as DocumentReference<Object?>
              : FirebaseFirestore.instance.doc(json['id_category'] ?? ''),
    );
  }

  // Convertir objeto a JSON sin las referencias completas (solo los datos necesarios)
  Map<String, dynamic> toJsonWithoutReferences() {
    return {
      'name': name,
      'description': description,
      'image': image,
      'restaurant':
          idRestaurant.id, // Solo enviamos el ID, no la referencia completa
    };
  }

  // Crear objeto desde JSON (sin referencias completas, solo con el ID)
  factory ProductModel.fromJsonWithoutReferences(Map<String, dynamic> json) {
    return ProductModel(
      name: json['name'],
      description: json['description'],
      image: json['image'],
      idRestaurant: FirebaseFirestore.instance.doc(json['restaurant']),
      idCategory: FirebaseFirestore.instance.doc(json['id_category']),
    );
  }
  ProductModel copyWith({
    String? id,
    String? name,
    String? image,
    String? description,
    List<String>? eatTimes,
    List<String>? addOns,
    List<double>? prices,
    DocumentReference<Object?>? idRestaurant,
    DocumentReference<Object?>? idCategory,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      image: image ?? this.image,
      description: description ?? this.description,
      eatTimes: eatTimes ?? this.eatTimes,
      addOns: addOns ?? this.addOns,
      prices: prices ?? this.prices,
      idRestaurant: idRestaurant ?? this.idRestaurant,
      idCategory: idCategory ?? this.idCategory,
    );
  }
}
