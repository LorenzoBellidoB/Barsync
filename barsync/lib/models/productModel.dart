import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  String id;
  String name;
  String image;
  String description;
  List<String> eatTimes;
  List<String> addOns;
  Map<String, double> prices;
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
    this.prices = const {},
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
      'restaurant': idRestaurant,
      'id_category': idCategory,
    };
  }

  // Crear objeto desde JSON (desde Firebase)
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final rawPrices = json['prices'] as Map<String, dynamic>? ?? {};
    final prices = rawPrices.map(
      (key, value) => MapEntry(key, (value as num).toDouble()),
    );

    return ProductModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      image: json['image'] ?? '',
      addOns:
          (json['add_ons'] as List?)?.map((e) => e as String).toList() ?? [],
      eatTimes:
          (json['eat_times'] as List?)?.map((e) => e as String).toList() ?? [],
      prices: prices,
      idRestaurant:
          json['restaurant'] is DocumentReference
              ? json['restaurant']
              : FirebaseFirestore.instance.doc(json['restaurant'] ?? ''),
      idCategory:
          json['id_category'] is DocumentReference
              ? json['id_category']
              : FirebaseFirestore.instance.doc(json['id_category'] ?? ''),
    );
  }

  // JSON sin referencias completas
  Map<String, dynamic> toJsonWithoutReferences() {
    return {
      'name': name,
      'description': description,
      'image': image,
      'prices': prices,
      'restaurant': idRestaurant.id,
      'id_category': idCategory.id,
    };
  }

  // Crear objeto desde JSON sin referencias completas
  factory ProductModel.fromJsonWithoutReferences(Map<String, dynamic> json) {
    final rawPrices = json['prices'] as Map<String, dynamic>? ?? {};
    final prices = rawPrices.map(
      (key, value) => MapEntry(key, (value as num).toDouble()),
    );

    return ProductModel(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      image: json['image'] ?? '',
      prices: prices,
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
    Map<String, double>? prices,
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

  /// Crea un `ProductModel` a partir de un documento Firestore.
  ///
  /// Extrae los campos necesarios del documento, usando valores por
  /// defecto si algún campo falta, y convierte tipos según corresponda.
  /// Devuelve una instancia con los datos del producto.
  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductModel(
      id: doc.id,
      name: data['name'] ?? '',
      image: data['image'] ?? '',
      description: data['description'] ?? '',
      eatTimes: List<String>.from(data['eat_times'] ?? []),
      addOns: List<String>.from(data['add_ons'] ?? []),
      prices: Map<String, double>.from(
        (data['prices'] ?? {}).map(
          (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
        ),
      ),
      idRestaurant: data['restaurant'],
      idCategory: data['id_category'],
    );
  }
}
