import 'package:barsync/models/categoryModel.dart';
import 'package:barsync/models/ordersModel.dart';
import 'package:barsync/models/productModel.dart';
import 'package:barsync/models/productOrderModel.dart';
import 'package:barsync/models/restaurantModel.dart';
import 'package:barsync/models/tableModel.dart';
import 'package:barsync/models/userModel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Users

DocumentReference<Object?> getUserById(UserModel user) {
  return FirebaseFirestore.instance.collection('users').doc(user.id);
}

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
  print(
    "👀 Guardando usuario con restaurante: ${user.idRestaurante.runtimeType}",
  );
  user.idRestaurante = restaurantRef;

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
  DocumentReference idRestaurante,
  String rol,
) async {
  try {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('users') // <- asegurarse que es 'users'
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
      final userId = user.id.trim();

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
          .doc(category.idRestaurant.id),
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
    final category = CategoryModel.fromJson(data, doc.id);

    return category;
  } catch (e) {
    print('❌ Error al obtener categoría por ID: $e');
    rethrow;
  }
}

Future<DocumentReference> addProduct(ProductModel product) async {
  try {
    final docRef = FirebaseFirestore.instance.collection('products').doc();
    product.id = docRef.id; // Asignamos el ID al modelo
    await docRef.set(product.toJson());
    return docRef;
  } catch (e) {
    print("Error al guardar restaurante: $e");
    rethrow;
  }
}

Future<bool> deleteProduct(ProductModel producto) async {
  bool res = false;
  try {
    final productRef = FirebaseFirestore.instance
        .collection('products')
        .doc(producto.id);

    await productRef.delete();

    final categoryRef = producto.idCategory;

    await categoryRef.update({
      'products': FieldValue.arrayRemove([productRef]),
    });
    res = true;
    return res;
  } catch (e) {
    print('Error al eliminar el producto: $e');
    return res;
  }
}

Future<bool> updateProduct(ProductModel producto) async {
  try {
    final productRef = FirebaseFirestore.instance
        .collection('products')
        .doc(producto.id);
    await productRef.update(producto.toJson());
    return true;
  } catch (e) {
    print('Error al actualizar producto: $e');
    return false;
  }
}

Stream<List<OrderModel>> listenToOrdersPending(
  DocumentReference restaurantRef,
) {
  return FirebaseFirestore.instance
      .collection('orders')
      .where('restaurant', isEqualTo: restaurantRef)
      .where('state', isNotEqualTo: 'listo')
      .orderBy('state')
      .snapshots()
      .asyncMap((snapshot) async {
        List<OrderModel> fetchedOrders = [];

        for (var doc in snapshot.docs) {
          var data = doc.data();
          List<ProductOrderModel> productsList = [];

          if (data['products'] != null && data['products'] is List) {
            for (var ref in (data['products'] as List)) {
              if (ref is DocumentReference) {
                try {
                  final productOrderDoc = await ref.get();
                  if (productOrderDoc.exists) {
                    final productOrderData =
                        productOrderDoc.data() as Map<String, dynamic>;
                    productsList.add(
                      ProductOrderModel.fromJson(productOrderData),
                    );
                  }
                } catch (e) {
                  print('Error al obtener producto de orden: $e');
                }
              }
            }
          }

          final restaurantRef = data['restaurant'];
          if (restaurantRef is! DocumentReference) {
            throw Exception('El campo "restaurant" no es válido.');
          }

          fetchedOrders.add(
            OrderModel(
              id: doc.id,
              time: data['time'],
              table: data['table'],
              state: data['state'],
              products: productsList,
              idRestaurant: restaurantRef,
              waiter: data['waiter'],
            ),
          );
        }

        return fetchedOrders;
      });
}

