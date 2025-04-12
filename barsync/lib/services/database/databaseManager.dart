import 'package:barsync/models/restaurantModel.dart';
import 'package:barsync/models/userModel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Users
Future<void> saveUser(UserModel user) async {
  final docRef = await FirebaseFirestore.instance
      .collection('users')
      .add(user.toJson());

  // Para obtener el id automatico de firebase
  await docRef.update({'id': docRef.id});
}

Stream<List<UserModel>> getUsers() {
  return FirebaseFirestore.instance
      .collection('users')
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs
                .map((doc) => UserModel.fromJson(doc.data(), doc.id))
                .toList(),
      );
}

Stream<List<UserModel>> getUsersByEmail(String email) {
  return FirebaseFirestore.instance
      .collection('users')
      .where('email', isEqualTo: email)
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs
                .map((doc) => UserModel.fromJson(doc.data(), doc.id))
                .toList(),
      );
}

// Restaurants
Stream<List<RestaurantModel>> getRestaurants() {
  return FirebaseFirestore.instance
      .collection('restaurants')
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs
                .map((doc) => RestaurantModel.fromJson(doc.data(), doc.id))
                .toList(),
      );
}

Stream<List<RestaurantModel>> getRestaurantByEmail(String email) {
  return FirebaseFirestore.instance
      .collection('restaurants')
      .where('emailBoss', isEqualTo: email)
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs
                .map((doc) => RestaurantModel.fromJson(doc.data(), doc.id))
                .toList(),
      );
}

Future<void> saveRestaurant(RestaurantModel restaurant) async {
  final docRef = await FirebaseFirestore.instance
      .collection('restaurants')
      .add(restaurant.toJson());

  // Si quieres actualizar el mismo documento para guardar el id dentro
  await docRef.update({'id': docRef.id});
}
