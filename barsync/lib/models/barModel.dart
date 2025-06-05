import 'package:cloud_firestore/cloud_firestore.dart';

class BarModel {
  final String id;
  final Map<String, dynamic> location; // { 'x': double, 'y': double }
  final DocumentReference restaurant;
  final double width;
  final double height;
  final int rotation; // 0 ó 90

  BarModel({
    required this.id,
    required this.location,
    required this.restaurant,
    required this.width,
    required this.height,
    required this.rotation,
  });

  factory BarModel.fromJson(Map<String, dynamic> json) {
    return BarModel(
      id: json['id'] as String,
      location: Map<String, dynamic>.from(json['location'] as Map),
      restaurant: json['restaurant'] as DocumentReference,
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      rotation: (json['rotation'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'location': location,
      'restaurant': restaurant,
      'width': width,
      'height': height,
      'rotation': rotation,
    };
  }
}
