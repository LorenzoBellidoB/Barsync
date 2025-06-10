import 'package:barsync/models/barModel.dart';
import 'package:barsync/models/categoryModel.dart';
import 'package:barsync/models/ordersModel.dart';
import 'package:barsync/models/productModel.dart';
import 'package:barsync/models/productOrderModel.dart';
import 'package:barsync/models/restaurantModel.dart';
import 'package:barsync/models/tableModel.dart';
import 'package:barsync/models/userModel.dart';
import 'package:barsync/services/auth/auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Users

DocumentReference<Object?> getUserById(UserModel user) {
  return FirebaseFirestore.instance.collection('users').doc(user.id);
}

Future<void> saveUser(UserModel user) async {
  if (user.email.isEmpty || user.rol.isEmpty) {
    throw Exception('Email, contraseña y rol son obligatorios.');
  }

  await FirebaseFirestore.instance.collection('users').add(user.toJson());
}

Future<UserModel> saveUserWithRestaurant(
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

  return user;
}

Stream<List<UserModel>> getUsers() {
  return FirebaseFirestore.instance
      .collection('users')
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs.map((doc) {
              final data = doc.data();
              return UserModel.fromJson(data, doc.id);
            }).toList(),
      );
}

Stream<List<UserModel>> getUsersByEmail(String email) {
  return FirebaseFirestore.instance
      .collection('users')
      .where('email', isEqualTo: email)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          // Le pasamos tanto los datos como doc.id
          return UserModel.fromJson(data, doc.id);
        }).toList();
      });
}

Future<String?> getWaiterName(DocumentReference waiterRef) async {
  if (waiterRef == null) return null;

  try {
    DocumentSnapshot snapshot = await waiterRef.get();
    if (snapshot.exists) {
      final data = snapshot.data() as Map<String, dynamic>;
      return data['name'] ?? data['nombre'] ?? 'Nombre no disponible';
    } else {
      return 'Camarero no encontrado';
    }
  } catch (e) {
    print('Error al obtener el nombre del camarero: $e');
    return 'Error al obtener el nombre';
  }
}

Stream<String> getUserIdByEmail(String email) {
  return FirebaseFirestore.instance
      .collection('users')
      .where('email', isEqualTo: email)
      .limit(1)
      .snapshots()
      .map((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          return snapshot.docs.first.id;
        } else {
          throw Exception('No se encontró usuario con ese email');
        }
      });
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

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return UserModel.fromJson(data, doc.id);
    }).toList();
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



Future<DocumentReference> getRestaurantRefById(String id) async {
  final snapshot =
      await FirebaseFirestore.instance
          .collection('restaurants')
          .where('id', isEqualTo: id)
          .limit(1)
          .get();

  if (snapshot.docs.isNotEmpty) {
    return snapshot.docs.first.reference;
  } else {
    throw Exception('No se encontró restaurante con id: $id');
  }
}

