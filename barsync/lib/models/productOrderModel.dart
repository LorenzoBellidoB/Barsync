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
  String orderId;

  ProductOrderModel({
    this.id = '',
    required this.name,
    this.done = false,
    required this.idRestaurant,
    this.addOns = const [],
    this.price = const {},
    required this.idCategory,
    this.orderId = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'done': done,
      'add_ons': addOns,
      'price': price,
      'restaurant': idRestaurant,
      'id_category': idCategory,
      'orderId': orderId,
    };
  }

  factory ProductOrderModel.fromJson(Map<String, dynamic> json) {
    final rawprice = json['price'] as Map<String, dynamic>? ?? {};
    final price = rawprice.map(
      (key, value) => MapEntry(key, (value as num).toDouble()),
    );

    return ProductOrderModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      done: json['done'] ?? false,
      price: price,
      idRestaurant: getValidDocRef(json['restaurant'], 'restaurants/default'),
      idCategory: getValidDocRef(json['id_category'], 'categories/default'),
      orderId: json['orderId'] ?? '',
      addOns:
          (json['add_ons'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}
