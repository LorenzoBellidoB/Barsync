import 'package:barsync/models/barModel.dart';
import 'package:barsync/models/billModel.dart';
import 'package:barsync/models/categoryModel.dart';
import 'package:barsync/models/ordersModel.dart';
import 'package:barsync/models/productModel.dart';
import 'package:barsync/models/productOrderModel.dart';
import 'package:barsync/models/restaurantModel.dart';
import 'package:barsync/models/tableModel.dart';
import 'package:barsync/models/userModel.dart';
import 'package:barsync/services/auth/auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Users

/// Este método obtiene una referencia a un documento de usuario en Firestore
/// basándose en el ID de un objeto `UserModel`.
DocumentReference<Object?> getUserById(UserModel user) {
  return FirebaseFirestore.instance.collection('users').doc(user.id);
}

/// Este método guarda un nuevo usuario en la colección 'users' de Firestore.
/// Lanza una excepción si el email o el rol del usuario están vacíos.
Future<void> saveUser(UserModel user) async {
  if (user.email.isEmpty || user.rol.isEmpty) {
    throw Exception('Email, contraseña y rol son obligatorios.');
  }

  await FirebaseFirestore.instance.collection('users').add(user.toJson());
}

/// Este método guarda un usuario en Firestore y lo asocia con un restaurante específico.
/// Asigna el ID del restaurante al usuario y genera un nuevo ID para el usuario si no lo tiene.
Future<UserModel> saveUserWithRestaurant(
  UserModel user,
  DocumentReference restaurantRef,
) async {
  user.idRestaurante = restaurantRef;

  final userRef = FirebaseFirestore.instance.collection('users').doc();
  user.id = userRef.id;

  await userRef.set(user.toJson());

  return user;
}

/// Este método comprueba si ya existe un usuario con el email dado.
Future<bool> usersDuplicated(String email) async {
  bool res = true;
  List<UserModel> users = await getUsers().first;

  for (UserModel u in users) {
    if (u.email == email) {
      res = false;
      break;
    }
  }
  return res;
}

/// Este método devuelve un stream que emite una lista de todos los usuarios
/// de la colección 'users' en Firestore en tiempo real.
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

/// Este método devuelve un stream que emite una lista de usuarios
/// cuya dirección de correo electrónico coincide con el email proporcionado.
/// Escucha cambios en tiempo real en la colección 'users'.
Stream<List<UserModel>> getUsersByEmail(String email) {
  return FirebaseFirestore.instance
      .collection('users')
      .where('email', isEqualTo: email)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          return UserModel.fromJson(data, doc.id);
        }).toList();
      });
}

