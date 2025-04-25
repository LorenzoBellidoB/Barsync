import 'package:barsync/models/productModel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel {
  String id = '';
  String name;
  String description = '';
  String image = '';
  List<ProductModel> products;
  String idRestaurant = '';

  CategoryModel({
    required this.name,
    required this.description,
    required this.image,
    this.products = const [],
    required this.idRestaurant,
  });

  // Convertir objeto a JSON (para Firebase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image': image,
      'products': products,
      'restaurant': idRestaurant,
    };
  }

  // Crear objeto desde JSON (desde Firebase)
  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      image: json['image'] ?? '',
      products: [], // se asignan luego, no aquí
      idRestaurant:
          (json['restaurant'] is DocumentReference)
              ? (json['restaurant'] as DocumentReference).id
              : json['restaurant'] ?? '',
    );
  }

  // Convertir objeto a JSON (para Firebase)
  Map<String, dynamic> toJsonWithoutProducts() {
    return {
      'name': name,
      'description': description,
      'image': image,
      'restaurant': idRestaurant,
    };
  }

  // Crear objeto desde JSON (desde Firebase)
  factory CategoryModel.fromJsonWithoutProducts(Map<String, dynamic> json) {
    return CategoryModel(
      name: json['name'],
      description: json['description'],
      image: json['image'],
      idRestaurant: json['restaurant'],
    );
  }
}
