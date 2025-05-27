import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:barsync/models/userModel.dart';

class Session {
  // Singleton
  static final Session _instance = Session._internal();
  factory Session() => _instance;
  Session._internal();

  // Campos privados nulleables
  DocumentReference<Object?>? _restaurantRef;
  String? _idRestaurant;
  UserModel? _currentUser;

  // Getters seguros con validaciones
  DocumentReference<Object?> get restaurantRef {
    if (_restaurantRef == null) {
      throw Exception("restaurantRef no ha sido inicializado.");
    }
    return _restaurantRef!;
  }

  String get idRestaurant {
    if (_idRestaurant == null) {
      throw Exception("idRestaurant no ha sido inicializado.");
    }
    return _idRestaurant!;
  }

  UserModel get currentUser {
    if (_currentUser == null) {
      throw Exception("currentUser no ha sido inicializado.");
    }
    return _currentUser!;
  }

  // Setters
  void setRestaurant(DocumentReference<Object?> ref) {
    _restaurantRef = ref;
    _idRestaurant = ref.id;
  }

  void setUser(UserModel user) {
    _currentUser = user;
  }

  // Métodos de verificación opcionales
  bool get isLoggedIn => _currentUser != null;
  bool get hasRestaurant => _restaurantRef != null;
}
