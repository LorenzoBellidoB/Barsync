import 'package:barsync/utils/ref.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductOrderModel {
  String id;
  String name;
  bool done;
  List<String> addOns;
  Map<String, double> price;
  DocumentReference<Object?> idRestaurant;
  DocumentReference<Object?> idCategory;

  ProductOrderModel({
    this.id = '',
    required this.name,
    this.done = false,
    required this.idRestaurant,
    this.addOns = const [],
    this.price = const {},
    required this.idCategory,
  });

  // Convertir objeto a JSON (para Firebase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'done': done,
      'add_ons': addOns,
      'price': price,
      'restaurant': idRestaurant,
      'id_category': idCategory,
    };
  }

  // Crear objeto desde JSON (desde Firebase)
  factory ProductOrderModel.fromJson(Map<String, dynamic> json) {
    final rawprice = json['price'] as Map<String, dynamic>? ?? {};
    final price = rawprice.map(
      (key, value) => MapEntry(key, (value as num).toDouble()),
    );

    return ProductOrderModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      done: json['done'],
      price: price,
      idRestaurant: getValidDocRef(json['restaurant'], 'restaurants/default'),
      idCategory: getValidDocRef(json['id_category'], 'categories/default'),
      addOns:
          (json['add_ons'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}
