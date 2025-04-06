import 'package:barsync/models/restaurantModel.dart';
import 'package:barsync/models/userModel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Users
Future<void> guardarUser(UserModel user) async {
  await FirebaseFirestore.instance
      .collection('users')
      .doc(user.id)
      .set(user.toJson());
}

Stream<List<UserModel>> obtenerUsers(String email) {
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
Future<void> guardarRestaurant(RestaurantModel restaurant) async {
  await FirebaseFirestore.instance
      .collection('restaurants')
      .doc(restaurant.id)
      .set(restaurant.toJson());
}
