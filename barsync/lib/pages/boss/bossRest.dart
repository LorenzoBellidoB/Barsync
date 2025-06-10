import 'dart:async';
import 'package:barsync/components/createCategory.dart';
import 'package:barsync/components/menu.dart';
import 'package:barsync/models/categoryModel.dart';
import 'package:barsync/pages/boss/createProduct.dart';
import 'package:barsync/pages/boss/editProduct.dart';
import 'package:barsync/utils/sesion.dart';
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
    listenToCategories();
  }

  void listenToCategories() {
    _categorySubscription = databaseManager
        .listenToCategories(Session().restaurantRef)
        .listen(
          (fetchedCategories) {
            if (mounted) {
              setState(() {
                categorias = fetchedCategories;
              });
            }
          },
          onError: (error) {
            print('Error en el stream de categorías: $error');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error al escuchar las categorías')),
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
    final mediaQuery = MediaQuery.of(context);
    final isPortrait = mediaQuery.orientation == Orientation.portrait;
    final screenWidth = mediaQuery.size.width;

    // Define the minimum width for landscape or larger screens
    const double minScreenWidth = 1000.0;

    if (isPortrait || screenWidth < minScreenWidth) {
      return Scaffold(
        backgroundColor:
            Color.fromRGBO(23, 23, 34, 1), // Your desired background color
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.screen_rotation,
                color: Colors.white,
                size: 80,
              ),
              SizedBox(height: 20),
              Text(
                'Por favor, gira tu dispositivo a modo horizontal',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'O el tamaño de la pantalla no es suficientemente grande.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () {
                  // This will pop the current route, essentially going back.
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    // Optionally, if there's no previous screen, you could:
                    // SystemNavigator.pop(); // To exit the app
                    // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen())); // To go to a different initial screen
                    print('No hay pantalla anterior para volver.');
                  }
                },
                icon: Icon(Icons.arrow_back),
                label: Text('Volver a la pantalla anterior'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.orange, // Button color
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Original BossScreen content for landscape and large screens
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading:
            false, // Evita que Flutter reserve espacio para "leading"
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
                                            MainAxisAlignment.center, // Centra el ícono y texto
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              expandedCategories.contains(
                                                      categoria.id)
                                                  ? Icons.expand_less
                                                  : Icons.expand_more,
                                              size: 20,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                if (expandedCategories
                                                    .contains(categoria.id)) {
                                                  expandedCategories
                                                      .remove(categoria.id);
                                                } else {
                                                  expandedCategories
                                                      .add(categoria.id);
                                                }
                                              });
                                            },
                                          ),
                                          Expanded(
                                            child: Text(
                                              categoria.name,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.center, // Centra el texto
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
                                        // You'll need to implement the delete category logic here
                                        // This will likely involve a confirmation dialog
                                        // and then calling a databaseManager function to delete the category.
                                        print('Delete category: ${categoria.name}');
                                        // Example for deleting a category (you need to adapt this to your DB logic)
                                        // showDialog(
                                        //   context: context,
                                        //   builder: (ctx) => AlertDialog(
                                        //     title: Text('Confirmar Eliminación'),
                                        //     content: Text('¿Estás seguro de que quieres eliminar la categoría "${categoria.name}"?'),
                                        //     actions: [
                                        //       TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancelar')),
                                        //       TextButton(
                                        //         onPressed: () async {
                                        //           await databaseManager.deleteCategory(categoria.id); // Assuming you have this function
                                        //           Navigator.pop(ctx);
                                        //           // Optionally refresh the list
                                        //           listenToCategories();
                                        //         },
                                        //         child: Text('Eliminar'),
                                        //       ),
                                        //     ],
                                        //   ),
                                        // );
                                      }),
                                    ),
                                  ),
                                ],
                              ),

                              if (expandedCategories.contains(categoria.id)) ...[
                                // Fila: añadir producto
                                TableRow(
                                  decoration:
                                      BoxDecoration(color: Colors.white),
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
                                              builder: (_) => CreateProduct(
                                                categoryId: FirebaseFirestore
                                                    .instance
                                                    .collection('categories')
                                                    .doc(categoria.id),
                                              ),
                                            ),
                                          ).then((_) {
                                            // Esto se llama cuando regresas de la pantalla de creación de producto
                                            listenToCategories();
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
                                                    builder: (_) => EditProduct(
                                                      producto: producto,
                                                    ),
                                                  ),
                                                ).then((_) {
                                                  // Esto se llama cuando regresas de la pantalla de edición
                                                  listenToCategories();
                                                  setState(() {});
                                                });
                                              }),
                                              SizedBox(width: 8),
                                              iconButton(Icons.delete,
                                                  () async {
                                                Future<bool> borrado =
                                                    databaseManager
                                                        .deleteProduct(
                                                            producto);

                                                if (await borrado) {
                                                  ScaffoldMessenger.of(
                                                          context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        'Producto eliminado correctamente',
                                                      ),
                                                    ),
                                                  );
                                                } else {
                                                  ScaffoldMessenger.of(
                                                          context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        'Error al eliminar el producto',
                                                      ),
                                                    ),
                                                  );
                                                }
                                                listenToCategories();
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