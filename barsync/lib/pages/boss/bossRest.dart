import 'dart:async';
import 'package:barsync/components/createCategory.dart';
import 'package:barsync/components/flushBar.dart';
import 'package:barsync/components/menu.dart';
import 'package:barsync/components/rotationScreen.dart';
import 'package:barsync/models/categoryModel.dart';
import 'package:barsync/pages/boss/createProduct.dart';
import 'package:barsync/pages/boss/editProduct.dart';
import 'package:barsync/services/database/databaseManager.dart';
import 'package:barsync/utils/sesion.dart';
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

  // Para cuando se expande las categorias
  Set<String> expandedCategories = {};

  @override
  /// Llamado cuando el widget se inicializa.
  /// Configura el estado inicial llamando a la función `listenCategories` para
  /// comenzar a escuchar actualizaciones en tiempo real de las categorías.
  void initState() {
    super.initState();
    listenCategories();
  }

  /// Escucha en tiempo real la colección "categories" filtrando por el restaurante
  /// actual. Cada vez que se produzca un cambio, actualiza el estado de
  /// `categorias` con la lista de categorías actualizada.
  ///
  /// Si se produce un error en el stream, muestra un mensaje en pantalla y
  /// lanza una excepción.
  Future<void> listenCategories() async {
    try {
      print('hola');
      _categorySubscription = listenToCategories(
        Session().restaurantRef,
      ).listen((fetchedCategories) {
        if (mounted) {
          setState(() {
            categorias = fetchedCategories;
          });
        }
      });
    } catch (error) {
      print('Error al obtener categorías: $error');
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showErrorFlushbar(context, 'Error al cargar las categorías');
        });
      }
    }
  }

  @override
  /// Cancela la suscripción al stream de categorías y llama a `super.dispose()`
  /// para liberar cualquier otro recurso que el widget pueda estar utilizando.
  @override
  void dispose() {
    _categorySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isPortrait = mediaQuery.orientation == Orientation.portrait;
    final screenWidth = mediaQuery.size.width;
    const double minScreenWidth = 1000.0;

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
                                          MainAxisAlignment.center,
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
                                            textAlign: TextAlign.center,
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
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      child: Text(
                                        categoria.description.isEmpty
                                            ? 'Sin descripción'
                                            : categoria.description,
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
                                    child: iconButton(Icons.delete, () {
                                      print(
                                        'Delete category: ${categoria.name}',
                                      );
                                      showDialog(
                                        context: context,
                                        builder:
                                            (context) => AlertDialog(
                                              title: Text(
                                                'Confirmar Eliminación',
                                              ),
                                              content: Text(
                                                '¿Estás seguro de que quieres eliminar la categoría "${categoria.name}"?',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed:
                                                      () => Navigator.pop(
                                                        context,
                                                      ),
                                                  child: Text('Cancelar'),
                                                ),
                                                TextButton(
                                                  onPressed: () async {
                                                    await deleteCategory(
                                                      categoria.id,
                                                    );
                                                    Navigator.pop(context);
                                                    listenCategories();
                                                  },
                                                  child: Text('Eliminar'),
                                                ),
                                              ],
                                            ),
                                      );
                                    }),
                                  ),
                                ),
                              ],
                            ),

                            if (expandedCategories.contains(categoria.id)) ...[
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
                                        ).then((_) {
                                          listenCategories();
                                          setState(() {});
                                        });
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
                                      child: Center(child: Text('')),
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
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (_) => EditProduct(
                                                        producto: producto,
                                                      ),
                                                ),
                                              ).then((_) {
                                                listenCategories();
                                                setState(() {});
                                              });
                                            }),
                                            SizedBox(width: 8),
                                            iconButton(Icons.delete, () async {
                                              Future<bool> borrado =
                                                  deleteProduct(producto);

                                              if (await borrado) {
                                                showSuccessFlushbar(
                                                  context,
                                                  'Producto eliminado correctamente',
                                                );
                                              } else {
                                                showErrorFlushbar(
                                                  context,
                                                  'Error al eliminar el producto',
                                                );
                                              }
                                              listenCategories();
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
