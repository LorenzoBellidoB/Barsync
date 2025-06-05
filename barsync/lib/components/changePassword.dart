import 'package:barsync/services/auth/auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ChangePasswordDialog extends StatefulWidget {
  final String uid;

  const ChangePasswordDialog({super.key, required this.uid});

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final TextEditingController newPassController = TextEditingController();
  final TextEditingController confirmPassController = TextEditingController();
  bool isLoading = false;

  void _updatePassword() async {
    final newPass = newPassController.text.trim();
    final confirmPass = confirmPassController.text.trim();

    if (newPass.isEmpty || confirmPass.isEmpty) {
      _showError("Todos los campos son obligatorios.");
      return;
    }

    if (newPass.length < 6 || confirmPass.length < 6) {
      _showError("La contraseña debe tener al menos 6 caracteres.");
      return;
    }

    if (newPass != confirmPass) {
      _showError("Las contraseñas no coinciden.");
      return;
    }

    setState(() => isLoading = true);

    try {
      // Cambiar la contraseña en Firebase Auth
      await AuthService().updatePassword(newPass);

      // Actualizar/crear el campo first_pass en Firestore
      final userDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid);

      final docSnapshot = await userDocRef.get();
      if (docSnapshot.exists) {
        await userDocRef.update({'first_pass': false});
      } else {
        await userDocRef.set({'first_pass': false});
      }

      Navigator.of(context).pop();
    } catch (e) {
      _showError("Error al cambiar la contraseña: $e");
      print(e);
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (_) => _DecoratedErrorDialog(message: message),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculamos un ancho máximo de 90% del ancho de la pantalla
    final maxWidth = MediaQuery.of(context).size.width * 0.9;

    return AlertDialog(
      backgroundColor: Color.fromRGBO(23, 23, 34, 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      contentPadding: EdgeInsets.zero,
      // Ajustamos ancho máximo mediante un ConstrainedBox
      content: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: SingleChildScrollView(
          // Con SingleChildScrollView evitamos overflow cuando aparece el teclado
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Título con icono
                Row(
                  children: [
                    Icon(Icons.lock_reset, color: Colors.grey, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Cambiar contraseña",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Campo nueva contraseña
                TextField(
                  style: TextStyle(color: Colors.white),
                  controller: newPassController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelStyle: TextStyle(color: Colors.white),
                    labelText: "Nueva contraseña",
                    iconColor: Colors.grey,
                    prefixIcon: const Icon(Icons.vpn_key),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Campo confirmar contraseña
                TextField(
                  style: TextStyle(color: Colors.white),
                  controller: confirmPassController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelStyle: TextStyle(color: Colors.white),
                    labelText: "Confirmar contraseña",
                    prefixIcon: const Icon(Icons.lock),
                    iconColor: Colors.grey,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Fila de botones
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Botón Cancelar
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.secondary.withValues(alpha: 0.1),
                      ),
                      onPressed:
                          isLoading ? null : () => Navigator.of(context).pop(),
                      child: Text(
                        "Cancelar",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Botón Actualizar
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 4,
                      ),
                      onPressed: isLoading ? null : _updatePassword,
                      child:
                          isLoading
                              ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                              : const Text(
                                "Actualizar",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DecoratedErrorDialog extends StatelessWidget {
  final String message;

  const _DecoratedErrorDialog({required this.message});

  @override
  Widget build(BuildContext context) {
    // Ancho máximo similar al ChangePasswordDialog
    final maxWidth = MediaQuery.of(context).size.width * 0.8;

    return AlertDialog(
      backgroundColor: Color.fromRGBO(23, 23, 34, 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      contentPadding: EdgeInsets.zero,
      content: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Título con icono rojo
                Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red.shade700,
                      size: 28,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Error",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Mensaje de error
                Text(
                  message,
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
                const SizedBox(height: 24),

                // Botón OK
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      "OK",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
