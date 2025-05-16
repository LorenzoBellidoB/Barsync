import 'package:barsync/components/alert.dart';
import 'package:barsync/components/menu.dart';
import 'package:barsync/models/restaurantModel.dart';
import 'package:barsync/models/userModel.dart';
import 'package:barsync/pages/admin/admin.dart';
import 'package:barsync/services/database/dataBaseManager.dart'
    as databaseManager;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CreateRestScreen extends StatefulWidget {
  const CreateRestScreen({super.key});

  @override
  State<CreateRestScreen> createState() => _CreateRestScreenState();
}

class _CreateRestScreenState extends State<CreateRestScreen> {
  final Map<String, TextEditingController> restauranteControllers = {
    'nombre': TextEditingController(),
    'direccion': TextEditingController(),
    'telefono': TextEditingController(),
    'nombreJefe': TextEditingController(),
    'email': TextEditingController(),
    'password': TextEditingController(),
  };

  final TextEditingController _camarerosCountController =
      TextEditingController();
  final TextEditingController _cocinerosCountController =
      TextEditingController();

  final List<String> estados = ['Activo', 'Inactivo'];
  String? estadoSeleccionado;

  List<Map<String, TextEditingController>> camareros = [];
  List<Map<String, TextEditingController>> cocineros = [];

  void updateDynamicFields() {
    int camarerosCount = int.tryParse(_camarerosCountController.text) ?? 0;
    int cocinerosCount = int.tryParse(_cocinerosCountController.text) ?? 0;

    setState(() {
      camareros = List.generate(camarerosCount, (_) {
        return {
          'nombre': TextEditingController(),
          'email': TextEditingController(),
          'password': TextEditingController(),
          'rol': TextEditingController(text: 'Waiter'),
        };
      });

      cocineros = List.generate(cocinerosCount, (_) {
        return {
          'nombre': TextEditingController(),
          'email': TextEditingController(),
          'password': TextEditingController(),
          'rol': TextEditingController(text: 'Cooker'),
        };
      });
    });
  }

  bool validateFields() {
    for (var key in restauranteControllers.keys) {
      if (restauranteControllers[key]!.text.isEmpty) {
        return false;
      }
    }

    if (estadoSeleccionado == null) return false;

    return true;
  }

  void createRestaurant() async {
    RestaurantModel restaurant = RestaurantModel(
      name: restauranteControllers['nombre']!.text,
      date: Timestamp.now(),
      state: estadoSeleccionado == 'Activo' ? true : false,
      address: restauranteControllers['direccion']!.text,
      phone: restauranteControllers['telefono']!.text,
      emailBoss: restauranteControllers['email']!.text,
      password: restauranteControllers['password']!.text,
    );
    try {
      final firestore = FirebaseFirestore.instance;
      // Guardar el restaurante
      String idRestaurante = await databaseManager.saveRestaurant(restaurant);
      print('Restaurante');
      print(restaurant.toJson());
      // Obtengo la referencia al restaurante
      final restaurantDoc = firestore
          .collection('restaurants')
          .doc(idRestaurante);
      // Crear camareros y cocineros del restaurante
      createWaitersCookersBoss(restaurantDoc);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Restaurante y usuarios creados correctamente."),
          backgroundColor: Colors.green,
        ),
      );

