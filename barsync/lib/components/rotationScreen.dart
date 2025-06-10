import 'package:flutter/material.dart';

class RotationMessageScreen extends StatelessWidget {
  const RotationMessageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E23),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.screen_rotation,
              color: Colors.white,
              size: 80,
            ),
            const SizedBox(height: 20),
            const Text(
              'Por favor, gira tu dispositivo a modo horizontal',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Esta pantalla requiere un ancho mínimo para una mejor visualización.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color.fromARGB(158, 255, 255, 255),
                  fontSize: 16,
                ),
              ),
            ),
            SizedBox(height: 10),
            TextButton(style: ButtonStyle(backgroundColor: WidgetStateProperty.all(Colors.orange)),
              onPressed: () {
              Navigator.pop(context);
            }, child: Text('Volver a la pantalla anterior', style: TextStyle(color: Colors.white),))
          ],
        ),
      ),
    );
  }
}