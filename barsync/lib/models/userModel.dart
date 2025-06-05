import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  String id;
  String name;
  String rol;
  String email;
  String fcmToken;
  bool first_pass = true;
  Timestamp register_date;
  DocumentReference<Object?> idRestaurante;

  UserModel({
    required this.id,
    required this.name,
    required this.rol,
    required this.email,
    required this.fcmToken,
    this.first_pass = true,
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
      'fcmToken': fcmToken,
      'first_pass': first_pass,
      'register_date': register_date,
      'idRestaurante': idRestaurante,
    };
  }

  // Creo una copia modificada de un user existente
  UserModel copyWith({
    String? id,
    String? name,
    String? rol,
    String? email,
    String? fcmToken,
    bool? first_pass,
    Timestamp? register_date,
    DocumentReference<Object?>? idRestaurante,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      rol: rol ?? this.rol,
      email: email ?? this.email,
      fcmToken: fcmToken ?? this.fcmToken,
      first_pass: first_pass ?? this.first_pass,
      register_date: register_date ?? this.register_date,
      idRestaurante: idRestaurante ?? this.idRestaurante,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json, String docId) {
    final rawRef = json['idRestaurante'];

    if (rawRef == null || rawRef is! DocumentReference) {
      print("❌ idRestaurante inválido: $rawRef");
    } else {
      print("✅ idRestaurante correcto: $rawRef");
    }

    return UserModel(
      id: docId,
      name: json['name'] ?? '',
      rol: json['rol'] ?? '',
      email: json['email'] ?? '',
      fcmToken: json['fcmToken'] ?? '',
      first_pass: json['first_pass'] ?? true,
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