/// Este método obtiene el nombre de un camarero a partir de su DocumentReference.
/// Si el documento existe, devuelve el nombre; de lo contrario, indica que no se encontró
/// o retorna un mensaje de error si ocurre una excepción.
Future<String> getWaiterName(DocumentReference waiterRef) async {
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

/// Este método obtiene el token FCM (Firebase Cloud Messaging) del camarero
/// asociado a una orden, lo que permite enviar notificaciones push.
Future<String?> getWaiterToken(OrderModel order) async {
  final waiterRef = order.waiter;
  final snap = await waiterRef.get();
  final data = snap.data() as Map<String, dynamic>;
  return data['fcmToken'];
}

/// Este método devuelve un stream que emite el ID de un usuario
/// dado su dirección de correo electrónico.
/// Limita la búsqueda a un solo resultado y lanza una excepción si no se encuentra ningún usuario.
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

/// Este método obtiene una lista de usuarios asociados a un restaurante específico
/// y con un rol determinado.
/// Retorna una lista vacía si ocurre un error.
Future<List<UserModel>> getUsersByRestaurantAndRole(
  DocumentReference idRestaurante,
  String rol,
) async {
  try {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('users')
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

/// Este método intenta crear un nuevo usuario en Firebase Authentication y guardarlo en Firestore.
/// Si el usuario ya existe en Authentication (por su email), actualiza los datos en Firestore.
/// Maneja la creación de la cuenta y el envío de verificación de email.
Future<UserModel> createOrUpdateAuthUserAndSave(
  UserModel user,
  DocumentReference restRef,
) async {
  UserModel userFull = user;

  try {
    final UserCredential userCredential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: user.email, password: '123456');

    await userCredential.user?.sendEmailVerification();

    final userWithAuth = user.copyWith(first_pass: true);

    userFull = await saveUserWithRestaurant(userWithAuth, restRef);
  } on FirebaseAuthException catch (e) {
    if (e.code == 'email-already-in-use') {
      print('Usuario ya existe, actualizando Firestore...');

      userFull = await saveUserWithRestaurant(user, restRef);
    } else {
      print("Error creando usuario Auth: $e");
      rethrow;
    }
  } catch (e) {
    print("Error inesperado: $e");
    rethrow;
  }

  return userFull;
}

//Restaurants

/// Este método devuelve un stream que emite una lista de todos los restaurantes
/// de la colección 'restaurants' en Firestore en tiempo real.
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

/// Este método obtiene la DocumentReference de un restaurante dado su ID.
/// Limita la búsqueda a un solo resultado y lanza una excepción si no se encuentra ningún restaurante.
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

/// Este método obtiene un modelo de restaurante dado su ID.
/// Lanza una excepción si no se encuentra el restaurante.
Future<RestaurantModel> getRestaurantById(String id) async {
  final snapshot =
      await FirebaseFirestore.instance.collection('restaurants').doc(id).get();
  if (snapshot.exists) {
    return RestaurantModel.fromJsonWithoutUsers(snapshot.data()!);
  } else {
    throw Exception('No se encontró restaurante con id: $id');
  }
}

/// Este método guarda un nuevo restaurante en la colección 'restaurants' de Firestore.
/// Genera un nuevo ID para el restaurante y lo asigna antes de guardarlo.
/// Retorna el ID del restaurante guardado.
Future<String> saveRestaurant(RestaurantModel restaurant) async {
  try {
    final docRef = FirebaseFirestore.instance.collection('restaurants').doc();
    restaurant.id = docRef.id;
    await docRef.set(restaurant.toJson());
    return docRef.id;
  } catch (e) {
    print("Error al guardar restaurante: $e");
    rethrow;
  }
}

/// Este método actualiza las listas de camareros y cocineros en un documento de restaurante
/// en Firestore.
/// Asocia los usuarios proporcionados (basado en su rol) con el restaurante.
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
        print('Usuario sin ID válido: ${user.toJson()}');
        continue;
      }

      final userRef = firestore.collection('users').doc(userId);
      final rol = user.rol.trim().toLowerCase();

      if (rol == 'waiter') {
        camareroRefs.add(userRef);
      } else if (rol == 'cooker') {
        cocineroRefs.add(userRef);
      } else {
        print('Rol desconocido: $rol');
      }
    }

    await restaurantDoc.set({
      'waiters': [],
      'cookers': [],
    }, SetOptions(merge: true));

    await restaurantDoc.update({
      'waiters': FieldValue.arrayUnion(camareroRefs),
      'cookers': FieldValue.arrayUnion(cocineroRefs),
    });

    print('Referencias de usuarios añadidas al restaurante correctamente.');
  } catch (e) {
    print('Error al actualizar el restaurante: $e');
  }
}

/// Este método devuelve un stream que escucha todos los restaurantes
/// en Firestore y, para cada restaurante, recupera sus usuarios (camareros y cocineros)
/// de forma asíncrona.
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

/// Este método elimina un restaurante de Firestore, junto con todos los usuarios
/// (jefes, camareros y cocineros) asociados a ese restaurante.
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
    for (var w in waiters) {
      await firestore.collection('users').doc(w.id).delete();
    }
    for (var c in cookers) {
      await firestore.collection('users').doc(c.id).delete();
    }
    await idRestaurante.delete();
  } catch (e) {
    print('Error al borrar el restaurante: $e');
  }
}

// Categories

