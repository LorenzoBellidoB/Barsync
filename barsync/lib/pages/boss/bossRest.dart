import 'dart:async';

import 'package:barsync/components/alert.dart';
import 'package:barsync/components/menu.dart';
import 'package:barsync/models/categoryModel.dart';
import 'package:barsync/models/productModel.dart';
import 'package:barsync/pages/boss/createProduct.dart';
import 'package:barsync/pages/login/login.dart';
import 'package:barsync/services/auth/auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class BossScreen extends StatefulWidget {
  const BossScreen({super.key});

  @override
  _BossScreenState createState() => _BossScreenState();
}

class _BossScreenState extends State<BossScreen> {
  List<CategoryModel> categorias = [];
  StreamSubscription? _categorySubscription;

  @override
  void initState() {
    super.initState();
    _listenToRestaurants();
  }

  void _listenToRestaurants() {
    _categorySubscription = FirebaseFirestore.instance
        .collection('categories')
        .snapshots()
        .listen(
          (snapshot) async {
            try {
              List<CategoryModel> fetchedCategorias = [];

              for (var doc in snapshot.docs) {
                var data = doc.data();

                List<ProductModel> productsList = [];

                if (data['products'] != null && data['products'] is List) {
                  for (var ref in data['products']) {
                    if (ref is DocumentReference) {
                      try {
                        var productDoc = await ref.get();
                        if (productDoc.exists) {
                          var productData =
                              productDoc.data() as Map<String, dynamic>;
                          productsList.add(ProductModel.fromJson(productData));
                        } else {
                          print('Product no encontrado: ${ref.id}');
                        }
                      } catch (e) {
                        print('Error obteniendo product ${ref.id}: $e');
                      }
                    }
                  }
                }

                try {
                  fetchedCategorias.add(
                    CategoryModel(
                      name: data['name'],
                      description: data['description'],
                      image: data['image'],
                      products: productsList,
                      idRestaurant:
                          (data['restaurant'] as DocumentReference).id,
                    ),
                  );
                } catch (e) {
                  print('Error construyendo CategoryModel para ${doc.id}: $e');
                }
              }

              if (mounted) {
                setState(() {
                  categorias = fetchedCategorias;
                });
              }
            } catch (e) {
              print('Error procesando snapshot: $e');
            }
          },
          onError: (error) {
            print('Error en el stream de categorias: $error');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error al escuchar las categorias')),
              );
            }
          },
        );
  }

  @override
  void dispose() {
    _categorySubscription?.cancel();
    super.dispose();
  }

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
          Menu(role: 'Boss'),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 32, left: 58, right: 58),
              child: ListView(
                children: [
                  Text(
                    'Crear Jefe',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Divider(),
                  categorias.isEmpty
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
                          DataColumn(label: Text('Productos')),
                          DataColumn(label: Text('Descripcion')),
                          DataColumn(label: Text('Acciones')),
                        ],
                        rows:
                            categorias.map((rest) {
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Row(
                                      children: [
                                        Expanded(child: Text(rest.name)),
                                        PopupMenuButton<String>(
                                          icon: Icon(Icons.add, size: 20),
                                          offset: Offset(0, 25),
                                          itemBuilder:
                                              (context) => [
                                                PopupMenuItem<String>(
                                                  value: 'add_product',
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 4,
                                                  ),
                                                  height: 30,

                                                  child: Text(
                                                    'Añadir Producto',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                          onSelected: (value) {
                                            if (value == 'add_product') {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (_) => CreateProduct(
                                                        categoryId: rest.id,
                                                      ),
                                                ),
                                              );
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),

                                  DataCell(
                                    SizedBox(
                                      width: 50,
                                      child: Text(
                                        textAlign: TextAlign.center,
                                        rest.products.length.toString(),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 300,
                                      child: Text(
                                        rest.description == ''
                                            ? 'Sin Descripción'
                                            : rest.description,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      children: [
                                        SizedBox(width: 8),
                                        iconButton(Icons.delete, () {}),
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