Stream<List<OrderModel>> listenToOrdersReady(DocumentReference restaurantRef) {
  return FirebaseFirestore.instance
      .collection('orders')
      .where('restaurant', isEqualTo: restaurantRef)
      .where('state', isEqualTo: 'listo')
      .orderBy('state')
      .snapshots()
      .asyncMap((snapshot) async {
        List<OrderModel> fetchedOrders = [];

        for (var doc in snapshot.docs) {
          var data = doc.data();
          List<ProductOrderModel> productsList = [];

          if (data['products'] != null && data['products'] is List) {
            for (var ref in (data['products'] as List)) {
              if (ref is DocumentReference) {
                try {
                  final productOrderDoc = await ref.get();
                  if (productOrderDoc.exists) {
                    final productOrderData =
                        productOrderDoc.data() as Map<String, dynamic>;
                    productsList.add(
                      ProductOrderModel.fromJson(productOrderData),
                    );
                  }
                } catch (e) {
                  print('Error al obtener producto de orden: $e');
                }
              }
            }
          }

          final restaurantRef = data['restaurant'];
          if (restaurantRef is! DocumentReference) {
            throw Exception('El campo "restaurant" no es válido.');
          }

          fetchedOrders.add(
            OrderModel(
              id: doc.id,
              time: data['time'],
              table: data['table'],
              state: data['state'],
              products: productsList,
              idRestaurant: restaurantRef,
              waiter: data['waiter'],
            ),
          );
        }

        return fetchedOrders;
      });
}

Stream<List<CategoryModel>> listenToCategories(
  DocumentReference restaurantRef,
) {
  return FirebaseFirestore.instance
      .collection('categories')
      .where('restaurant', isEqualTo: restaurantRef)
      .snapshots()
      .asyncMap((snapshot) async {
        List<CategoryModel> fetchedCategories = [];

        for (var doc in snapshot.docs) {
          final data = doc.data();

          List<ProductModel> productsList = [];

          if (data['products'] != null && data['products'] is List) {
            for (var ref in (data['products'] as List<dynamic>)) {
              if (ref is DocumentReference) {
                final productDoc = await ref.get();
                if (productDoc.exists) {
                  final productData = productDoc.data() as Map<String, dynamic>;
                  productsList.add(ProductModel.fromJson(productData));
                }
              }
            }
          }

          fetchedCategories.add(
            CategoryModel(
              id: doc.id,
              name: data['name'],
              description: data['description'],
              image: data['image'],
              products: productsList,
              idRestaurant: data['restaurant'] as DocumentReference,
            ),
          );
        }

        return fetchedCategories;
      });
}

Stream<List<RestaurantModel>> listenToRestaurantsWithUsers() {
  return FirebaseFirestore.instance
      .collection('restaurants')
      .snapshots()
      .asyncMap((snapshot) async {
        List<RestaurantModel> fetchedRestaurants = [];

        for (var doc in snapshot.docs) {
          final data = doc.data();

          List<UserModel> waitersList = [];
          List<UserModel> cookersList = [];

          if (data['waiters'] != null && data['waiters'] is List) {
            for (var ref in data['waiters']) {
              if (ref is DocumentReference) {
                try {
                  var userDoc = await ref.get();
                  if (userDoc.exists) {
                    var userData = userDoc.data() as Map<String, dynamic>;
                    waitersList.add(UserModel.fromJson(userData));
                  } else {
                    print('Waiter no encontrado: ${ref.id}');
                  }
                } catch (e) {
                  print('Error obteniendo waiter ${ref.id}: $e');
                }
              }
            }
          }

          if (data['cookers'] != null && data['cookers'] is List) {
            for (var ref in data['cookers']) {
              if (ref is DocumentReference) {
                try {
                  var userDoc = await ref.get();
                  if (userDoc.exists) {
                    var userData = userDoc.data() as Map<String, dynamic>;
                    cookersList.add(UserModel.fromJson(userData));
                  } else {
                    print('Cooker no encontrado: ${ref.id}');
                  }
                } catch (e) {
                  print('Error obteniendo cooker ${ref.id}: $e');
                }
              }
            }
          }

          try {
            fetchedRestaurants.add(
              RestaurantModel(
                id: doc.id,
                name: data['name'],
                state: data['state'],
                address: data['address'],
                phone: data['phone'],
                emailBoss: data['emailBoss'],
                password: data['password'],
                date: data['date'],
                waiters: waitersList,
                cookers: cookersList,
              ),
            );
          } catch (e) {
            print('Error construyendo RestaurantModel para ${doc.id}: $e');
          }
        }

        return fetchedRestaurants;
      });
}

