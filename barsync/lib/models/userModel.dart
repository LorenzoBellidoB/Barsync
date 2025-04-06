import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  String id;
  String name;
  String rol;
  String email;
  Timestamp register_date;

  UserModel({
    required this.id,
    required this.name,
    required this.rol,
    required this.email,
    required this.register_date,
  });

  // Convertir objeto a JSON (para Firebase)
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'rol': rol,
      'email': email,
      'register_date': register_date,
    };
  }

  // Crear objeto desde JSON (desde Firebase)
  factory UserModel.fromJson(Map<String, dynamic> json, String id) {
    return UserModel(
      id: id,
      name: json['name'],
      rol: json['rol'],
      email: json['email'],
      register_date: json['register_date'],
    );
  }
}
