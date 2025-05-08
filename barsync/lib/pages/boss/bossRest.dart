import 'dart:async';

import 'package:barsync/components/alert.dart';
import 'package:barsync/components/createCategory.dart';
import 'package:barsync/components/menu.dart';
import 'package:barsync/models/categoryModel.dart';
import 'package:barsync/models/productModel.dart';
import 'package:barsync/pages/boss/createProduct.dart';
import 'package:barsync/pages/boss/editProduct.dart';
import 'package:barsync/pages/login/login.dart';
import 'package:barsync/services/auth/auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:barsync/services/database/dataBaseManager.dart'
    as databaseManager;

class BossScreen extends StatefulWidget {
  const BossScreen({super.key});

  @override
  _BossScreenState createState() => _BossScreenState();
}

class _BossScreenState extends State<BossScreen> {
  List<CategoryModel> categorias = [];
  StreamSubscription? _categorySubscription;

  // Para cuando se expande las categorias
  Set<String> expandedCategories = {};

  @override
  void initState() {
    super.initState();
    listenToRestaurants();
  }

  void listenToRestaurants() {
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
                  for (var ref in (data['products'] as List<dynamic>)) {
                    try {
                      // Validar que sea un DocumentReference directamente
                      if (ref is DocumentReference) {
                        final productDoc = await ref.get();
                        if (productDoc.exists) {
                          final productData =
                              productDoc.data() as Map<String, dynamic>;
                          productsList.add(ProductModel.fromJson(productData));
                        } else {
                          print('Producto no encontrado: ${ref.id}');
                        }
                      } else {
                        print('Referencia de producto no válida: $ref');
                      }
                    } catch (e) {
                      print('Error procesando producto: $e');
                    }
                  }
                }

