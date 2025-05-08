import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:barsync/models/userModel.dart';

class Session {
  static final Session _instance = Session._internal();
  factory Session() => _instance;
  Session._internal();

  late DocumentReference<Object?> restaurantRef;
  late String idRestaurant;
  late UserModel currentUser;

  void setRestaurant(DocumentReference<Object?> ref) {
    restaurantRef = ref;
    idRestaurant = ref.id;
  }

  void setUser(UserModel user) {
    currentUser = user;
  }
}
