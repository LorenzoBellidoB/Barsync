import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  String? id;
  String name;
  String rol;
  String email;
  String password;
  Timestamp register_date;

  UserModel({
    required this.id,
    required this.name,
    required this.rol,
    required this.email,
    required this.password,
    required this.register_date,
  });

  UserModel.withoutId({
    required this.name,
    required this.rol,
    required this.email,
    required this.password,
    required this.register_date,
  }) : id = '';

  // Convertir objeto a JSON (para Firebase)
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'rol': rol,
      'email': email,
      'password': password,
      'register_date': register_date,
    };
  }

  // Crear objeto desde JSON sin id
  factory UserModel.fromJsonWithoutId(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      password: json['password'],
      rol: json['role'],
      register_date: json['register_date'],
    );
  }

  // Crear objeto desde JSON (desde Firebase)
  factory UserModel.fromJson(Map<String, dynamic> json, String? id) {
    return UserModel(
      id: id,
      name: json['name'],
      rol: json['rol'],
      email: json['email'],
      password: json['password'],
      register_date: json['register_date'],
    );
  }
}
