import 'dart:async';

import 'package:barsync/components/alert.dart';
import 'package:barsync/components/orderCard.dart';
import 'package:barsync/models/ordersModel.dart';
import 'package:barsync/pages/kitchen/ordersReady.dart';
import 'package:barsync/pages/login/login.dart';
import 'package:barsync/services/auth/auth.dart';
import 'package:barsync/services/database/dataBaseManager.dart';
import 'package:barsync/utils/sesion.dart';
import 'package:flutter/material.dart';

class OrdersPending extends StatefulWidget {
  const OrdersPending({super.key});

  @override
  _OrdersPendingState createState() => _OrdersPendingState();
}

class _OrdersPendingState extends State<OrdersPending> {
  List<OrderModel> comandas = [];
  Map<String, String> waiterNameCache = {};
  StreamSubscription? _orderSubscription;
  Set<String> expandedCategories = {};

  @override
  void initState() {
    super.initState();
    listenToOrders();
  }

  void listenToOrders() {
    _orderSubscription = listenToOrdersPending(Session().restaurantRef).listen(
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al escuchar las orders')),
          );
        }
      },
    );
  }

  Future<String> getWaiterName(OrderModel order) async {
    final String waiterPath = order.waiter.path;
    if (waiterNameCache.containsKey(waiterPath)) {
      return waiterNameCache[waiterPath]!;
    }

    try {
      final waiterSnapshot = await order.waiter.get();
      if (!waiterSnapshot.exists) {
        waiterNameCache[waiterPath] = 'Desconocido';
        return 'Desconocido';
      }

      final waiterData = waiterSnapshot.data() as Map<String, dynamic>;
      final name = waiterData['name'] ?? 'Sin nombre';
      waiterNameCache[waiterPath] = name;
      return name;
    } catch (e) {
      waiterNameCache[waiterPath] = 'Error';
      return 'Error';
    }
  }

  @override
  void dispose() {
    _orderSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                            backgroundColor: Colors.blue,
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
                                builder: (context) => const OrdersReady(),
                              ),
                            );
                          },
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
                    getWaiterName: getWaiterName,
                    onButtonPressed:
                        () => {
                          print(comanda.toJson()),
                          // Acción del botón aquí, por ejemplo cambiar estado
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