/// Este método añade una nueva categoría a la colección 'categories' en Firestore.
/// Asocia la categoría con un restaurante específico y le asigna un ID.
Future<void> addCategory(CategoryModel category) async {
  try {
    final categoryData = {
      'name': category.name,
      'description': category.description,
      'image': category.image,
      'restaurant': FirebaseFirestore.instance
          .collection('restaurants')
          .doc(category.idRestaurant.id),
      'products': [],
    };

    final docRef = await FirebaseFirestore.instance
        .collection('categories')
        .add(categoryData);

    await docRef.update({'id': docRef.id});

    print('Categoría añadida con ID: ${docRef.id}');
  } catch (e) {
    print('Error al añadir categoría: $e');
    rethrow;
  }
}

/// Este método elimina una categoría de la colección 'categories' en Firestore.
Future<void> deleteCategory(String id) async {
  try {
    await FirebaseFirestore.instance.collection('categories').doc(id).delete();
  } catch (e) {
    print(e);
  }
}

/// Este método obtiene un mapa de referencias de documentos de categorías y sus nombres.
/// Es útil para obtener una lista de categorías con sus IDs y nombres.
Future<Map<DocumentReference, String>> fetchCategories() async {
  final snapshot =
      await FirebaseFirestore.instance.collection('categories').get();

  return {
    for (var doc in snapshot.docs)
      doc.reference: (doc.data())['name'] as String,
  };
}

/// Este método obtiene una categoría por su ID de la colección 'categories' en Firestore.
/// Retorna el modelo de categoría si se encuentra, de lo contrario, retorna `null`.
Future<CategoryModel?> getCategoryById(String categoryId) async {
  try {
    final doc =
        await FirebaseFirestore.instance
            .collection('categories')
            .doc(categoryId)
            .get();

    if (!doc.exists) {
      print('Categoría no encontrada');
      return null;
    }

    final data = doc.data()!;
    final category = CategoryModel.fromJson(data, doc.id);

    return category;
  } catch (e) {
    print('Error al obtener categoría por ID: $e');
    rethrow;
  }
}

/// Este método devuelve un stream que escucha las categorías
/// para un restaurante específico en Firestore.
/// Recupera los detalles de los productos asociados a cada categoría de forma asíncrona.
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

// Products

/// Este método añade un nuevo producto a la colección 'products' en Firestore.
/// Asigna un ID al producto antes de guardarlo.
/// Retorna la DocumentReference del producto guardado.
Future<DocumentReference> addProduct(ProductModel product) async {
  try {
    final docRef = FirebaseFirestore.instance.collection('products').doc();
    product.id = docRef.id;
    await docRef.set(product.toJson());
    return docRef;
  } catch (e) {
    print("Error al guardar restaurante: $e");
    rethrow;
  }
}

/// Este método actualiza el estado 'done' de un producto de orden en Firestore.
/// Indica si un producto ha sido preparado o no.
Future<void> updateProductDone(String productId, bool value) async {
  final ref = FirebaseFirestore.instance
      .collection('productsOrder')
      .doc(productId);

  await ref.update({'done': value});

  print('Producto $productId marcado como ${value ? 'hecho' : 'pendiente'}');
}

/// Este método elimina un producto de la colección 'products' en Firestore
/// y también lo remueve de la lista de productos de su categoría asociada.
/// Retorna `true` si la eliminación fue exitosa, `false` en caso de error.
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

/// Este método actualiza los datos de un producto existente en Firestore.
/// Retorna `true` si la actualización fue exitosa, `false` en caso de error.
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

// Orders

/// Este método crea una nueva orden en Firestore.
/// También crea documentos para cada producto dentro de la orden y los asocia.
/// Retorna la DocumentReference de la orden creada.
Future<DocumentReference> createOrder(OrderModel order) async {
  try {
    final docRef = FirebaseFirestore.instance.collection('orders').doc();
    order.id = docRef.id;

    List<DocumentReference> productRefs = [];
    for (ProductOrderModel p in order.products) {
      p.orderId = order.id;
      DocumentReference productOrderRef = await createProductOrder(p);
      productRefs.add(productOrderRef);
    }

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
    print("Error al guardar una comanda: $e");
    rethrow;
  }
}

