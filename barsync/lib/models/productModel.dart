import 'package:barsync/models/addOnsModel.dart';
import 'package:barsync/models/eatTimeModel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  String id = '';
  String name;
  String image = '';
  String description = '';
  List<EatTimeModel> eatTimes;
  List<AddOnsModel> addOns;
  List<double> prices;
  String idRestaurant = '';
  String idCategory = '';

  ProductModel({
    required this.name,
    this.image = '',
    this.description = '',
    required this.idRestaurant,
    this.addOns = const [],
    this.eatTimes = const [],
    this.prices = const [],
    this.idCategory = '',
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
    return ProductModel(
      name: json['name'],
      description: json['description'] ?? '',
      image: json['image'] ?? '',
      addOns:
          (json['addOns'] != null && json['addOns'] is List)
              ? (json['addOns'] as List<dynamic>)
                  .map(
                    (item) =>
                        AddOnsModel.fromJson(item as Map<String, dynamic>),
                  )
                  .toList()
              : [],
      eatTimes:
          (json['eat_times'] != null && json['eat_times'] is List)
              ? (json['eat_times'] as List<dynamic>)
                  .map(
                    (item) =>
                        EatTimeModel.fromJson(item as Map<String, dynamic>),
                  )
                  .toList()
              : [],
      prices:
          (json['prices'] != null && json['prices'] is List)
              ? (json['prices'] as List)
                  .map((item) => (item as num).toDouble())
                  .toList()
              : [],
      idRestaurant:
          (json['restaurant'] is DocumentReference)
              ? (json['restaurant'] as DocumentReference).id
              : json['restaurant'] ?? '',
      idCategory:
          (json['id_category'] is DocumentReference)
              ? (json['id_category'] as DocumentReference).id
              : json['id_category'] ?? '',
    );
  }

  // Convertir objeto a JSON (para Firebase)
  Map<String, dynamic> toJsonWithoutReferences() {
    return {
      'name': name,
      'description': description,
      'image': image,
      'restaurant': idRestaurant,
    };
  }

  // Crear objeto desde JSON (desde Firebase)
  factory ProductModel.fromJsonWithoutReferences(Map<String, dynamic> json) {
    return ProductModel(
      name: json['name'],
      description: json['description'],
      image: json['image'],
      idRestaurant: json['restaurant'],
    );
  }
}
