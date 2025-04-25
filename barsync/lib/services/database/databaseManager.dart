import 'package:barsync/models/categoryModel.dart';
import 'package:barsync/models/restaurantModel.dart';
import 'package:barsync/models/userModel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Users
Future<void> saveUser(UserModel user) async {
  if (user.email.isEmpty || user.password.isEmpty || user.rol.isEmpty) {
    throw Exception('Email, contraseña y rol son obligatorios.');
  }

  await FirebaseFirestore.instance.collection('users').add(user.toJson());
}

Future<void> saveUserWithRestaurant(
  UserModel user,
  DocumentReference restaurantRef,
) async {
  user.idRestaurante = restaurantRef.id;

  final userRef = FirebaseFirestore.instance.collection('users').doc();
  user.id = userRef.id;

  await userRef.set(user.toJson());
}

Stream<List<UserModel>> getUsers() {
  return FirebaseFirestore.instance
      .collection('users')
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs.map((doc) => UserModel.fromJson(doc.data())).toList(),
      );
}

Stream<List<UserModel>> getUsersByEmail(String email) {
  return FirebaseFirestore.instance
      .collection('users')
      .where('email', isEqualTo: email)
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs.map((doc) => UserModel.fromJson(doc.data())).toList(),
      );
}

Future<List<UserModel>> getUsersByRestaurantAndRole(
  String idRestaurante,
  String rol,
) async {
  try {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('usuarios')
            .where('idRestaurante', isEqualTo: idRestaurante)
            .where('rol', isEqualTo: rol)
            .get();

    return snapshot.docs.map((doc) => UserModel.fromJson(doc.data())).toList();
  } catch (e) {
    print("Error al obtener usuarios: $e");
    return [];
  }
}

// Restaurants
Stream<List<RestaurantModel>> getRestaurants() {
  return FirebaseFirestore.instance
      .collection('restaurants')
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs
                .map((doc) => RestaurantModel.fromJson(doc.data()))
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
                .map((doc) => RestaurantModel.fromJson(doc.data()))
                .toList(),
      );
}

Future<String> saveRestaurant(RestaurantModel restaurant) async {
  try {
    final docRef = FirebaseFirestore.instance.collection('restaurants').doc();
    restaurant.id = docRef.id; // Asignamos el ID al modelo
    await docRef.set(restaurant.toJson());
    return docRef.id;
  } catch (e) {
    print("Error al guardar restaurante: $e");
    rethrow;
  }
}

Future<void> updateUsersRestaurant(
  DocumentReference idRestaurante,
  List<UserModel> users,
) async {
  final firestore = FirebaseFirestore.instance;
  try {
    final restaurantDoc = idRestaurante;
    print("Referencia restaurante: $restaurantDoc");

    List<DocumentReference> camareroRefs = [];
    List<DocumentReference> cocineroRefs = [];

    for (UserModel user in users) {
      final userId = user.id?.trim();

      if (userId == null || userId.isEmpty) {
        print('❌ Usuario sin ID válido: ${user.toJson()}');
        continue; // Saltamos este usuario
      }

      final userRef = firestore.collection('users').doc(userId);
      final rol = user.rol.trim().toLowerCase();

      if (rol == 'waiter') {
        camareroRefs.add(userRef);
      } else if (rol == 'cooker') {
        cocineroRefs.add(userRef);
      } else {
        print('⚠️ Rol desconocido: $rol');
      }
    }

    // Opcional: Asegurarse de que los campos existen
    await restaurantDoc.set({
      'waiters': [],
      'cookers': [],
    }, SetOptions(merge: true));

    // Actualizamos el restaurante con las referencias a los usuarios
    await restaurantDoc.update({
      'waiters': FieldValue.arrayUnion(camareroRefs),
      'cookers': FieldValue.arrayUnion(cocineroRefs),
    });

    print('Referencias de usuarios añadidas al restaurante correctamente.');
  } catch (e) {
    print('Error al actualizar el restaurante: $e');
  }
}

// Categoria

Future<void> addCategory(CategoryModel category) async {
  try {
    final categoryData = {
      'name': category.name,
      'description': category.description,
      'image': category.image,
      'restaurant': FirebaseFirestore.instance
          .collection('restaurants')
          .doc(category.idRestaurant),
      'products': [], // inicial vacío
    };

    // Añadir la categoría
    final docRef = await FirebaseFirestore.instance
        .collection('categories')
        .add(categoryData);

    // Actualizar el mismo documento con su propio ID
    await docRef.update({'id': docRef.id});

    print('✅ Categoría añadida con ID: ${docRef.id}');
  } catch (e) {
    print('❌ Error al añadir categoría: $e');
    rethrow;
  }
}

Future<CategoryModel?> getCategoryById(String categoryId) async {
  try {
    final doc =
        await FirebaseFirestore.instance
            .collection('categories')
            .doc(categoryId)
            .get();

    if (!doc.exists) {
      print('❗ Categoría no encontrada');
      return null;
    }

    final data = doc.data()!;
    final category = CategoryModel.fromJson(data)..id = doc.id;

    return category;
  } catch (e) {
    print('❌ Error al obtener categoría por ID: $e');
    rethrow;
  }
}
