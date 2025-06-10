// import 'package:barsync/components/alert.dart';
// import 'package:barsync/components/menu.dart';
// import 'package:barsync/pages/admin/admin.dart';
// import 'package:barsync/services/database/dataBaseManager.dart';
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:barsync/models/userModel.dart';
// import 'package:barsync/models/restaurantModel.dart';

// class EditRestScreen extends StatefulWidget {
//   final RestaurantModel restaurant;

//   const EditRestScreen({Key? key, required this.restaurant}) : super(key: key);

//   @override
//   _EditRestScreenState createState() => _EditRestScreenState();
// }

// class _EditRestScreenState extends State<EditRestScreen> {
//   // Controladores para los campos “generales” del restaurante
//   late final Map<String, TextEditingController> restauranteControllers;
//   late final TextEditingController _camarerosCountController;
//   late final TextEditingController _cocinerosCountController;

//   // Lista de mapas para crear dinámicamente campos de camareros / cocineros
//   List<Map<String, TextEditingController>> camareros = [];
//   List<Map<String, TextEditingController>> cocineros = [];

//   // Dropdown “Estado” (Activo / Inactivo)
//   final List<String> estados = ['Activo', 'Inactivo'];
//   String? estadoSeleccionado;

//   @override
//   void initState() {
//     super.initState();

//     // 1) Inicializo los controladores para los campos “fijos” del restaurante
//     restauranteControllers = {
//       'nombre': TextEditingController(text: widget.restaurant.name),
//       'direccion': TextEditingController(text: widget.restaurant.address),
//       'telefono': TextEditingController(text: widget.restaurant.phone),
//       'nombreJefe': TextEditingController(text: widget.restaurant.emailBoss),
//       'email': TextEditingController(text: widget.restaurant.emailBoss),
//       // Nota: en Creatión usabas 'email' para el jefe; aquí lo he puesto igual que emailBoss.
//       // Adáptalo si en tu modelo el email del jefe se guarda en otro campo.
//     };

//     // 2) Inicializo el estado seleccionado según el modelo (bool → “Activo” / “Inactivo”)
//     estadoSeleccionado = widget.restaurant.state ? 'Activo' : 'Inactivo';

//     // 3) Inicializo los controladores de conteo de camareros / cocineros con la longitud actual
//     _camarerosCountController = TextEditingController(
//       text: widget.restaurant.waiters.length.toString(),
//     );
//     _cocinerosCountController = TextEditingController(
//       text: widget.restaurant.cookers.length.toString(),
//     );

//     // 4) Construyo las listas “camareros” y “cocineros” pre-rellenas con los datos existentes
//     for (var waiter in widget.restaurant.waiters) {
//       // Cada waiter es un UserModel
//       camareros.add({
//         'nombre': TextEditingController(text: waiter.name),
//         'email': TextEditingController(text: waiter.email),
//         'rol': TextEditingController(text: waiter.rol),
//       });
//     }
//     for (var cooker in widget.restaurant.cookers) {
//       cocineros.add({
//         'nombre': TextEditingController(text: cooker.name),
//         'email': TextEditingController(text: cooker.email),
//         'rol': TextEditingController(text: cooker.rol),
//       });
//     }
//   }

//   @override
//   void dispose() {
//     // Descarto todos los TextEditingController
//     for (var c in restauranteControllers.values) {
//       c.dispose();
//     }
//     _camarerosCountController.dispose();
//     _cocinerosCountController.dispose();
//     for (var map in camareros) {
//       map.values.forEach((c) => c.dispose());
//     }
//     for (var map in cocineros) {
//       map.values.forEach((c) => c.dispose());
//     }
//     super.dispose();
//   }

//   // Recalcula dinámicamente cuántos campos de camareros / cocineros mostrar
//   void updateDynamicFields() {
//     final camCount = int.tryParse(_camarerosCountController.text) ?? 0;
//     final cocCount = int.tryParse(_cocinerosCountController.text) ?? 0;

