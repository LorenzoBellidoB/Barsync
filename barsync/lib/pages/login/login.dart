import 'package:barsync/components/alert.dart';
import 'package:barsync/components/changePassword.dart';
import 'package:barsync/models/userModel.dart';
import 'package:barsync/pages/admin/admin.dart';
import 'package:barsync/pages/boss/bossRest.dart';
import 'package:barsync/pages/kitchen/ordersPending.dart';
import 'package:barsync/pages/waiter/waiterScreen.dart';
import 'package:barsync/services/auth/auth.dart';
import 'package:barsync/services/database/dataBaseManager.dart';
import 'package:barsync/utils/sesion.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:barsync/utils/notification_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final NotificationService _notificationService = NotificationService();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String rol = "";

  void login() async {
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
          if (user.email == 'test@test.com') {
            showSuccessDialog(rol, const AdminScreen());
          }
          List<UserModel> users = await getUsersByEmail(email).first;
          if (users.isNotEmpty) {
            UserModel userModel = users.first;
            print("Usuario logueado: ${userModel.email} - ${userModel.rol} ");

            try {
              final isFirstLogin = userModel.first_pass;
              Session().setRestaurant(userModel.idRestaurante);
              Session().setUser(userModel);
              print('Usuario');
              print(Session().currentUser.toJson());
              if (isFirstLogin) {
                await showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => ChangePasswordDialog(uid: userModel.id),
                );
              } else {
                rol = userModel.rol;
                print('Usuario switch');
                print(Session().currentUser.toJson());
                switch (rol.toLowerCase()) {
                  case "waiter":
                    showSuccessDialog(rol, WaiterScreen());
                    break;
                  case "cooker":
                    showSuccessDialog(rol, const OrdersPending());
                    break;
                  case "boss":
                    showSuccessDialog(rol, const BossScreen());
                    break;
                  case "admin":
                    showSuccessDialog(rol, const AdminScreen());
                    break;
                  default:
                    print("Rol desconocido: $rol");
                }
              }
            } catch (e) {
              print("Error validacion de contraseña $e");
            }
          } else {
            print("No se encontró ningún usuario con ese email o contraseña.");
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

  void showSuccessDialog(String rol, Widget screenToNavigate) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => CustomAlertDialog(
            title: "Login exitoso",
            message: "Sus credenciales son correctas.",
            buttonText: "Aceptar",
            colorbg: const Color.fromRGBO(23, 23, 34, 1),
            icon: Icons.verified_outlined,
            textColor: Colors.white,
            buttonColor: Colors.blueAccent,
            onConfirm: () async {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => screenToNavigate),
              );
              await _notificationService.initFCM();
              _notificationService.setupListeners();

              emailController.clear();
              passwordController.clear();
            },
          ),
    );
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
      child: Container(
        color: Color.fromRGBO(23, 23, 34, 0.8),
        padding: EdgeInsets.all(30.0),
        width: 350,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                // icono + texto horizontal
                children: [
                  Image.asset(
                    'assets/icons/barSyncApp.png',
                    width: 34,
                    height: 34,
                  ),
                  SizedBox(width: 8),
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
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: login,
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
      ),
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
