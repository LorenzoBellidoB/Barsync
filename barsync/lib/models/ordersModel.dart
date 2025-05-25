import 'package:barsync/models/productOrderModel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  String id;
  String state;
  Timestamp time;
  List<ProductOrderModel> products;
  DocumentReference table;
  DocumentReference idRestaurant;
  DocumentReference waiter;

  OrderModel({
    required this.id,
    required this.state,
    required this.time,
    required this.products,
    required this.table,
    required this.idRestaurant,
    required this.waiter,
  });

  // Convertir objeto a JSON (para Firebase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'state': state,
      'time': time,
      'products': products.map((p) => p.toJson()).toList(),
      'table': table,
      'restaurant': idRestaurant,
      'waiter': waiter,
    };
  }

  // Crear objeto desde JSON (desde Firebase)
  factory OrderModel.fromJson(Map<String, dynamic> json, String id) {
    return OrderModel(
      id: id,
      state: json['state'] ?? '',
      time: json['time'] as Timestamp,
      products:
          (json['products'] as List<dynamic>?)
              ?.map((item) => ProductOrderModel.fromJson(item))
              .toList() ??
          [],
      table:
          json['table'] is DocumentReference
              ? json['table']
              : FirebaseFirestore.instance.doc(json['table']),
      idRestaurant:
          json['restaurant'] is DocumentReference
              ? json['restaurant']
              : FirebaseFirestore.instance.doc(json['restaurant']),
      waiter: json['waiter'],
    );
  }

  // Convertir objeto a JSON (para Firebase)
  Map<String, dynamic> toJsonWithoutProducts() {
    return {'state': state, 'time': time, 'restaurant': idRestaurant};
  }

  // Crear objeto desde JSON (desde Firebase)
  factory OrderModel.fromJsonWithoutProducts(Map<String, dynamic> json) {
    return OrderModel(
      id: '',
      products: json['products'],
      table: json['table'],
      state: json['state'],
      time: json['time'],
      idRestaurant: json['restaurant'],
      waiter: json['waiter'],
    );
  }
}
