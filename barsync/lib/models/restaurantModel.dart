import 'package:barsync/models/userModel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RestaurantModel {
  String id;
  String name;
  Timestamp date;
  bool state;
  String address;
  String phone;
  String emailBoss;
  String password;
  List<UserModel> waiters;
  List<UserModel> cookers;

  RestaurantModel({
    required this.id,
    required this.name,
    required this.date,
    required this.state,
    required this.address,
    required this.phone,
    required this.emailBoss,
    required this.password,
    this.waiters = const [],
    this.cookers = const [],
  });

  // Convertir objeto a JSON (para Firebase)
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'emailBoss': emailBoss,
      'date': date,
      'state': state,
      'address': address,
      'phone': phone,
      'password': password,
      'waiters': waiters,
      'cookers': cookers,
    };
  }

  // Crear objeto desde JSON (desde Firebase)
  factory RestaurantModel.fromJson(Map<String, dynamic> json, String id) {
    return RestaurantModel(
      id: id,
      name: json['name'],
      state: json['state'],
      address: json['address'],
      phone: json['phone'],
      emailBoss: json['emailBoss'],
      password: json['password'],
      waiters: json['waiters'],
      cookers: json['cookers'],
      date: json['date'],
    );
  }

  // Convertir objeto a JSON (para Firebase)
  Map<String, dynamic> toJsonWithoutUsers() {
    return {
      'name': name,
      'emailBoss': emailBoss,
      'date': date,
      'state': state,
      'address': address,
      'phone': phone,
      'password': password,
    };
  }

  // Crear objeto desde JSON (desde Firebase)
  factory RestaurantModel.fromJsonWithoutUsers(
    Map<String, dynamic> json,
    String id,
  ) {
    return RestaurantModel(
      id: id,
      name: json['name'],
      state: json['state'],
      address: json['address'],
      phone: json['phone'],
      emailBoss: json['emailBoss'],
      password: json['password'],
      date: json['date'],
    );
  }

  // Método para convertir un RestaurantModel en un Map
  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'state': state};
  }
}
