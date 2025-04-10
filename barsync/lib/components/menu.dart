import 'package:flutter/material.dart';

class Menu extends StatelessWidget {
  final String role;

  const Menu({required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: 20),
      alignment: Alignment.topLeft,
      color: Color.fromRGBO(23, 23, 34, 1),
      width: 300,
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.start, // Alinea los botones al inicio
        crossAxisAlignment:
            CrossAxisAlignment.start, // Alinea todo a la izquierda
        children: [
          if (role == 'Admin') ...[
            ListTile(
              contentPadding:
                  EdgeInsets.zero, // Elimina el padding predeterminado
              title: TextButton.icon(
                onPressed: () {},
                icon: Icon(
                  Icons.restaurant,
                  color: Color.fromRGBO(104, 104, 155, 1),
                ),
                label: Text(
                  'Administración de Restaurantes',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ), // Asegura que el texto sea blanco
                ),
                style: TextButton.styleFrom(
                  alignment:
                      Alignment.centerLeft, // Alinea el botón a la izquierda
                ),
              ),
            ),
            ListTile(
              contentPadding:
                  EdgeInsets.zero, // Elimina el padding predeterminado
              title: TextButton.icon(
                onPressed: () {},
                icon: Icon(
                  Icons.person,
                  color: Color.fromRGBO(104, 104, 155, 1),
                ),
                label: Text(
                  'Administración de Usuarios',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ), // Asegura que el texto sea blanco
                ),
                style: TextButton.styleFrom(
                  alignment:
                      Alignment.centerLeft, // Alinea el botón a la izquierda
                ),
              ),
            ),
          ] else if (role == 'Boss') ...[
            ListTile(
              contentPadding:
                  EdgeInsets.zero, // Elimina el padding predeterminado
              title: TextButton.icon(
                onPressed: () {},
                icon: Icon(
                  Icons.restaurant,
                  color: Color.fromRGBO(104, 104, 155, 1),
                ),
                label: Text(
                  'Menú',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ), // Asegura que el texto sea blanco
                ),
                style: TextButton.styleFrom(
                  alignment:
                      Alignment.centerLeft, // Alinea el botón a la izquierda
                ),
              ),
            ),
            ListTile(
              contentPadding:
                  EdgeInsets.zero, // Elimina el padding predeterminado
              title: TextButton.icon(
                onPressed: () {},
                icon: Icon(
                  Icons.person,
                  color: Color.fromRGBO(104, 104, 155, 1),
                ),
                label: Text(
                  'Mesas',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ), // Asegura que el texto sea blanco
                ),
                style: TextButton.styleFrom(
                  alignment:
                      Alignment.centerLeft, // Alinea el botón a la izquierda
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
