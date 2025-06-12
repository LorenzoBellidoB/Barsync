import 'package:barsync/components/alert.dart';
import 'package:barsync/pages/admin/admin.dart';
import 'package:barsync/pages/boss/bossRest.dart';
import 'package:barsync/pages/boss/tableScreen.dart';
import 'package:barsync/pages/login/login.dart';
import 'package:barsync/services/auth/auth.dart';
import 'package:flutter/material.dart';

class Menu extends StatelessWidget {
  final String role;

  const Menu({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: 20),
      alignment: Alignment.topLeft,
      color: Color.fromRGBO(23, 23, 34, 1),
      width: 300,
      child: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (role == 'Admin') ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: TextButton.icon(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const AdminScreen()),
                    );
                  },
                  icon: Icon(
                    Icons.restaurant,
                    color: Color.fromRGBO(104, 104, 155, 1),
                  ),
                  label: Text(
                    'Administración de Restaurantes',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  style: TextButton.styleFrom(alignment: Alignment.centerLeft),
                ),
              ),
            ] else if (role == 'Boss') ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: TextButton.icon(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => BossScreen()),
                    );
                  },
                  icon: Icon(
                    Icons.restaurant,
                    color: Color.fromRGBO(104, 104, 155, 1),
                  ),
                  label: Text(
                    'Menú',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  style: TextButton.styleFrom(alignment: Alignment.centerLeft),
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: TextButton.icon(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => TableLayoutScreen()),
                    );
                  },
                  icon: Icon(
                    Icons.table_bar,
                    color: Color.fromRGBO(104, 104, 155, 1),
                  ),
                  label: Text(
                    'Mesas',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  style: TextButton.styleFrom(alignment: Alignment.centerLeft),
                ),
              ),
            ],

            Spacer(),
            Divider(color: Colors.grey.shade700),
            Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: TextButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder:
                        (_) => CustomAlertDialog(
                          title: 'Cerrar Sesión',
                          message: '¿Está seguro de cerrar sesión?',
                          buttonText: 'Cerrar Sesión',
                          colorbg: Color.fromRGBO(23, 23, 34, 1),
                          buttonColor: Colors.orange,
                          textColor: Colors.white,
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text('Cancelar'),
                            ),
                            TextButton(
                              onPressed: () {
                                AuthService().signOut();
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const LoginScreen(),
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text('Cerrar Sesión'),
                            ),
                          ],
                        ),
                  );
                },
                icon: Icon(Icons.exit_to_app, color: Colors.white),
                label: Text(
                  'Cerrar Sesión',
                  style: TextStyle(color: Colors.white),
                ),
                style: TextButton.styleFrom(alignment: Alignment.centerLeft),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
