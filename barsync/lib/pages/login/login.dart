import 'package:barsync/components/alert.dart';
import 'package:barsync/models/userModel.dart';
import 'package:barsync/pages/admin/admin.dart';
import 'package:barsync/pages/boss/bossRest.dart';
import 'package:barsync/pages/kitchen/kitchen.dart';
import 'package:barsync/pages/waiter/rooms.dart';
import 'package:barsync/services/auth/auth.dart';
import 'package:barsync/services/database/dataBaseManager.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String rol = "";

  void _login() async {
    String email = emailController.text;
    String password = passwordController.text;
    print("Email: $email, Contraseña: $password");

    if (email.isNotEmpty && password.isNotEmpty) {
      // Esperar el resultado real
      try {
        User? user = await AuthService().signInWithEmail(email, password);
        print("credenciales: $user");

        if (user == null) {
          // Solo mostrar si el usuario es null (login fallido)
          showDialog(
            context: context,
            barrierDismissible:
                false, // <-- ¡Esta línea evita que se cierre tocando fuera!
            builder:
                (context) => const CustomAlertDialog(
                  title: "Error de credenciales",
                  message: "El email o la contraseña son incorrectos.",
                  buttonText: "Intentar de nuevo", // Texto del botón
                  colorbg: Color.fromRGBO(
                    23,
                    23,
                    34,
                    1,
                  ), // Color del ícono y título
                  icon: Icons.warning_amber, // Ícono del título
                  textColor: Colors.white, // Color del texto del botón
                  buttonColor: Colors.redAccent, // Color de fondo del botón
                ),
          );
        } else {
          // Obtener datos del usuario desde Firestore
          List<UserModel> users = await getUsersByEmail(email).first;

          if (users.isNotEmpty) {
            UserModel userModel = users.first;
            print("Usuario logueado: ${userModel.email} - ${userModel.rol}");

            rol = userModel.rol;
            switch (rol.toLowerCase()) {
              case "waiter":
                // Mostrar diálogo exitoso (como ya tenías)
                showDialog(
                  context: context,
                  barrierDismissible:
                      false, // <-- ¡Esta línea evita que se cierre tocando fuera!
                  builder:
                      (context) => CustomAlertDialog(
                        title: "Login exitoso",
                        message: "Sus credenciales son correctas.",
                        buttonText: "Aceptar",
                        colorbg: const Color.fromRGBO(23, 23, 34, 1),
                        icon: Icons.verified_outlined,
                        textColor: Colors.white,
                        buttonColor: Colors.blueAccent,
                        onConfirm: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RoomsScreen(),
                            ),
                          );
                        },
                      ),
                );
                break;
              case "kitchen":
                // Mostrar diálogo exitoso (como ya tenías)
                showDialog(
                  context: context,
                  barrierDismissible:
                      false, // <-- ¡Esta línea evita que se cierre tocando fuera!
                  builder:
                      (context) => CustomAlertDialog(
                        title: "Login exitoso",
                        message: "Sus credenciales son correctas.",
                        buttonText: "Aceptar",
                        colorbg: const Color.fromRGBO(23, 23, 34, 1),
                        icon: Icons.verified_outlined,
                        textColor: Colors.white,
                        buttonColor: Colors.blueAccent,
                        onConfirm: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const KitchenScreen(),
                            ),
                          );
                        },
                      ),
                );
                break;
              case "boss":
                // Mostrar diálogo exitoso (como ya tenías)
                showDialog(
                  context: context,
                  barrierDismissible:
                      false, // <-- ¡Esta línea evita que se cierre tocando fuera!
                  builder:
                      (context) => CustomAlertDialog(
                        title: "Login exitoso",
                        message: "Sus credenciales son correctas.",
                        buttonText: "Aceptar",
                        colorbg: const Color.fromRGBO(23, 23, 34, 1),
                        icon: Icons.verified_outlined,
                        textColor: Colors.white,
                        buttonColor: Colors.blueAccent,
                        onConfirm: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const BossScreen(),
                            ),
                          );
                        },
                      ),
                );
                break;
              case "admin":
                // Mostrar diálogo exitoso (como ya tenías)
                showDialog(
                  context: context,
                  barrierDismissible:
                      false, // <-- ¡Esta línea evita que se cierre tocando fuera!
                  builder:
                      (context) => CustomAlertDialog(
                        title: "Login exitoso",
                        message: "Sus credenciales son correctas.",
                        buttonText: "Aceptar",
                        colorbg: const Color.fromRGBO(23, 23, 34, 1),
                        icon: Icons.verified_outlined,
                        textColor: Colors.white,
                        buttonColor: Colors.blueAccent,
                        onConfirm: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AdminScreen(),
                            ),
                          );
                        },
                      ),
                );
                break;
              default:
                print("Rol desconocido: $rol");
                break;
            }
          } else {
            print("No se encontró ningún usuario con ese email.");
          }
        }
      } catch (e) {
        print("Error: $e");
      }
    } else {
      showDialog(
        context: context,
        barrierDismissible:
            false, // <-- ¡Esta línea evita que se cierre tocando fuera!
        builder:
            (context) => const CustomAlertDialog(
              title: "Campo Vacío",
              message: "Rellene todos los campos.",
              buttonText: "Aceptar", // Texto del botón
              colorbg: Color.fromRGBO(
                23,
                23,
                34,
                1,
              ), // Color del ícono y título
              icon: Icons.help_outline, // Ícono del título
              textColor: Colors.white, // Color del texto del botón
              buttonColor: Colors.orangeAccent, // Color de fondo del botón
            ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isMobile = constraints.maxWidth < 600;

          return Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/images/restaurant_bg.png',
                  fit: BoxFit.cover,
                ),
              ),
              isMobile
                  ? Center(
                    child: _buildLoginForm(),
                  ) // Solo el formulario en móviles
                  : Row(
                    children: [
                      Expanded(child: _buildWelcomeSection()),
                      Expanded(child: _buildLoginForm()),
                    ],
                  ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      color: Color.fromRGBO(0, 0, 0, 0.6),
      padding: EdgeInsets.all(30.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset('assets/images/logo_bg.png', height: 200),
          Text(
            'Bienvenido a BarSync!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Accede de forma rápida y segura para optimizar el trabajo en el restaurante. '
            '\n'
            'Ya seas administrador o camarero, aquí encontrarás todas las herramientas necesarias para gestionar salas, mesas, pedidos y más.',
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return ClipRect(
      // Da error con el minmap al cambiar de pantalla
      // child: BackdropFilter(
      //   filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        color: Color.fromRGBO(23, 23, 34, 0.8),
        padding: EdgeInsets.all(40.0),
        width: 350, // Ajuste para que no ocupe toda la pantalla en móviles
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min, // Se ajusta al contenido
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                  'assets/icons/barSyncApp.png', // Ruta del icono
                  width: 34, // Ajusta el tamaño
                  height: 34,
                ),
                SizedBox(width: 8), // Espacio entre icono y texto
                Text(
                  'Bienvenido a',
                  style: TextStyle(fontSize: 18, color: Colors.white70),
                ),
              ],
            ),

            Text(
              'BarSync',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 30),
            _buildTextField(
              label: 'Email',
              icon: Icons.mail,
              obscure: false,
              controller: emailController,
            ),
            SizedBox(height: 20),
            _buildTextField(
              label: 'Contraseña',
              icon: Icons.lock,
              obscure: true,
              controller: passwordController,
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: TextButton(
                    onPressed: () {},
                    child: Text(
                      '¿Olvidaste tu contraseña?',
                      style: TextStyle(color: Colors.blue),
                      overflow: TextOverflow.ellipsis, // Evita desbordamiento
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: Text('Iniciar sesión'),
              ),
            ),
          ],
        ),
      ),
      // ),
    );
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    required bool obscure,
    required TextEditingController controller,
  }) {
    return TextField(
      controller: controller,
      style: TextStyle(color: Colors.white),
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white),
        prefixIcon: Icon(icon, color: Colors.grey),
        border: OutlineInputBorder(),
        fillColor: Color.fromRGBO(23, 23, 34, 1),
        filled: true,
      ),
    );
  }
}