Future<int> getTableNumber(OrderModel comanda) async {
  final tableSnapshot =
      await comanda.table.get(); // Asegúrate que `table` es DocumentReference
  final tableData = tableSnapshot.data() as Map<String, dynamic>;
  return tableData['number'] ?? 0;
}

DocumentReference getTableRefById(String? tableId) {
  return FirebaseFirestore.instance.collection('tables').doc(tableId);
}

Future<DocumentReference> createOrder(OrderModel order) async {
  try {
    final docRef = FirebaseFirestore.instance.collection('orders').doc();
    order.id = docRef.id;

    // Crear productos en 'productsOrder' y guardar referencias
    List<DocumentReference> productRefs = [];
    for (ProductOrderModel p in order.products) {
      DocumentReference productOrderRef = await createProductOrder(p);
      productRefs.add(productOrderRef);
    }

    // Crear JSON manualmente para garantizar que son referencias
    final orderData = {
      'id': order.id,
      'time': order.time,
      'table': order.table,
      'state': order.state,
      'products': productRefs,
      'restaurant': order.idRestaurant,
      'waiter': order.waiter,
    };

    await docRef.set(orderData);

    return docRef;
  } catch (e) {
    print("❌ Error al guardar una comanda: $e");
    rethrow;
  }
}

Future<DocumentReference> createProductOrder(ProductOrderModel order) async {
  try {
    final ordersRef = FirebaseFirestore.instance.collection('productsOrder');

    DocumentReference docRef;
    if (order.id.isEmpty) {
      docRef = await ordersRef.add(order.toJson());
      await docRef.update({'id': docRef.id});
    } else {
      docRef = ordersRef.doc(order.id);
      await docRef.set(order.toJson());
    }

    return docRef;
  } catch (e) {
    print('Error al guardar el producto: $e');
    rethrow;
  }
}

Future<void> updateProductsOrder(
  DocumentReference order,
  List<ProductOrderModel> products,
) async {
  final firestore = FirebaseFirestore.instance;
  try {
    final orderDoc = order;
    print("Referencia restaurante: $orderDoc");

    List<DocumentReference> prosuctsRefs = [];

    for (ProductOrderModel product in products) {
      final productid = product.id.trim();

      if (productid == null || productid.isEmpty) {
        print('❌ Producto sin ID válido: ${product.toJson()}');
        continue; // Saltamos este usuario
      }

      final productRef = firestore.collection('productsOrder').doc(productid);

      prosuctsRefs.add(productRef);
    }
    // Actualizamos el restaurante con las referencias a los usuarios
    await orderDoc.update({'products': FieldValue.arrayUnion(prosuctsRefs)});

    print('Referencias de usuarios añadidas al restaurante correctamente.');
  } catch (e) {
    print('Error al actualizar el restaurante: $e');
  }
}

Future<void> createAuthUserAndSave(
  UserModel user,
  DocumentReference restRef,
) async {
  try {
    // Crear usuario en Firebase Auth
    final UserCredential userCredential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(
          email: user.email,
          password: user.password,
        );

    // Enviar verificación por correo
    await userCredential.user?.sendEmailVerification();

    // Guardar datos del usuario en Firestore
    final userWithAuth = user.copyWith(
      id: userCredential.user!.uid,
      first_pass:
          true, // Marcamos que es la primera contraseña (la por defecto)
    );

    await saveUserWithRestaurant(userWithAuth, restRef);
  } catch (e) {
    print("❌ Error creando usuario Auth: $e");
  }
}

Future<void> loginUser(String email, String password) async {
  try {
    final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Verificar si el email está verificado
    if (!credential.user!.emailVerified) {
      // Mostrar mensaje o reenviar verificación
      print("⚠️ El correo no está verificado");
      return;
    }

    // Obtener los datos del usuario desde Firestore
    final userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(credential.user!.uid)
            .get();

    if (userDoc.exists) {
      final userModel = UserModel.fromJson(userDoc.data()!);

      if (userModel.first_pass) {
        // Redirigir a pantalla para cambiar contraseña
        print("⚠️ Usando contraseña por defecto. Obligar cambio.");
        // Navega a la pantalla de cambio de contraseña
      } else {
        // Acceso normal
        print("✅ Bienvenido ${userModel.name}");
      }
    }
  } catch (e) {
    print("❌ Error de login: $e");
  }
}
