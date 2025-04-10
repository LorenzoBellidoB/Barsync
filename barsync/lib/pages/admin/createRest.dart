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
  Widget build(BuildContext context) {
    return MaterialApp(title: 'BarSync', home: BarSyncForm());
  }
}

class BarSyncForm extends StatelessWidget {
  final TextEditingController dateController = TextEditingController();

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
      body: Row(children: [Menu(role: 'Admin'), Expanded(child: Container())]),
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
}
