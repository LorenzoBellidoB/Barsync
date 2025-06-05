import 'package:cloud_firestore/cloud_firestore.dart';

class TableModel {
  String id;
  int number;
  int dinners;
  String state;
  String type;
  Map<String, double> location;
  DocumentReference idRestaurant;
  DocumentReference? waiter;
  DocumentReference? currentOrder;

  TableModel({
    this.id = '',
    required this.number,
    this.dinners = 0,
    this.state = 'libre',
    required this.type,
    required this.location,
    required this.idRestaurant,
    this.waiter,
    this.currentOrder,
  });

  factory TableModel.fromJson(Map<String, dynamic> json) {
    final loc =
        (json['location'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        ) ??
        {};
    return TableModel(
      id: json['id'] ?? '',
      number: json['number'] ?? 0,
      dinners: json['dinners'] ?? 0,
      state: json['state'] ?? 'libre',
      type: json['type'] ?? 'mesa',
      location: loc,
      idRestaurant: json['restaurant'],
      waiter: json['waiter'],
      currentOrder: json['currentOrder'],
    );
  }

  Map<String, dynamic> toJson() {
    final data = {
      'number': number,
      'dinners': dinners,
      'state': state,
      'type': type,
      'location': location,
      'restaurant': idRestaurant,
      'waiter': waiter,
    };
    if (currentOrder != null) data['currentOrder'] = currentOrder;
    return data;
  }
}
