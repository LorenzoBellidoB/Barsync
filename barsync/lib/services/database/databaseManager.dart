import 'package:barsync/models/restaurantModel.dart';
import 'package:barsync/models/userModel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Users
Future<void> saveUser(UserModel user) async {
  await FirebaseFirestore.instance
      .collection('users')
      .doc(user.id)
      .set(user.toJson());
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
      .collection('users')
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs
                .map((doc) => RestaurantModel.fromJson(doc.data(), doc.id))
                .toList(),
      );
}

Stream<List<Map<String, dynamic>>> getRestaurantsMap() {
  return FirebaseFirestore.instance
      .collection('users')
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs.map((doc) {
              final restaurant = RestaurantModel.fromJson(doc.data(), doc.id);
              return restaurant.toMap(); // Convertir a Map<String, dynamic>
            }).toList(),
      );
}

Future<void> saveRestaurant(RestaurantModel restaurant) async {
  await FirebaseFirestore.instance
      .collection('restaurants')
      .doc(restaurant.id)
      .set(restaurant.toJson());
}
