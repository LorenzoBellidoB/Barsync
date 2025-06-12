import 'package:cloud_firestore/cloud_firestore.dart';

class BillModel {
  String id;
  DocumentReference table;
  DocumentReference idRestaurant;
  Timestamp startTime;
  Timestamp? endTime;
  List<DocumentReference> orderRefs;
  String state;
  double totalAmount;

  BillModel({
    this.id = '',
    required this.table,
    required this.idRestaurant,
    required this.startTime,
    this.endTime,
    this.orderRefs = const [],
    this.state = 'open',
    this.totalAmount = 0.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'table': table,
      'idRestaurant': idRestaurant,
      'startTime': startTime,
      'endTime': endTime,
      'orderRefs': orderRefs,
      'state': state,
      'totalAmount': totalAmount,
    };
  }

  factory BillModel.fromJson(Map<String, dynamic> json, String id) {
    return BillModel(
      id: id,
      table:
          json['table'] is DocumentReference
              ? json['table']
              : FirebaseFirestore.instance.doc(json['table']),
      idRestaurant:
          json['idRestaurant'] is DocumentReference
              ? json['idRestaurant']
              : FirebaseFirestore.instance.doc(json['idRestaurant']),
      startTime: json['startTime'] as Timestamp,
      endTime: json['endTime'] as Timestamp?,
      orderRefs:
          (json['orderRefs'] as List?)
              ?.map((e) => e as DocumentReference)
              .toList() ??
          [],
      state: json['state'] ?? 'open',
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
