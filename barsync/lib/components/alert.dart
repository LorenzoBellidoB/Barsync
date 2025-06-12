import 'package:flutter/material.dart';

class CustomAlertDialog extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;
  final Color colorbg;
  final IconData icon;
  final Color textColor;
  final Color buttonColor;
  final VoidCallback? onConfirm;
  final List<Widget>? actions;

  const CustomAlertDialog({
    super.key,
    required this.title,
    required this.message,
    this.buttonText = "Aceptar",
    this.colorbg = Colors.redAccent,
    this.icon = Icons.warning_amber_rounded,
    this.textColor = Colors.white,
    this.buttonColor = Colors.redAccent,
    this.onConfirm,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: screenWidth > 600 ? 400 : double.infinity,
        ),
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: colorbg,
          title: Row(
            children: [
              Icon(icon, color: buttonColor),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: buttonColor,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: TextStyle(fontSize: 16, color: textColor),
          ),

          actions:
              actions ??
              [
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: textColor,
                    backgroundColor: buttonColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  onPressed: () {
                    Navigator.of(context).pop();
                    if (onConfirm != null) onConfirm!();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Text(buttonText),
                  ),
                ),
              ],
        ),
      ),
    );
  }
}