/// Este método crea o actualiza un producto de una orden en la colección 'productsOrder' en Firestore.
/// Si el producto no tiene ID, lo crea; de lo contrario, actualiza el existente.
/// Retorna la DocumentReference del producto de orden.
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

/// Este método devuelve un stream que escucha las órdenes pendientes (estado no "listo")
/// para un restaurante específico en Firestore.
/// Recupera los detalles de los productos asociados a cada orden de forma asíncrona.
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

/// Este método devuelve un stream que escucha las órdenes que están "listo"
/// para un restaurante específico en Firestore.
/// Recupera los detalles de los productos asociados a cada orden de forma asíncrona.
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

// Tables

/// Este método obtiene el número de mesa asociado a una orden.
Future<int> getTableNumber(OrderModel comanda) async {
  final tableSnapshot = await comanda.table.get();
  final tableData = tableSnapshot.data() as Map<String, dynamic>;
  return tableData['number'] ?? 0;
}

/// Este método obtiene el tipo de mesa asociado a una orden.
Future<String> getTableType(OrderModel comanda) async {
  final tableSnapshot = await comanda.table.get();
  final tableData = tableSnapshot.data() as Map<String, dynamic>;
  return tableData['type'] ?? '';
}

/// Este método obtiene la DocumentReference de una mesa dado su ID.
DocumentReference getTableRefById(String? tableId) {
  return FirebaseFirestore.instance.collection('tables').doc(tableId);
}

/// Este método guarda las ediciones realizadas en una mesa (número de mesa, comensales y tipo)
/// en Firestore.
Future<void> saveTableEdits(
  TableModel selectedTable,
  int tableNumber,
  int dinners,
  String type,
) async {
  final original = selectedTable;
  final newNumber = tableNumber;
  final newDinners = dinners;
  final newTipo = type;

  await FirebaseFirestore.instance.collection('tables').doc(original.id).update(
    {'number': newNumber, 'dinners': newDinners, 'type': newTipo},
  );
}

/// Este método elimina una mesa de la colección 'tables' en Firestore
/// y también la remueve de la lista de mesas del restaurante asociado.
Future<void> deleteTable(TableModel t, DocumentReference restaurantRef) async {
  await FirebaseFirestore.instance.collection('tables').doc(t.id).delete();

  await restaurantRef.update({
    'tables': FieldValue.arrayRemove([
      FirebaseFirestore.instance.collection('tables').doc(t.id),
    ]),
  });
}

/// Este método guarda las ediciones realizadas en una barra (ancho, alto y rotación)
/// en Firestore.
Future<void> saveBarEdits(
  BarModel selectedBar,
  double width,
  double height,
  int rotation,
) async {
  if (selectedBar == null) return;

  final original = selectedBar;
  final newWidth = width;
  final newHeight = height;
  final newRotation = rotation;

  if (newHeight != null) {
    await FirebaseFirestore.instance.collection('bars').doc(original.id).update(
      {'width': newWidth, 'height': newHeight, 'rotation': newRotation},
    );
  }
}

Future<void> payment(double totalToPay, BillModel bill, String tableId) async {
  try {
    // 1) Marcar factura como pagada
    await FirebaseFirestore.instance.collection('bills').doc(bill.id).update({
      'state': 'paid',
      'endTime': Timestamp.now(),
      'totalAmount': totalToPay,
    });

    // 2) Marcar mesa como libre
    await FirebaseFirestore.instance.collection('tables').doc(tableId).update({
      'state': 'libre',
    });

    // 3) Borrar órdenes y productos con batch
    final batch = FirebaseFirestore.instance.batch();
    for (final orderRef in bill.orderRefs) {
      final orderSnap = await orderRef.get();
      if (!orderSnap.exists) continue;

      final orderData = orderSnap.data() as Map<String, dynamic>;
      final rawProducts = orderData['products'];
      if (rawProducts is List) {
        for (final item in rawProducts) {
          if (item is DocumentReference) {
            batch.delete(item);
          }
        }
      }
      batch.delete(orderRef);
    }

    await batch.commit();
    print("Pago procesado correctamente.");
  } catch (e, stack) {
    print("Error al procesar el pago: $e");
    print("Stacktrace: $stack");
  }
}
