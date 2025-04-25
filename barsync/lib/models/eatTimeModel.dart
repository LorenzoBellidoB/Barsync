import 'package:cloud_firestore/cloud_firestore.dart';

class EatTimeModel {
  String id = '';
  String name;

  EatTimeModel({required this.id, required this.name});

  // Convertir objeto a JSON (para Firebase)
  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }

  // Crear objeto desde JSON sin id
  // factory EatTimeModel.fromJsonWithoutId(Map<String, dynamic> json) {
  //   return EatTimeModel(
  //     name: json['name'],
  //     email: json['email'],
  //     password: json['password'],
  //     rol: json['role'],
  //     register_date: json['register_date'],
  //   );
  // }

  // Crear objeto desde JSON (desde Firebase)
  factory EatTimeModel.fromJson(Map<String, dynamic> json) {
    return EatTimeModel(id: json['id'], name: json['name']);
  }
}