Future<RestaurantModel> getRestaurantById(String id) async {
  final snapshot =
      await FirebaseFirestore.instance.collection('restaurants').doc(id).get();
  if (snapshot.exists) {
    return RestaurantModel.fromJsonWithoutUsers(snapshot.data()!);
  } else {
    throw Exception('No se encontró restaurante con id: $id');
  }
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

      if (userId.isEmpty) {
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

Future<void> deleteRestaurant(DocumentReference idRestaurante) async {
  AuthService auth = AuthService();
  List<UserModel> bossList;
  List<UserModel> waiters;
  List<UserModel> cookers;
  final firestore = FirebaseFirestore.instance;
  try {
    waiters = await getUsersByRestaurantAndRole(idRestaurante, 'Waiter');
    cookers = await getUsersByRestaurantAndRole(idRestaurante, 'Cooker');
    bossList = await getUsersByRestaurantAndRole(idRestaurante, 'Boss');

    UserModel boss = bossList.first;
    await firestore.collection('users').doc(boss.id).delete();
    // await auth.deleteUserByEmail(boss.email); // Necesito permisos de firebase que no tengo
    for (var w in waiters) {
      await firestore.collection('users').doc(w.id).delete();
      // await auth.deleteUserByEmail(w.email); // Necesito permisos de firebase que no tengo
    }
    for (var c in cookers) {
      await firestore.collection('users').doc(c.id).delete();
      // await auth.deleteUserByEmail(c.email); // Necesito permisos de firebase que no tengo
    }
    await idRestaurante.delete();
  } catch (e) {
    print('Error al borrar el restaurante: $e');
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
                    waitersList.add(UserModel.fromJson(userData, userDoc.id));
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
                    cookersList.add(UserModel.fromJson(userData, userDoc.id));
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
                cif: data['cif'],
                state: data['state'],
                address: data['address'],
                phone: data['phone'],
                emailBoss: data['emailBoss'],
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

Future<bool> usersDuplicated(String email) async {
  bool res = true;
  List<UserModel> users = getUsers() as List<UserModel>;

  for (UserModel u in users) {
    if (u.email == email) {
      res = false;
    }
  }
  return res;
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
      p.orderId = order.id;
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

      if (productid.isEmpty) {
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

Future<UserModel> createOrUpdateAuthUserAndSave(
  UserModel user,
  DocumentReference restRef,
) async {
  UserModel userFull = user;

  try {
    // Intentar crear usuario en Firebase Auth
    final UserCredential userCredential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: user.email, password: '123456');

    // Enviar verificación por correo
    await userCredential.user?.sendEmailVerification();

    // Guardar datos del usuario en Firestore
    final userWithAuth = user.copyWith(first_pass: true);

    userFull = await saveUserWithRestaurant(userWithAuth, restRef);
  } on FirebaseAuthException catch (e) {
    if (e.code == 'email-already-in-use') {
      // Usuario ya existe, solo actualizamos Firestore

      print('Usuario ya existe, actualizando Firestore...');

      userFull = await saveUserWithRestaurant(user, restRef);
    } else {
      print("❌ Error creando usuario Auth: $e");
      rethrow;
    }
  } catch (e) {
    print("❌ Error inesperado: $e");
    rethrow;
  }

  return userFull;
}

Future<void> updateProductDone(String productId, bool value) async {
  final ref = FirebaseFirestore.instance
      .collection('productsOrder')
      .doc(productId);

  await ref.update({'done': value});

  // Aquí podrías enviar una notificación si es necesario
  print('✅ Producto $productId marcado como ${value ? 'hecho' : 'pendiente'}');
}

Future<String?> getWaiterToken(OrderModel order) async {
  final waiterRef = order.waiter; // DocumentReference
  final snap = await waiterRef.get();
  final data = snap.data() as Map<String, dynamic>;
  return data['fcmToken'];
}

Future<void> sendNotificationToWaiter({
  required String token,
  required String title,
  required String body,
}) async {
  try {
    final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable(
      'sendNotification',
    );

    final response = await callable.call(<String, dynamic>{
      'token': token,
      'title': title,
      'body': body,
    });

    print('Respuesta de la notificación: ${response.data}');
  } on FirebaseFunctionsException catch (e) {
    print('Error al enviar notificación: ${e.message}');
  }
}

Future<void> saveTableEdits(TableModel selectedTable, int tableNumber,
    int dinners, String type) async {
  final original = selectedTable; // Removed '!' as it can be null initially
  final newNumber = tableNumber;
  final newDinners = dinners;
  final newTipo = type;

  await FirebaseFirestore.instance
      .collection('tables')
      .doc(original.id)
      .update({
        'number': newNumber,
        'dinners': newDinners,
        'type': newTipo,
      });
}

Future<void> deleteCategory(String id) async {
  try {
    await FirebaseFirestore.instance.collection('categories').doc(id).delete();
  } catch (e) {
    print(e);
  }
}
Future<void> saveBarEdits(
    BarModel selectedBar, double width, double height, int rotation) async {
  if (selectedBar == null) return;

  final original = selectedBar; // Removed '!' as it can be null initially
  final newWidth = width;
  final newHeight = height;
  final newRotation = rotation;

  if (newHeight != null) {
    await FirebaseFirestore.instance.collection('bars').doc(original.id).update({
      'width': newWidth,
      'height': newHeight,
      'rotation': newRotation,
    });
  }
}

Future<void> deleteTable(TableModel t, DocumentReference restaurantRef) async {
  await FirebaseFirestore.instance.collection('tables').doc(t.id).delete();

  await restaurantRef.update({
    'tables': FieldValue.arrayRemove([
      FirebaseFirestore.instance.collection('tables').doc(t.id),
    ]),
  });
}