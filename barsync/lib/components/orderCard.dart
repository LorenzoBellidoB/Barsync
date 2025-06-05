import 'dart:async';

import 'package:barsync/models/ordersModel.dart';
import 'package:barsync/models/productOrderModel.dart';
import 'package:barsync/services/database/dataBaseManager.dart';
import 'package:barsync/services/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class OrderCard extends StatefulWidget {
  final OrderModel comanda;
  final Future<String> Function(OrderModel) getWaiterName;
  final VoidCallback onButtonPressed;

  const OrderCard({
    Key? key,
    required this.comanda,
    required this.getWaiterName,
    required this.onButtonPressed,
  }) : super(key: key);

  @override
  State<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard> {
  String? _selectedGroupKey;

  Timer? _timer;
  String getTime(DateTime createdTime) {
    final now = DateTime.now();
    final difference = now.difference(createdTime);

    if (difference.inDays > 0) {
      return 'Hace ${difference.inDays} ${difference.inDays == 1 ? "día" : "días"}';
    } else if (difference.inHours > 0) {
      return 'Hace ${difference.inHours} ${difference.inHours == 1 ? "hora" : "horas"}';
    } else if (difference.inMinutes > 0) {
      return 'Hace ${difference.inMinutes} ${difference.inMinutes == 1 ? "minuto" : "minutos"}';
    } else {
      return 'Hace un momento';
    }
  }

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      setState(() {
        // Esto obliga a redibujar el widget cada minuto
      });
    });

    for (var product in widget.comanda.products) {
      final size = product.price.keys.first;
      final addonsKey = product.addOns?.join(',') ?? '';
      final key = '${product.name}_$size\_$addonsKey';
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Colores según estado
    Color headerColor;
    Color footerColor;
    String buttonText;

    switch (widget.comanda.state.toLowerCase()) {
      case 'pendiente':
        headerColor = Colors.grey[900]!;
        footerColor = Colors.black87;
        buttonText = 'Cocinar';
        break;
      case 'en_preparacion':
        headerColor = const Color.fromARGB(255, 0, 114, 245);
        footerColor = const Color.fromARGB(255, 0, 87, 185);
        buttonText = 'Finalizar';
        break;
      case 'listo':
        headerColor = const Color.fromARGB(255, 224, 52, 0);
        footerColor = const Color.fromARGB(255, 160, 37, 0);
        buttonText = '';
        break;
      default:
        headerColor = Colors.grey;
        footerColor = Colors.grey;
        buttonText = '...';
    }

    final Map<String, List<ProductOrderModel>> groupedProducts = {};
    for (var product in widget.comanda.products) {
      final size = product.price.keys.first;
      final addonsKey = product.addOns?.join(',') ?? '';
      final key = '${product.name}_$size\_$addonsKey';
      groupedProducts.putIfAbsent(key, () => []).add(product);
    }

    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2F2F38),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(3),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CABECERA
          Container(
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FutureBuilder<int>(
                  future: getTableNumber(widget.comanda),
                  builder: (context, snapshot) {
                    final tableNumber =
                        snapshot.data != null
                            ? 'Mesa ${snapshot.data}'
                            : 'Mesa...';
                    return Text(
                      tableNumber,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // CUERPO
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  getTime(widget.comanda.time.toDate()),
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),

                const SizedBox(height: 4),
                const Divider(color: Colors.white24),
                const SizedBox(height: 4),
                FutureBuilder<String>(
                  future: widget.getWaiterName(widget.comanda),
                  builder: (context, snapshot) {
                    final name = snapshot.data ?? '...';
                    return Text(
                      'Realizado por: $name',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),

                // PRODUCTOS AGRUPADOS CON RADIO
                ...groupedProducts.entries.map((entry) {
                  final group = entry.value;
                  final product = group.first;
                  final quantity = group.length;
                  final size = product.price.keys.first;
                  final isSelected = product.done;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color:
                            group.every((p) => p.done)
                                ? Colors.green.withOpacity(0.1)
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '$quantity x ${product.name} ($size)',
                                  style: TextStyle(
                                    color:
                                        group.every((p) => p.done)
                                            ? Colors.greenAccent
                                            : Colors.white,
                                    fontWeight: FontWeight.w500,
                                    decoration:
                                        group.every((p) => p.done)
                                            ? TextDecoration.lineThrough
                                            : TextDecoration.none,
                                  ),
                                ),
                              ),
                              Checkbox(
                                value: group.every((p) => p.done),
                                onChanged: (bool? value) async {
                                  // Solo permite marcar, no desmarcar
                                  if (group.every((p) => p.done)) return;

                                  final newValue = value ?? false;

                                  setState(() {
                                    for (var item in group) {
                                      item.done = newValue;
                                    }
                                  });

                                  // 🔥 Actualiza en Firestore
                                  for (var item in group) {
                                    await FirebaseFirestore.instance
                                        .collection('productsOrder')
                                        .doc(item.id)
                                        .update({'done': newValue});
                                  }

                                  // 👇 Obtener el token del mesero
                                  final waiterToken = await getWaiterToken(
                                    widget.comanda,
                                  );

                                  if (waiterToken != null) {
                                    final mesaNum = await getTableNumber(
                                      widget.comanda,
                                    );

                                    await NotificationService()
                                        .sendNotificationToToken(
                                          token: waiterToken,
                                          title: 'Producto listo',
                                          body:
                                              'Tu producto "${product.name}" de la Mesa $mesaNum está listo.',
                                        );
                                  }

                                  // ✅ Si todos están hechos, dispara acción
                                  final allDone = widget.comanda.products.every(
                                    (p) => p.done,
                                  );
                                  if (allDone) {
                                    widget.onButtonPressed();
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          if (product.addOns.isNotEmpty)
                            ...product.addOns.map(
                              (addOn) => Padding(
                                padding: const EdgeInsets.only(left: 12),
                                child: Text(
                                  '• $addOn',
                                  style: TextStyle(
                                    color:
                                        group.every((p) => p.done)
                                            ? Colors.greenAccent.withOpacity(
                                              0.7,
                                            )
                                            : Colors.white70,
                                    fontStyle:
                                        group.every((p) => p.done)
                                            ? FontStyle.italic
                                            : FontStyle.normal,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),

          // BOTÓN FINAL
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                String newState;

                switch (widget.comanda.state.toLowerCase()) {
                  case 'pendiente':
                    newState = 'en_preparacion';
                    break;
                  case 'en_preparacion':
                    newState = 'listo';
                    break;
                  default:
                    return;
                }

                // Actualiza el estado en Firestore
                await FirebaseFirestore.instance
                    .collection('orders')
                    .doc(widget.comanda.id)
                    .update({'state': newState});

                // También puedes actualizar el estado local si lo necesitas
                setState(() {
                  widget.comanda.state = newState;
                });

                widget.onButtonPressed();
              },

              style: ElevatedButton.styleFrom(
                backgroundColor: footerColor,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                buttonText,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
