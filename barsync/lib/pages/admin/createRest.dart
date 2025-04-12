import 'package:barsync/components/alert.dart';
import 'package:barsync/components/menu.dart';
import 'package:barsync/models/userModel.dart';
import 'package:barsync/pages/login/login.dart';
import 'package:barsync/services/auth/auth.dart';
import 'package:barsync/services/database/databaseManager.dart'
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
    'fecha': TextEditingController(),
    'status': TextEditingController(),
    'direccion': TextEditingController(),
    'telefono': TextEditingController(),
    'email': TextEditingController(),
    'password': TextEditingController(),
  };

  final TextEditingController _camarerosCountController =
      TextEditingController();
  final TextEditingController _cocinerosCountController =
      TextEditingController();

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

  void createWaitersCookers() {
    print("CAMAREROS:");
    for (var c in camareros) {
      UserModel camarero = new UserModel.withoutId(
        name: c['nombre']!.text,
        email: c['email']!.text,
        password: c['password']!.text,
        rol: c['rol']!.text,
        register_date: Timestamp.now(),
      );
      try {
        databaseManager.saveUser(camarero);
      } catch (e) {
        print(e);
      }
    }

    print("COCINEROS:");
    for (var c in cocineros) {
      UserModel cocinero = new UserModel.withoutId(
        name: c['nombre']!.text,
        email: c['email']!.text,
        password: c['password']!.text,
        rol: c['rol']!.text,
        register_date: Timestamp.now(),
      );
      try {
        databaseManager.saveUser(cocinero);
      } catch (e) {
        print(e);
      }
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
      width: 250,
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
                    'Crear Jefe',
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
                            "Nombre",
                            restauranteControllers['nombre']!,
                          ),
                          buildDynamicTextField(
                            "Fecha",
                            restauranteControllers['fecha']!,
                          ),
                          buildDynamicTextField(
                            "Status",
                            restauranteControllers['status']!,
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
                      onPressed: createWaitersCookers,
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder:
                (context) => CustomAlertDialog(
                  title: 'Cerrar Sesión',
                  message: '¿Está seguro de cerrar sesión?',
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
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text('Cerrar Sesión'),
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
}
