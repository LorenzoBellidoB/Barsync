import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  String id = '';
  String name;
  String rol;
  String email;
  String password;
  Timestamp register_date;
  DocumentReference<Object?> idRestaurante;

  UserModel({
    required this.id,
    required this.name,
    required this.rol,
    required this.email,
    required this.password,
    required this.register_date,
    required this.idRestaurante,
  });

  // Convertir objeto a JSON (para Firebase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'rol': rol,
      'email': email,
      'password': password,
      'register_date': register_date,
      'idRestaurante': idRestaurante,
    };
  }

  // Crear objeto desde JSON sin id
  // factory UserModel.fromJsonWithoutId(Map<String, dynamic> json) {
  //   return UserModel(
  //     name: json['name'],
  //     email: json['email'],
  //     password: json['password'],
  //     rol: json['role'],
  //     register_date: json['register_date'],
  //   );
  // }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final rawRef = json['idRestaurante'];

    if (rawRef == null || rawRef is! DocumentReference) {
      print("❌ idRestaurante inválido: $rawRef");
    } else {
      print("✅ idRestaurante correcto: $rawRef");
    }

    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      rol: json['rol'] ?? '',
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      register_date: json['register_date'],
      idRestaurante:
          rawRef is DocumentReference
              ? rawRef
              : FirebaseFirestore.instance.doc(
                '/restaurants/fallback',
              ), // fallback temporal
    );
  }
}