//     setState(() {
//       // Ajusto la lista de camareros:
//       if (camCount < camareros.length) {
//         // Si disminuyó, libero controladores sobrantes y recorto la lista
//         for (int i = camCount; i < camareros.length; i++) {
//           camareros[i].values.forEach((c) => c.dispose());
//         }
//         camareros = camareros.sublist(0, camCount);
//       } else if (camCount > camareros.length) {
//         // Si aumentó, agrego nuevos controladores vacíos
//         final toAdd = camCount - camareros.length;
//         for (int i = 0; i < toAdd; i++) {
//           camareros.add({
//             'nombre': TextEditingController(),
//             'email': TextEditingController(),
//             'rol': TextEditingController(text: 'Waiter'),
//           });
//         }
//       }

//       // Ajusto la lista de cocineros:
//       if (cocCount < cocineros.length) {
//         for (int i = cocCount; i < cocineros.length; i++) {
//           cocineros[i].values.forEach((c) => c.dispose());
//         }
//         cocineros = cocineros.sublist(0, cocCount);
//       } else if (cocCount > cocineros.length) {
//         final toAdd = cocCount - cocineros.length;
//         for (int i = 0; i < toAdd; i++) {
//           cocineros.add({
//             'nombre': TextEditingController(),
//             'email': TextEditingController(),
//             'rol': TextEditingController(text: 'Cooker'),
//           });
//         }
//       }
//     });
//   }

//   bool validateFields() {
//     // Verifico campos básicos no vacíos
//     for (var key in restauranteControllers.keys) {
//       if (restauranteControllers[key]!.text.trim().isEmpty) {
//         return false;
//       }
//     }
//     if (estadoSeleccionado == null) return false;
//     // Verifico que cada camarero y cocinero tenga nombre y email:
//     for (var map in camareros) {
//       if (map['nombre']!.text.trim().isEmpty ||
//           map['email']!.text.trim().isEmpty) {
//         return false;
//       }
//     }
//     for (var map in cocineros) {
//       if (map['nombre']!.text.trim().isEmpty ||
//           map['email']!.text.trim().isEmpty) {
//         return false;
//       }
//     }
//     return true;
//   }

//   Future<void> updateRestaurant() async {
//     final bool nuevoEstado = estadoSeleccionado == 'Activo';

//     final ref = await getRestaurantRefById(widget.restaurant.id);

//     // Construyo lista de UserModel para waiters
//     final List<UserModel> waitersList =
//         camareros.map((mapCtrl) {
//           final id = getUserIdByEmail(mapCtrl['email']!.text.trim());

//           return UserModel(
//             name: mapCtrl['nombre']!.text.trim(),
//             email: mapCtrl['email']!.text.trim(),
//             rol: mapCtrl['rol']!.text.trim(),
//             id: id.toString(),
//             fcmToken: '',
//             register_date: Timestamp.now(),
//             idRestaurante: ref,
//           );
//         }).toList();

//     // Construyo lista de UserModel para cookers
//     final List<UserModel> cookersList =
//         cocineros.map((mapCtrl) {
//           final id = getUserIdByEmail(mapCtrl['email']!.text.trim());

//           return UserModel(
//             name: mapCtrl['nombre']!.text.trim(),
//             email: mapCtrl['email']!.text.trim(),
//             rol: mapCtrl['rol']!.text.trim(),
//             id: id.toString(),
//             fcmToken: '',
//             register_date: Timestamp.now(),
//             idRestaurante: ref,
//           );
//         }).toList();

//     // Creo un RestaurantModel actualizado
//     final updated = RestaurantModel(
//       id: widget.restaurant.id,
//       name: restauranteControllers['nombre']!.text.trim(),
//       address: restauranteControllers['direccion']!.text.trim(),
//       phone: restauranteControllers['telefono']!.text.trim(),
//       emailBoss: restauranteControllers['email']!.text.trim(),
//       state: nuevoEstado,
//       date: widget.restaurant.date,
//       waiters: waitersList,
//       cookers: cookersList,
//       tables: widget.restaurant.tables,
//     );

//     try {
//       final docRef = FirebaseFirestore.instance
//           .collection('restaurants')
//           .doc(updated.id);

//       // Actualizo el restaurante
//       await docRef.update(updated.toJson());

