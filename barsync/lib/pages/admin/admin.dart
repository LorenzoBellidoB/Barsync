import 'dart:async';

import 'package:barsync/components/alert.dart';
import 'package:barsync/components/menu.dart';
import 'package:barsync/models/restaurantModel.dart';
import 'package:barsync/models/userModel.dart';
import 'package:barsync/pages/admin/createRest.dart';
import 'package:barsync/pages/login/login.dart';
import 'package:barsync/services/auth/auth.dart';
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

  // Escuchar cambios en tiempo real
  @override
  void initState() {
    super.initState();
    _listenToRestaurants();
  }

  void _listenToRestaurants() {
    _restaurantSubscription = FirebaseFirestore.instance
        .collection('restaurants')
        .snapshots()
        .listen(
          (snapshot) async {
            try {
              List<RestaurantModel> fetchedRestaurantes = [];

              for (var doc in snapshot.docs) {
                var data = doc.data() as Map<String, dynamic>;

                List<UserModel> waitersList = [];
                List<UserModel> cookersList = [];

                if (data['waiters'] != null && data['waiters'] is List) {
                  for (var ref in data['waiters']) {
                    if (ref is DocumentReference) {
                      try {
                        var userDoc = await ref.get();
                        if (userDoc.exists) {
                          var userData = userDoc.data() as Map<String, dynamic>;
                          waitersList.add(
                            UserModel.fromJson(userData, userDoc.id),
                          );
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
                          cookersList.add(
                            UserModel.fromJson(userData, userDoc.id),
                          );
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
                  fetchedRestaurantes.add(
                    RestaurantModel(
                      id: doc.id,
                      name: data['name'],
                      state: data['state'],
                      address: data['address'],
                      phone: data['phone'],
                      email: data['email'],
                      password: data['password'],
                      date: data['date'],
                      waiters: waitersList,
                      cookers: cookersList,
                    ),
                  );
                } catch (e) {
                  print(
                    'Error construyendo RestaurantModel para ${doc.id}: $e',
                  );
                }
              }

              if (mounted) {
                setState(() {
                  restaurantes = fetchedRestaurantes;
                });
              }
            } catch (e) {
              print('Error procesando snapshot: $e');
            }
          },
          onError: (error) {
            print('Error en el stream de restaurantes: $error');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error al escuchar los restaurantes')),
              );
            }
          },
        );
  }

  @override
  void dispose() {
    _restaurantSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/icons/barSyncApp.png', width: 30, height: 30),
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
        backgroundColor: Color.fromRGBO(23, 23, 34, 1),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Container(color: Color.fromRGBO(60, 60, 71, 1), height: 1.5),
        ),
      ),
      body: Row(
        children: [
          Menu(role: 'Admin'),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 32, left: 58, right: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextButton.icon(
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
                  Expanded(
                    child:
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
                                          Container(
                                            width: 500,
                                            child: Text(rest.name),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            rest.state ? 'Activo' : 'Inactivo',
                                          ),
                                        ),
                                        DataCell(
                                          Row(
                                            children: [
                                              iconButton(Icons.edit, () {}),
                                              SizedBox(width: 8),
                                              iconButton(Icons.delete, () {}),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                            ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder:
                (context) => CustomAlertDialog(
                  title: 'Cerrar Sesión',
                  message: '¿Está seguro de cerrar sesión?',
                  buttonText: 'Cerrar Sesión',
                  colorbg: Color.fromRGBO(23, 23, 34, 1),
                  buttonColor: Colors.orange,
                  textColor: Colors.white,
                  actions: [
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text('Cancelar'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text('Cerrar Sesión'),
                      onPressed: () {
                        AuthService().signOut();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
          );
        },
        backgroundColor: Colors.blue,
        child: Icon(Icons.exit_to_app, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
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