      // Guardar los camareros y cocineros en el restaurante
    } catch (e) {
      print(e);
    }
  }

  void createWaitersCookersBoss(DocumentReference id) async {
    List<UserModel> listUsers = [];

    UserModel boss = UserModel(
      id: '',
      name: restauranteControllers['nombreJefe']!.text,
      rol: 'Boss',
      email: restauranteControllers['email']!.text,
      password: restauranteControllers['password']!.text,
      register_date: Timestamp.now(),
      idRestaurante: id,
    );
    print(boss.toJson());
    try {
      await databaseManager.saveUserWithRestaurant(boss, id);
      print(boss.toJson()); // Ahora sí tendrá el id
      listUsers.add(boss); // ✅ Se añade con id correcto
    } catch (e) {
      print(e);
    }

    print("CAMAREROS:");
    for (var c in camareros) {
      UserModel camarero = UserModel(
        id: '',
        name: c['nombre']!.text,
        email: c['email']!.text,
        password: c['password']!.text,
        rol: c['rol']!.text,
        register_date: Timestamp.now(),
        idRestaurante: id,
      );

      try {
        await databaseManager.saveUserWithRestaurant(camarero, id);
        print(camarero.toJson()); // Ahora sí tendrá el id
        listUsers.add(camarero); // ✅ Se añade con id correcto
      } catch (e) {
        print(e);
      }
    }

    print("COCINEROS:");
    for (var c in cocineros) {
      UserModel cocinero = UserModel(
        id: '',
        name: c['nombre']!.text,
        email: c['email']!.text,
        password: c['password']!.text,
        rol: c['rol']!.text,
        register_date: Timestamp.now(),
        idRestaurante: id,
      );

      try {
        await databaseManager.saveUserWithRestaurant(cocinero, id);
        print(cocinero.toJson());
        listUsers.add(cocinero);
      } catch (e) {
        print(e);
      }
    }

    try {
      await databaseManager.updateUsersRestaurant(id, listUsers);
    } catch (e) {
      print('Error al actualizar restaurante: $e');
    }
  }

  @override
  // Para limpiar los controladores cuando se destruya el widget
  void dispose() {
    for (var c in camareros) {
      c.forEach((_, controller) => controller.dispose());
    }
    for (var c in cocineros) {
      c.forEach((_, controller) => controller.dispose());
    }
    for (var controller in restauranteControllers.values) {
      controller.dispose();
    }

    _camarerosCountController.dispose();
    _cocinerosCountController.dispose();
    super.dispose();
  }

  Widget buildDynamicTextField(
    String label,
    TextEditingController controller, {
    bool obscure = false,
  }) {
    return SizedBox(
      width: 200,
      child: TextField(
        controller: controller,
        obscureText:
            obscure, // Acepta el parámetro `obscure` para ocultar el texto
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
      backgroundColor: Colors.grey.shade100,
      body: Row(
        children: [
          Menu(role: 'Admin'),
          Expanded(
            child: ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 8),
                  child: Text(
                    'Crear Restaurante',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                Divider(),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: [
                      Wrap(
                        spacing: 20,
                        runSpacing: 20,
                        children: [
                          buildDynamicTextField(
                            "Restaurante",
                            restauranteControllers['nombre']!,
                          ),
                          SizedBox(
                            width: 200,
                            child: DropdownButtonFormField<String>(
                              value: estadoSeleccionado,
                              decoration: InputDecoration(
                                labelText: "Estado",
                                border: OutlineInputBorder(),
                              ),
                              items:
                                  estados.map((estado) {
                                    return DropdownMenuItem<String>(
                                      value: estado,
                                      child: Text(estado),
                                    );
                                  }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  estadoSeleccionado = value;
                                  //restauranteControllers['status']!.text =
                                  //value ?? '';
                                });
                              },
                            ),
                          ),

                          buildDynamicTextField(
                            "Dirección",
                            restauranteControllers['direccion']!,
                          ),
                          buildDynamicTextField(
                            "Teléfono",
                            restauranteControllers['telefono']!,
                          ),
                          buildDynamicTextField(
                            "Nombre Jefe",
                            restauranteControllers['nombreJefe']!,
                          ),
                          buildDynamicTextField(
                            "Email",
                            restauranteControllers['email']!,
                          ),
                          buildDynamicTextField(
                            "Password",
                            restauranteControllers['password']!,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Divider(),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: [
                      SizedBox(
                        width: 250,
                        child: TextField(
                          controller: _camarerosCountController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Número de Camareros',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (_) => updateDynamicFields(),
                        ),
                      ),
                      SizedBox(
                        width: 250,
                        child: TextField(
                          controller: _cocinerosCountController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Número de Cocineros',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (_) => updateDynamicFields(),
                        ),
                      ),
                    ],
                  ),
                ),
                if (camareros.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 14.0),
                    child: Text(
                      "Camareros",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  ...camareros.asMap().entries.map((entry) {
                    final camarero = entry.value;
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          buildDynamicTextField(
                            "Nombre ${entry.key + 1}",
                            camarero['nombre']!,
                          ),
                          buildDynamicTextField(
                            "Email ${entry.key + 1}",
                            camarero['email']!,
                          ),
                          buildDynamicTextField(
                            "Password ${entry.key + 1}",
                            camarero['password']!,
                          ),
                        ],
                      ),
                    );
                  }),
                ],
                if (cocineros.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 14.0),
                    child: Text(
                      "Cocineros",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  ...cocineros.asMap().entries.map((entry) {
                    final cocinero = entry.value;
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          buildDynamicTextField(
                            "Nombre ${entry.key + 1}",
                            cocinero['nombre']!,
                          ),
                          buildDynamicTextField(
                            "Email ${entry.key + 1}",
                            cocinero['email']!,
                          ),
                          buildDynamicTextField(
                            "Password ${entry.key + 1}",
                            cocinero['password']!,
                          ),
                        ],
                      ),
                    );
                  }),
                ],
                SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        if (!validateFields()) {
                          showDialog(
                            context: context,
                            builder:
                                (_) => CustomAlertDialog(
                                  title: 'Campos incompletos',
                                  message:
                                      'Completa todos los campos antes de continuar.',
                                  buttonText: 'Aceptar',
                                  colorbg: Colors.black,
                                  icon: Icons.warning,
                                  textColor: Colors.white,
                                  buttonColor: Colors.orange,
                                ),
                          );
                          return;
                        }

                        createRestaurant();
                      },

                      icon: Icon(Icons.add),
                      label: Text('Crear'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                    ),
                    SizedBox(width: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          camareros.clear();
                          cocineros.clear();
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AdminScreen(),
                            ),
                          );
                        });
                      },
                      icon: Icon(Icons.cancel),
                      label: Text('Cancelar'),

                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.lightBlueAccent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