                try {
                  fetchedCategorias.add(
                    CategoryModel(
                      id: doc.id,
                      name: data['name'],
                      description: data['description'],
                      image: data['image'],
                      products: productsList,
                      idRestaurant: (data['restaurant'] as DocumentReference),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
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
                padding: EdgeInsets.only(bottom: 100),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          barrierDismissible: true,
                          builder: (context) {
                            return Dialog(
                              backgroundColor: Colors.transparent,
                              insetPadding: EdgeInsets.zero,
                              child: CreateCategory(
                                onClose: () => Navigator.of(context).pop(),
                              ),
                            );
                          },
                        );
                      },

                      icon: Icon(Icons.add, color: Colors.white),
                      label: Text(
                        'Crear Categoría',
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
                  SizedBox(height: 20),
                  categorias.isEmpty
                      ? Center(child: CircularProgressIndicator())
                      : Table(
                        columnWidths: const {
                          0: FlexColumnWidth(3),
                          1: FixedColumnWidth(80),
                          2: FlexColumnWidth(4),
                          3: FlexColumnWidth(2),
                        },
                        border: TableBorder(
                          horizontalInside: BorderSide(
                            color: Colors.grey.shade300,
                          ),
                        ),
                        children: [
                          // Encabezado
                          TableRow(
                            decoration: BoxDecoration(
                              color: Color.fromRGBO(23, 23, 34, 1),
                            ),
                            children: [
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    left: 44.0,
                                    top: 8.0,
                                  ),
                                  child: Text(
                                    'Nombre',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              TableCell(
                                verticalAlignment:
                                    TableCellVerticalAlignment.middle,
                                child: Center(
                                  child: Text(
                                    'Productos',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              Center(
                                child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text(
                                    'Descripción',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              TableCell(
                                verticalAlignment:
                                    TableCellVerticalAlignment.middle,
                                child: Center(
                                  child: Text(
                                    'Acciones',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Filas por categoría
                          for (var categoria in categorias) ...[
                            TableRow(
                              decoration: BoxDecoration(
                                color: Color.fromRGBO(230, 230, 230, 1),
                              ),
                              children: [
                                TableCell(
                                  verticalAlignment:
                                      TableCellVerticalAlignment.middle,
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment
                                              .center, // Centra el ícono y texto
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            expandedCategories.contains(
                                                  categoria.id,
                                                )
                                                ? Icons.expand_less
                                                : Icons.expand_more,
                                            size: 20,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              if (expandedCategories.contains(
                                                categoria.id,
                                              )) {
                                                expandedCategories.remove(
                                                  categoria.id,
                                                );
                                              } else {
                                                expandedCategories.add(
                                                  categoria.id,
                                                );
                                              }
                                            });
                                          },
                                        ),
                                        Expanded(
                                          child: Text(
                                            categoria.name,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign:
                                                TextAlign
                                                    .center, // Centra el texto
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                TableCell(
                                  verticalAlignment:
                                      TableCellVerticalAlignment.middle,
                                  child: Center(
                                    child: Text(
                                      categoria.products.length.toString(),
                                    ),
                                  ),
                                ),
                                TableCell(
                                  verticalAlignment:
                                      TableCellVerticalAlignment.middle,
                                  child: Center(
                                    child: Text(
                                      categoria.description.isEmpty
                                          ? 'Sin descripción'
                                          : categoria.description,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                                TableCell(
                                  verticalAlignment:
                                      TableCellVerticalAlignment.middle,
                                  child: Center(
                                    child: iconButton(Icons.delete, () {}),
                                  ),
                                ),
                              ],
                            ),

                            if (expandedCategories.contains(categoria.id)) ...[
                              // Fila: añadir producto
                              TableRow(
                                decoration: BoxDecoration(color: Colors.white),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 48,
                                      top: 8,
                                      bottom: 8,
                                    ),
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (_) => CreateProduct(
                                                  categoryId: FirebaseFirestore
                                                      .instance
                                                      .collection('categories')
                                                      .doc(categoria.id),
                                                ),
                                          ),
                                        );
                                      },
                                      child: Text(
                                        '+ Añadir Producto',
                                        style: TextStyle(
                                          color: Colors.blue.shade700,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(),
                                  SizedBox(),
                                  SizedBox(),
                                ],
                              ),

                              // Filas de productos
                              for (var producto in categoria.products)
                                TableRow(
                                  decoration: BoxDecoration(
                                    color: Color.fromRGBO(245, 245, 245, 1),
                                  ),
                                  children: [
                                    TableCell(
                                      verticalAlignment:
                                          TableCellVerticalAlignment.middle,
                                      child: Center(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 4,
                                          ),
                                          child: Text(
                                            producto.name,
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                    ),
                                    TableCell(
                                      verticalAlignment:
                                          TableCellVerticalAlignment.middle,
                                      child: Center(
                                        child: Text(
                                          '',
                                        ), // Aquí podrías poner algo como cantidad o stock
                                      ),
                                    ),
                                    TableCell(
                                      verticalAlignment:
                                          TableCellVerticalAlignment.middle,
                                      child: Center(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          child: Text(
                                            producto.description ?? '',
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                    ),
                                    TableCell(
                                      verticalAlignment:
                                          TableCellVerticalAlignment.middle,
                                      child: Center(
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            iconButton(Icons.edit, () async {
                                              // Acción de editar
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (_) => EditProduct(
                                                        producto: producto,
                                                      ),
                                                ),
                                              ).then((_) {
                                                // Esto se llama cuando regresas de la pantalla de edición
                                                listenToRestaurants();
                                                setState(() {});
                                              });
                                            }),

                                            SizedBox(width: 8),
                                            iconButton(Icons.delete, () async {
                                              Future<bool> borrado =
                                                  databaseManager.deleteProduct(
                                                    producto,
                                                  );

                                              if (await borrado) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Producto eliminado correctamente',
                                                    ),
                                                  ),
                                                );
                                              } else {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Error al eliminar el producto',
                                                    ),
                                                  ),
                                                );
                                              }
                                              listenToRestaurants();
                                            }),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ],
                        ],
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