//       // Ahora actualizo o creo usuarios (waiters y cookers)
//       for (var user in [...waitersList, ...cookersList]) {
//         await createOrUpdateAuthUserAndSave(user, ref);
//       }

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text("Restaurante y usuarios actualizados correctamente."),
//           backgroundColor: Colors.green,
//         ),
//       );

//       // Navegar a AdminScreen o donde corresponda
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (_) => const AdminScreen()),
//       );
//     } catch (e) {
//       print(e);
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text("Error al actualizar: $e"),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }

//   Widget buildTextField(
//     String label,
//     TextEditingController controller, {
//     bool obscure = false,
//     TextInputType keyboardType = TextInputType.text,
//     void Function(String)? onChanged,
//   }) {
//     return TextField(
//       controller: controller,
//       obscureText: obscure,
//       keyboardType: keyboardType,
//       onChanged: onChanged,
//       decoration: InputDecoration(
//         labelText: label,
//         labelStyle: TextStyle(
//           color: Colors.grey[800],
//           fontWeight: FontWeight.w600,
//         ),
//         prefixIcon: const Icon(Icons.edit, color: Colors.grey, size: 20),
//         filled: true,
//         fillColor: Colors.white,
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: BorderSide(color: Colors.grey.shade400),
//         ),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: BorderSide(color: Colors.grey.shade300),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: BorderSide(color: Theme.of(context).primaryColor),
//         ),
//         contentPadding: const EdgeInsets.symmetric(
//           horizontal: 16,
//           vertical: 12,
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey.shade100,
//       appBar: AppBar(
//         elevation: 0,
//         automaticallyImplyLeading: false,
//         backgroundColor: const Color.fromRGBO(23, 23, 34, 1),
//         flexibleSpace: SafeArea(
//           child: Padding(
//             padding: const EdgeInsets.only(left: 20, top: 12),
//             child: Row(
//               children: [
//                 Image.asset(
//                   'assets/icons/barSyncApp.png',
//                   width: 30,
//                   height: 30,
//                 ),
//                 const SizedBox(width: 8),
//                 const Text(
//                   'BarSync',
//                   style: TextStyle(
//                     fontSize: 26,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.white,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//       body: Row(
//         crossAxisAlignment: CrossAxisAlignment.start, // Alinear al top
//         children: [
//           // Menú lateral
//           Menu(role: 'Admin'),

//           // Contenido principal
//           Expanded(
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.symmetric(vertical: 16),
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 16),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'Editar Restaurante',
//                       style: TextStyle(
//                         fontSize: 24,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.black87,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     const Divider(thickness: 1),

//                     // ==============================================================
//                     // Card: Datos generales del restaurante (precargados)
//                     // ==============================================================
//                     Padding(
//                       padding: const EdgeInsets.only(top: 8, bottom: 16),
//                       child: Card(
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(16),
//                         ),
//                         elevation: 4,
//                         child: Padding(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 24,
//                             vertical: 20,
//                           ),
//                           child: Row(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               // Columna Izquierda
//                               Expanded(
//                                 child: Column(
//                                   children: [
//                                     buildTextField(
//                                       "Restaurante",
//                                       restauranteControllers['nombre']!,
//                                     ),
//                                     const SizedBox(height: 20),
//                                     buildTextField(
//                                       "Dirección",
//                                       restauranteControllers['direccion']!,
//                                     ),
//                                     const SizedBox(height: 20),
//                                     buildTextField(
//                                       "Nombre Jefe",
//                                       restauranteControllers['nombreJefe']!,
//                                     ),
//                                   ],
//                                 ),
//                               ),

//                               const SizedBox(width: 20),

