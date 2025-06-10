import 'dart:async';
import 'package:barsync/components/alert.dart';
import 'package:barsync/components/menu.dart';
import 'package:barsync/components/rotationScreen.dart';
import 'package:barsync/models/restaurantModel.dart';
import 'package:barsync/pages/admin/createRest.dart';
import 'package:barsync/services/database/dataBaseManager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  List<RestaurantModel> restaurantes = [];
  StreamSubscription? _restaurantSubscription;

  @override
  /// Este método se llama cuando el widget se crea por primera vez.
  /// Configura el estado inicial llamando a la función `listenToRestaurants` para comenzar a escuchar
  /// actualizaciones en tiempo real de los datos de los restaurantes.
  void initState() {
    super.initState();
    listenToRestaurants();
  }

  /// Escucha en tiempo real la colección "restaurants" y actualiza el estado de `restaurantes`
  /// cada vez que se produzca un cambio.
  void listenToRestaurants() {
    _restaurantSubscription = listenToRestaurantsWithUsers().listen(
      (fetchedRestaurants) {
        if (mounted) {
          setState(() {
            restaurantes = fetchedRestaurants;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al escuchar los restaurantes')),
          );
        }
      },
    );
  }

  @override
  /// Cancela la suscripción al stream de restaurantes y llama a `super.dispose()` para liberar
  /// cualquier otro recurso que el widget pueda estar utilizando.
  void dispose() {
    _restaurantSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isPortrait = mediaQuery.orientation == Orientation.portrait;
    final screenWidth = mediaQuery.size.width;

    const double minScreenWidth = 200.0;

    if (isPortrait || screenWidth < minScreenWidth) {
      return RotationMessageScreen();
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        flexibleSpace: SafeArea(
          child: Padding(
            padding: EdgeInsets.only(left: 20, top: 12),
            child: Row(
              children: [
                Image.asset(
                  'assets/icons/barSyncApp.png',
                  width: 30,
                  height: 30,
                ),
                SizedBox(width: 8),
                Text(
                  'BarSync',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        backgroundColor: Color.fromRGBO(23, 23, 34, 1),
      ),
      body: Row(
        children: [
          Menu(role: 'Admin'),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 32, left: 58, right: 20),
              child: ListView(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreateRestScreen(),
                          ),
                        );
                      },
                      icon: Icon(Icons.add, color: Colors.white),
                      label: Text(
                        'Crear Restaurante',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: Color.fromRGBO(23, 23, 34, 1),
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  restaurantes.isEmpty
                      ? Center(child: CircularProgressIndicator())
                      : DataTable(
                        headingRowColor: WidgetStateProperty.all(
                          Color.fromRGBO(23, 23, 34, 1),
                        ),
                        dataRowColor: WidgetStateProperty.all(
                          Color.fromRGBO(230, 230, 230, 1),
                        ),
                        headingTextStyle: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        columns: const [
                          DataColumn(label: Text('Nombre')),
                          DataColumn(label: Text('Status')),
                          DataColumn(label: Text('Acciones')),
                        ],
                        rows:
                            restaurantes.map((rest) {
                              return DataRow(
                                cells: [
                                  DataCell(
                                    SizedBox(
                                      width: 500,
                                      child: Text(rest.name),
                                    ),
                                  ),
                                  DataCell(
                                    Text(rest.state ? 'Activo' : 'Inactivo'),
                                  ),
                                  DataCell(
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        // iconButton(Icons.edit, () {
                                        // Navigator.push(
                                        //   context,
                                        //   MaterialPageRoute(
                                        //     builder:
                                        //         (context) => EditRestScreen(
                                        //           restaurant: rest,
                                        //         ),
                                        //   ),
                                        // );
                                        // }),
                                        // SizedBox(width: 8),
                                        iconButton(Icons.delete, () {
                                          try {
                                            showDialog(
                                              context: context,
                                              barrierDismissible: false,
                                              builder:
                                                  (_) => CustomAlertDialog(
                                                    title: 'Borrar Restaurante',
                                                    message:
                                                        '¿Está seguro de borrar ${rest.name}?',
                                                    buttonText: 'Borrar',
                                                    colorbg: Color.fromRGBO(
                                                      23,
                                                      23,
                                                      34,
                                                      1,
                                                    ),
                                                    buttonColor: Colors.orange,
                                                    textColor: Colors.white,
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () {
                                                          Navigator.of(
                                                            context,
                                                          ).pop();
                                                        },
                                                        style: TextButton.styleFrom(
                                                          backgroundColor:
                                                              Colors.orange,
                                                          foregroundColor:
                                                              Colors.white,
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  10,
                                                                ),
                                                          ),
                                                        ),
                                                        child: Text('Cancelar'),
                                                      ),
                                                      TextButton(
                                                        onPressed: () {
                                                          final firestore =
                                                              FirebaseFirestore
                                                                  .instance;
                                                          final restaurantDoc =
                                                              firestore
                                                                  .collection(
                                                                    'restaurants',
                                                                  )
                                                                  .doc(rest.id);
                                                          deleteRestaurant(
                                                            restaurantDoc,
                                                          );
                                                          Navigator.of(
                                                            context,
                                                          ).pop();
                                                        },
                                                        style: TextButton.styleFrom(
                                                          backgroundColor:
                                                              Colors.orange,
                                                          foregroundColor:
                                                              Colors.white,
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  10,
                                                                ),
                                                          ),
                                                        ),
                                                        child: Text('Borrar'),
                                                      ),
                                                    ],
                                                  ),
                                            );
                                          } catch (e) {
                                            print(
                                              "Error al obtener el restaurante $e",
                                            );
                                          }
                                        }),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                      ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget iconButton(IconData icon, VoidCallback onPressed) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(icon: Icon(icon, size: 18), onPressed: onPressed),
    );
  }
}
