import 'package:barsync/components/alert.dart';
import 'package:barsync/components/menu.dart';
import 'package:barsync/pages/login/login.dart';
import 'package:barsync/services/auth/auth.dart';
import 'package:flutter/material.dart';

class CreateRestScreen extends StatefulWidget {
  const CreateRestScreen({super.key});

  @override
  State<CreateRestScreen> createState() => _CreateRestScreenState();
}

class _CreateRestScreenState extends State<CreateRestScreen> {
  @override
  final TextEditingController _camarerosCountController =
      TextEditingController();
  final TextEditingController _cocinerosCountController =
      TextEditingController();

  List<TextEditingController> camarerosControllers = [];
  List<TextEditingController> cocinerosControllers = [];

  void _updateDynamicFields() {
    final int camarerosCount =
        int.tryParse(_camarerosCountController.text) ?? 0;
    final int cocinerosCount =
        int.tryParse(_cocinerosCountController.text) ?? 0;

    setState(() {
      camarerosControllers = List.generate(
        camarerosCount,
        (index) => TextEditingController(),
      );
      cocinerosControllers = List.generate(
        cocinerosCount,
        (index) => TextEditingController(),
      );
    });
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
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListView(
                children: [
                  Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: [
                      _buildTextField("Nombre"),
                      _buildTextField("Fecha"),
                      _buildTextField("Status"),
                      _buildTextField("Dirección"),
                      _buildTextField("Teléfono"),
                      _buildTextField("Email"),
                      _buildTextField("Password", obscure: true),
                    ],
                  ),
                  SizedBox(height: 20),
                  Divider(),
                  SizedBox(height: 20),
                  Wrap(
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
                          onChanged: (_) => _updateDynamicFields(),
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
                          onChanged: (_) => _updateDynamicFields(),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  if (camarerosControllers.isNotEmpty) ...[
                    Text(
                      "Camareros",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ...camarerosControllers.asMap().entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: _buildDynamicTextField(
                          "Camarero ${entry.key + 1}",
                          entry.value,
                        ),
                      );
                    }),
                  ],
                  if (cocinerosControllers.isNotEmpty) ...[
                    SizedBox(height: 20),
                    Text(
                      "Cocineros",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ...cocinerosControllers.asMap().entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: _buildDynamicTextField(
                          "Cocinero ${entry.key + 1}",
                          entry.value,
                        ),
                      );
                    }),
                  ],
                  SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: Icon(Icons.add),
                        label: Text('Crear'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                      ),
                      SizedBox(width: 20),
                      ElevatedButton.icon(
                        onPressed: () {},
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

  Widget _buildTextField(String label, {bool obscure = false}) {
    return SizedBox(
      width: 250,
      child: TextField(
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildDynamicTextField(
    String label,
    TextEditingController controller,
  ) {
    return SizedBox(
      width: 250,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }
}
