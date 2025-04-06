import 'package:barsync/models/userModel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RestaurantModel {
  String id;
  String name;
  Timestamp date;
  bool state;
  String address;
  String phone;
  String email;
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
    required this.email,
    required this.password,
    required this.waiters,
    required this.cookers,
  });

  // Convertir objeto a JSON (para Firebase)
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'register_date': date,
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
      email: json['email'],
      password: json['password'],
      waiters: json['waiters'],
      cookers: json['cookers'],
      date: json['date'],
    );
  }
}
