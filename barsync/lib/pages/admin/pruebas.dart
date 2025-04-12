import 'package:barsync/components/menu.dart';
import 'package:barsync/models/restaurantModel.dart';
import 'package:barsync/models/userModel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  // Lista para almacenar los restaurantes
  List<RestaurantModel> restaurantes = [];

  // Método para cargar los restaurantes desde Firestore
  Future<void> fetchRestaurantes() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('restaurants').get();

      List<RestaurantModel> fetchedRestaurantes = [];

      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;

        List<dynamic> waiterRefs = data['waiters'] ?? [];
        List<dynamic> cookerRefs = data['cookers'] ?? [];

        // Crear futuras para todos los waiters y cookers
        List<Future<UserModel>> waiterFutures =
            waiterRefs.whereType<DocumentReference>().map((ref) async {
              final snap = await ref.get();
              final userData = snap.data() as Map<String, dynamic>;
              return UserModel.fromJson(userData, snap.id);
            }).toList();

        List<Future<UserModel>> cookerFutures =
            cookerRefs.whereType<DocumentReference>().map((ref) async {
              final snap = await ref.get();
              final userData = snap.data() as Map<String, dynamic>;
              return UserModel.fromJson(userData, snap.id);
            }).toList();

        // Esperar todas las cargas de usuarios en paralelo
        List<UserModel> waitersList = await Future.wait(waiterFutures);
        List<UserModel> cookersList = await Future.wait(cookerFutures);

        fetchedRestaurantes.add(
          RestaurantModel(
            id: doc.id,
            name: data['name'],
            state: data['state'],
            address: data['address'],
            phone: data['phone'],
            emailBoss: data['email'],
            password: data['password'],
            date: data['date'],
            waiters: waitersList,
            cookers: cookersList,
          ),
        );
      }

      setState(() {
        restaurantes = fetchedRestaurantes;
      });
    } catch (e) {
      print('Error al cargar los restaurantes: $e');
    }
  }

  // Si no tuviera referencias funcionaria
  // Future<void> fetchRestaurantes() async {
  //   try {
  //     // Obtener los datos de la colección 'restaurants'
  //     QuerySnapshot snapshot =
  //         await FirebaseFirestore.instance.collection('restaurants').get();

  //     List<RestaurantModel> fetchedRestaurantes = [];

  //     // Convertir los documentos de Firestore a objetos RestaurantModel
  //     for (var doc in snapshot.docs) {
  //       var data = doc.data() as Map<String, dynamic>;

  //       // Asegurarse de que las referencias sean resueltas
  //       // Si waiters o cookers son referencias a otros documentos, podrías obtener esos datos si los necesitas

  //       // Aquí solo mostramos cómo crear el RestaurantModel sin las referencias a otros documentos
  //       fetchedRestaurantes.add(
  //         RestaurantModel.fromJsonWithoutUsers(data, doc.id),
  //       );
  //     }

  //     setState(() {
  //       restaurantes = fetchedRestaurantes;
  //     });
  //   } catch (e) {
  //     print('Error al cargar los restaurantes: $e');
  //     // Si lo deseas, puedes agregar una notificación de error en la UI
  //   }
  // }

  @override
  void initState() {
    super.initState();
    fetchRestaurantes(); // Llamar al método para cargar los restaurantes
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
            child: Container(
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 28,
                  left: 48,
                  right: 24,
                  bottom: 60,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    TextButton.icon(
                      onPressed: () {},
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
                              ? Center(
                                child: CircularProgressIndicator(),
                              ) // Mostrar indicador de carga
                              : DataTable(
                                headingRowColor: WidgetStateProperty.all(
                                  Color.fromRGBO(23, 23, 34, 1),
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
                                              child: Text(
                                                rest.name,
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                                softWrap: false,
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Container(
                                              width: 100,
                                              child: Text(
                                                rest.state
                                                    ? 'Activo'
                                                    : 'Inactivo',
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Row(
                                              children: [
                                                Container(
                                                  width: 36,
                                                  height: 36,
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[200],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                  child: IconButton(
                                                    icon: Icon(
                                                      Icons.edit,
                                                      size: 18,
                                                    ),
                                                    onPressed: () {},
                                                  ),
                                                ),
                                                SizedBox(width: 8),
                                                Container(
                                                  width: 36,
                                                  height: 36,
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[200],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                  child: IconButton(
                                                    icon: Icon(
                                                      Icons.delete,
                                                      size: 18,
                                                    ),
                                                    onPressed: () {},
                                                  ),
                                                ),
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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.blue,
        child: Icon(Icons.exit_to_app, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }
}



// Create restaurant
// body: Padding(
//         padding: const EdgeInsets.all(20.0),
//         child: SingleChildScrollView(
//           child: Column(
//             children: [
//               Wrap(
//                 spacing: 20,
//                 runSpacing: 20,
//                 children: [
//                   _buildTextField("Nombre"),
//                   _buildTextField("Fecha"),
//                   _buildTextField("Status"),
//                   _buildTextField("Dirección"),
//                   _buildTextField("Teléfono"),
//                   _buildTextField("Email"),
//                   _buildTextField("Password", obscure: true),
//                 ],
//               ),
//               SizedBox(height: 20),
//               Divider(),
//               SizedBox(height: 20),
//               Wrap(
//                 spacing: 20,
//                 runSpacing: 20,
//                 children: [
//                   _buildTextField("Camareros"),
//                   _buildTextField("Email"),
//                   _buildTextField("Email"),
//                   _buildTextField("Email"),
//                   _buildTextField("Cocina"),
//                   _buildTextField("Email"),
//                   _buildTextField("Email"),
//                 ],
//               ),
//               SizedBox(height: 30),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   ElevatedButton.icon(
//                     onPressed: () {},
//                     icon: Icon(Icons.add),
//                     label: Text('Crear'),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.blue,
//                     ),
//                   ),
//                   SizedBox(width: 20),
//                   ElevatedButton.icon(
//                     onPressed: () {},
//                     icon: Icon(Icons.cancel),
//                     label: Text('Cancelar'),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.lightBlueAccent,
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),