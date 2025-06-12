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
  final TextEditingController resetEmailController = TextEditingController();

  String rol = "";

  /// Verifica si un email cumple con el formato correcto
  ///
  /// El formato esperado es:
  /// - Al menos un caracter alfanumerico, guion bajo, punto o guion, seguido de
  /// - Un arroba (@),
  /// - Al menos un caracter alfanumerico, guion, punto o guion,
  /// - Un punto (.) y
  /// - Al menos dos caracteres alfabeticos (dominio de segundo nivel)

  bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
    );
    return emailRegex.hasMatch(email.trim());
  }

  /// Realiza el login de un usuario en la aplicacion. Si el email y la
  /// contraseña son correctos, se loguea al usuario y se determina su
  /// rol en la aplicación. Según el rol, se redirige a una pantalla
  /// diferente. Si el usuario no existe o la contraseña es incorrecta,
  /// se muestra un mensaje de error. Si el usuario existe pero no ha
  /// cambiado su contrase a inicial, se muestra un diálogo para cambiar
  /// la contraseña.
  void login() async {
    String email = emailController.text;
    String password = passwordController.text;
    print("Email: $email, Contraseña: $password");

    if (email.isNotEmpty && password.isNotEmpty) {
      try {
        User? user = await AuthService().signInWithEmail(email, password);
        print("credenciales: $user");

        if (user == null) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder:
                (context) => const CustomAlertDialog(
                  title: "Error de credenciales",
                  message: "El email o la contraseña son incorrectos.",
                  buttonText: "Intentar de nuevo",
                  colorbg: Color.fromRGBO(23, 23, 34, 1),
                  icon: Icons.warning_amber,
                  textColor: Colors.white,
                  buttonColor: Colors.redAccent,
                ),
          );
        } else {
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
        barrierDismissible: true,
        builder:
            (context) => const CustomAlertDialog(
              title: "Campo Vacío",
              message: "Rellene todos los campos.",
              buttonText: "Aceptar",
              colorbg: Color.fromRGBO(23, 23, 34, 1),
              icon: Icons.help_outline,
              textColor: Colors.white,
              buttonColor: Colors.orangeAccent,
            ),
      );
    }
  }

  /// Muestra un diálogo de éxito después de un inicio de sesión exitoso.
  /// El diálogo informa al usuario que las credenciales son correctas. Tras
  /// la confirmación, navega a la pantalla apropiada según el rol del usuario.
  /// También inicializa los servicios de notificación y borra los campos de entrada
  /// de correo electrónico y contraseña.
  /// [rol] El rol del usuario que inicia sesión, utilizado para determinar la pantalla a la que navegar.
  /// [pantallaANavegar] El widget que representa la pantalla a la que navegar después de la confirmación del diálogo.

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

  /// Muestra un diálogo para ingresar una dirección de correo electrónico y solicitar un enlace para restablecer la contraseña a través de Firebase.
  /// Tras la confirmación, el correo electrónico se envía a Firebase para ser procesado.
  /// Si el correo electrónico es válido y existe en la base de datos, se envía un correo electrónico al usuario con instrucciones para restablecer su contraseña.
  /// De lo contrario, se muestra un error.
  void _resetPassword() async {
    resetEmailController.clear();

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color.fromRGBO(23, 23, 34, 1),
              title: Row(
                children: const [
                  Text(
                    "Recuperar contraseña",
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
              content: TextField(
                controller: resetEmailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  labelStyle: TextStyle(color: Colors.white70),
                  prefixIcon: Icon(Icons.mail_outline, color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    "Cancelar",
                    style: TextStyle(color: Colors.orangeAccent),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    textStyle: const TextStyle(color: Colors.white),
                  ),
                  onPressed: () async {
                    final email = resetEmailController.text.trim();
                    Navigator.of(context).pop();

                    if (isValidEmail(email)) {
                      try {
                        await FirebaseAuth.instance.sendPasswordResetEmail(
                          email: email,
                        );
                        showDialog(
                          context: context,
                          builder:
                              (_) => const CustomAlertDialog(
                                title: "Correo enviado",
                                message:
                                    "Si el correo está registrado, recibirás un email para restablecer tu contraseña.",
                                buttonText: "Aceptar",
                                colorbg: Color.fromRGBO(23, 23, 34, 1),
                                icon: Icons.mark_email_read_outlined,
                                textColor: Colors.white,
                                buttonColor: Colors.green,
                              ),
                        );
                      } catch (e) {
                        // Error silencioso
                        print("Error al enviar email de recuperación: $e");
                      }
                    } else {
                      showDialog(
                        context: context,
                        builder:
                            (_) => const CustomAlertDialog(
                              title: "Correo inválido",
                              message:
                                  "Por favor, ingresa un correo electrónico válido.",
                              buttonText: "Aceptar",
                              colorbg: Color.fromRGBO(23, 23, 34, 1),
                              icon: Icons.error_outline,
                              textColor: Colors.white,
                              buttonColor: Colors.redAccent,
                            ),
                      );
                    }
                  },
                  child: const Text(
                    "Enviar",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isMobile = constraints.maxWidth < 850;
          return Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/images/restaurant_bg.png',
                  fit: BoxFit.cover,
                ),
              ),
              isMobile
                  ? Center(child: _buildLoginForm())
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
            '\nYa seas administrador o camarero, aquí encontrarás todas las herramientas necesarias para gestionar salas, mesas, pedidos y más.',
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
                      onPressed: _resetPassword,
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
