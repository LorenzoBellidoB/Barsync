import 'dart:async';

import 'package:barsync/components/alert.dart';
import 'package:barsync/components/flushBar.dart';
import 'package:barsync/components/orderCard.dart';
import 'package:barsync/components/rotationScreen.dart';
import 'package:barsync/models/ordersModel.dart';
import 'package:barsync/pages/kitchen/ordersPending.dart';
import 'package:barsync/pages/login/login.dart';
import 'package:barsync/services/auth/auth.dart';
import 'package:barsync/services/database/databaseManager.dart';
import 'package:barsync/utils/sesion.dart';
import 'package:flutter/material.dart';

class OrdersReady extends StatefulWidget {
  const OrdersReady({super.key});

  @override
  _OrdersReadyState createState() => _OrdersReadyState();
}

class _OrdersReadyState extends State<OrdersReady> {
  List<OrderModel> comandas = [];
  Map<String, String> waiterNameCache = {};
  StreamSubscription? _orderSubscription;
  Set<String> expandedCategories = {};

  @override
  /// Inicializa el estado del widget llamando a la función `listenToOrders`
  /// para comenzar a escuchar pedidos pendientes en tiempo real.
  void initState() {
    super.initState();
    listenToOrders();
  }

  /// Escucha en tiempo real la colección "orders" del restaurante actual y actualiza
  /// el estado de `comandas` cada vez que se produzca un cambio en las comandas listas.
  ///
  /// Si se produce un error en el stream, muestra un mensaje en pantalla y
  /// lanza una excepción.

  void listenToOrders() {
    _orderSubscription = listenToOrdersReady(Session().restaurantRef).listen(
      (fetchedOrders) {
        if (mounted) {
          setState(() {
            comandas = fetchedOrders;
          });
        }
      },
      onError: (error) {
        print('Error en el stream de orders: $error');
        if (mounted) {
          showErrorFlushbar(context, 'Error al escuchar las orders');
        }
      },
    );
  }

  @override
  /// Cancela la suscripción al stream de pedidos listos y llama a `super.dispose()`
  /// para liberar cualquier otro recurso.
  void dispose() {
    _orderSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isPortrait = mediaQuery.orientation == Orientation.portrait;
    final screenWidth = mediaQuery.size.width;

    const double minScreenWidth = 1000.0;

    if (isPortrait || screenWidth < minScreenWidth) {
      return RotationMessageScreen();
    }
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E23),
      appBar: AppBar(
        backgroundColor: const Color(0xFF171722),
        elevation: 0,
        automaticallyImplyLeading:
            false, // Evita que Flutter reserve espacio para "leading"
        flexibleSpace: SafeArea(
          child: Padding(
            padding: EdgeInsets.only(left: 48, top: 12, bottom: 10),
            child: Row(
              children: [
                Row(
                  children: [
                    Image.asset('assets/icons/barSyncApp.png', height: 36),
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
                Expanded(
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const OrdersPending(),
                              ),
                            );
                          },
                          child: const Text(
                            'En Preparación',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {},
                          child: const Text(
                            'Completado',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 26),
                  child: IconButton(
                    icon: const Icon(
                      Icons.logout,
                      color: Colors.white,
                      size: 32,
                    ),
                    onPressed:
                        () => showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder:
                              (context) => CustomAlertDialog(
                                title: 'Cerrar Sesión',
                                message: '¿Está seguro de cerrar sesión?',
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
                                    onPressed:
                                        () => Navigator.of(context).pop(),
                                  ),
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      backgroundColor: Colors.orange,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: Text('Cerrar Sesión'),
                                    onPressed: () {
                                      AuthService().signOut();
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) => const LoginScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(48),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:
                comandas.map((comanda) {
                  return OrderCard(
                    comanda: comanda,
                    getWaiterName: getWaiterName(comanda.waiter),
                    type: getTableType(comanda),
                    onButtonPressed:
                        () => {
                          print(comanda.toJson()),
                          print('Botón presionado para mesa ${comanda.table}'),
                        },
                  );
                }).toList(),
          ),
        ),
      ),
    );
  }
}