//                               // Columna Derecha
//                               Expanded(
//                                 child: Column(
//                                   children: [
//                                     DropdownButtonFormField<String>(
//                                       value: estadoSeleccionado,
//                                       decoration: InputDecoration(
//                                         labelText: "Estado",
//                                         labelStyle: TextStyle(
//                                           color: Colors.grey[800],
//                                           fontWeight: FontWeight.w600,
//                                         ),
//                                         filled: true,
//                                         fillColor: Colors.white,
//                                         border: OutlineInputBorder(
//                                           borderRadius: BorderRadius.circular(
//                                             12,
//                                           ),
//                                           borderSide: BorderSide(
//                                             color: Colors.grey.shade400,
//                                           ),
//                                         ),
//                                         enabledBorder: OutlineInputBorder(
//                                           borderRadius: BorderRadius.circular(
//                                             12,
//                                           ),
//                                           borderSide: BorderSide(
//                                             color: Colors.grey.shade300,
//                                           ),
//                                         ),
//                                         focusedBorder: OutlineInputBorder(
//                                           borderRadius: BorderRadius.circular(
//                                             12,
//                                           ),
//                                           borderSide: BorderSide(
//                                             color:
//                                                 Theme.of(context).primaryColor,
//                                           ),
//                                         ),
//                                         contentPadding:
//                                             const EdgeInsets.symmetric(
//                                               horizontal: 16,
//                                               vertical: 12,
//                                             ),
//                                       ),
//                                       items:
//                                           estados.map((estado) {
//                                             return DropdownMenuItem<String>(
//                                               value: estado,
//                                               child: Text(estado),
//                                             );
//                                           }).toList(),
//                                       onChanged: (value) {
//                                         setState(() {
//                                           estadoSeleccionado = value;
//                                         });
//                                       },
//                                     ),
//                                     const SizedBox(height: 20),
//                                     buildTextField(
//                                       "Teléfono",
//                                       restauranteControllers['telefono']!,
//                                       keyboardType: TextInputType.phone,
//                                     ),
//                                     const SizedBox(height: 20),
//                                     buildTextField(
//                                       "Email Jefe",
//                                       restauranteControllers['email']!,
//                                       keyboardType: TextInputType.emailAddress,
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ),

//                     const Divider(thickness: 1),

//                     // ==============================================================
//                     // Card: Conteo de camareros y cocineros (pre-relleno)
//                     // ==============================================================
//                     Padding(
//                       padding: const EdgeInsets.symmetric(vertical: 8),
//                       child: Card(
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(16),
//                         ),
//                         elevation: 4,
//                         child: Padding(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 24,
//                             vertical: 20,
//                           ),
//                           child: Row(
//                             children: [
//                               // Columna Izquierda
//                               Expanded(
//                                 child: buildTextField(
//                                   "Número de Camareros",
//                                   _camarerosCountController,
//                                   keyboardType: TextInputType.number,
//                                   onChanged: (_) => updateDynamicFields(),
//                                 ),
//                               ),

//                               const SizedBox(width: 20),

//                               // Columna Derecha
//                               Expanded(
//                                 child: buildTextField(
//                                   "Número de Cocineros",
//                                   _cocinerosCountController,
//                                   keyboardType: TextInputType.number,
//                                   onChanged: (_) => updateDynamicFields(),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ),

//                     // ====================================
//                     // Sección dinámica: Camareros
//                     // ====================================
//                     if (camareros.isNotEmpty) ...[
//                       const Padding(
//                         padding: EdgeInsets.symmetric(vertical: 8),
//                         child: Text(
//                           "Camareros",
//                           style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.black87,
//                           ),
//                         ),
//                       ),
//                       ...camareros.asMap().entries.map((entry) {
//                         final idx = entry.key;
//                         final mapCtrl = entry.value;
//                         return Padding(
//                           padding: const EdgeInsets.symmetric(vertical: 8),
//                           child: Card(
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(14),
//                             ),
//                             elevation: 2,
//                             child: Padding(
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 16,
//                                 vertical: 12,
//                               ),
//                               child: Row(
//                                 children: [
//                                   // Nombre
//                                   Expanded(
//                                     child: buildTextField(
//                                       "Nombre ${idx + 1}",
//                                       mapCtrl['nombre']!,
//                                     ),
//                                   ),

//                                   const SizedBox(width: 20),

//                                   // Email
//                                   Expanded(
//                                     child: buildTextField(
//                                       "Email ${idx + 1}",
//                                       mapCtrl['email']!,
//                                       keyboardType: TextInputType.emailAddress,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         );
//                       }).toList(),
//                     ],

