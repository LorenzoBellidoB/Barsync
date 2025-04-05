import 'package:flutter/material.dart';

class CustomAlertDialog extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;
  final Color colorbg; // Color del ícono y título
  final IconData icon; // Ícono en el título
  final Color textColor; // Color del texto del botón
  final Color buttonColor; // Color de fondo del botón

  const CustomAlertDialog({
    super.key,
    required this.title,
    required this.message,
    this.buttonText = "Aceptar",
    this.colorbg = Colors.redAccent,
    this.icon = Icons.warning_amber_rounded,
    this.textColor =
        Colors.white, // Color del texto del botón por defecto blanco
    this.buttonColor =
        Colors.redAccent, // Color de fondo del botón por defecto rojo
  });

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth:
              screenWidth > 600
                  ? 400
                  : double.infinity, // Limita el ancho en tablet
        ),
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: colorbg,
          title: Row(
            children: [
              Icon(icon, color: buttonColor), // Ícono personalizable
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: buttonColor, // Color del título
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: TextStyle(fontSize: 16, color: textColor),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: textColor, // Color del texto del botón
                backgroundColor: buttonColor, // Color de fondo del botón
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Cierra el diálogo
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Text(buttonText), // Texto del botón
              ),
            ),
          ],
        ),
      ),
    );
  }
}