//                     // ====================================
//                     // Sección dinámica: Cocineros
//                     // ====================================
//                     if (cocineros.isNotEmpty) ...[
//                       const Padding(
//                         padding: EdgeInsets.symmetric(vertical: 8),
//                         child: Text(
//                           "Cocineros",
//                           style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.black87,
//                           ),
//                         ),
//                       ),
//                       ...cocineros.asMap().entries.map((entry) {
//                         final idx = entry.key;
//                         final mapCtrl = entry.value;
//                         return Padding(
//                           padding: const EdgeInsets.symmetric(vertical: 8),
//                           child: Card(
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(14),
//                             ),
//                             elevation: 2,
//                             child: Padding(
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 16,
//                                 vertical: 12,
//                               ),
//                               child: Row(
//                                 children: [
//                                   // Nombre
//                                   Expanded(
//                                     child: buildTextField(
//                                       "Nombre ${idx + 1}",
//                                       mapCtrl['nombre']!,
//                                     ),
//                                   ),

//                                   const SizedBox(width: 20),

//                                   // Email
//                                   Expanded(
//                                     child: buildTextField(
//                                       "Email ${idx + 1}",
//                                       mapCtrl['email']!,
//                                       keyboardType: TextInputType.emailAddress,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         );
//                       }).toList(),
//                     ],

//                     const SizedBox(height: 30),

//                     // ====================================
//                     // Botones Actualizar / Cancelar
//                     // ====================================
//                     Center(
//                       child: Wrap(
//                         spacing: 20,
//                         runSpacing: 10,
//                         children: [
//                           // ===================
//                           // Botón Actualizar
//                           // ===================
//                           ElevatedButton.icon(
//                             onPressed: () {
//                               if (!validateFields()) {
//                                 showDialog(
//                                   context: context,
//                                   builder:
//                                       (_) => CustomAlertDialog(
//                                         title: 'Campos incompletos',
//                                         message:
//                                             'Por favor, completa todos los campos antes de continuar.',
//                                         buttonText: 'Aceptar',
//                                         colorbg: Colors.black,
//                                         icon: Icons.warning_amber_rounded,
//                                         textColor: Colors.white,
//                                         buttonColor: Colors.orange,
//                                       ),
//                                 );
//                                 return;
//                               }
//                               updateRestaurant();
//                             },
//                             icon: const Icon(
//                               Icons.save,
//                               size: 22,
//                               color: Colors.white,
//                             ),
//                             label: const Padding(
//                               padding: EdgeInsets.only(left: 8),
//                               child: Text(
//                                 'Actualizar Restaurante',
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.w600,
//                                   color: Colors.white,
//                                 ),
//                               ),
//                             ),
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Theme.of(context).primaryColor,
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 28,
//                                 vertical: 16,
//                               ),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(14),
//                               ),
//                               elevation: 6,
//                               shadowColor: Theme.of(
//                                 context,
//                               ).primaryColor.withOpacity(0.5),
//                             ),
//                           ),

//                           // ===================
//                           // Botón Cancelar
//                           // ===================
//                           ElevatedButton.icon(
//                             onPressed: () {
//                               // Simplemente regreso a Admin sin guardar cambios
//                               Navigator.pushReplacement(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (_) => const AdminScreen(),
//                                 ),
//                               );
//                             },
//                             icon: const Icon(
//                               Icons.cancel_outlined,
//                               size: 22,
//                               color: Colors.white,
//                             ),
//                             label: const Padding(
//                               padding: EdgeInsets.only(left: 8),
//                               child: Text(
//                                 'Cancelar',
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.w600,
//                                   color: Colors.white,
//                                 ),
//                               ),
//                             ),
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor:
//                                   Theme.of(context).colorScheme.secondary,
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 28,
//                                 vertical: 16,
//                               ),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(14),
//                               ),
//                               elevation: 6,
//                               shadowColor: Theme.of(
//                                 context,
//                               ).colorScheme.secondary.withOpacity(0.5),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),

//                     const SizedBox(height: 20),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
