// lib/pages/waiter/billingScreen.dart

import 'dart:io';

import 'package:barsync/models/billModel.dart';
import 'package:barsync/models/printModel.dart';
import 'package:barsync/models/productOrderModel.dart';
import 'package:barsync/models/tableModel.dart';
import 'package:barsync/pages/waiter/printerSelection.dart';
import 'package:barsync/pages/waiter/waiterScreen.dart';
import 'package:barsync/services/database/dataBaseManager.dart';
import 'package:barsync/utils/mdns_helper.dart';
import 'package:barsync/utils/print.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:esc_pos_printer_plus/esc_pos_printer_plus.dart';
import 'package:flutter/material.dart';

class BillingScreen extends StatefulWidget {
  final TableModel table;

  const BillingScreen({Key? key, required this.table}) : super(key: key);

  @override
  _BillingScreenState createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  BillModel? _bill;
  List<ProductOrderModel> _allProductsInBill = [];
  bool _isLoading = true;
  WifiPrinter? _selectedPrinter;

  @override
  void initState() {
    super.initState();
    _fetchBillDetails();
  }

  Future<void> _fetchBillDetails() async {
    setState(() => _isLoading = true);
    try {
      final billSnap = await FirebaseFirestore.instance
          .collection('bills')
          .where('table', isEqualTo: getTableRefById(widget.table.id))
          .where('state', isEqualTo: 'open')
          .limit(1)
          .get();

      if (billSnap.docs.isNotEmpty) {
        _bill = BillModel.fromJson(
          billSnap.docs.first.data(),
          billSnap.docs.first.id,
        );

        _allProductsInBill.clear();
        for (final orderRef in _bill!.orderRefs) {
          final orderSnap = await orderRef.get();
          if (!orderSnap.exists) continue;
          final orderData = orderSnap.data() as Map<String, dynamic>;
          final rawProducts = orderData['products'];
          if (rawProducts is List) {
            for (final item in rawProducts) {
              if (item is DocumentReference) {
                final prodSnap = await item.get();
                if (prodSnap.exists) {
                  _allProductsInBill.add(
                    ProductOrderModel.fromJson(
                      prodSnap.data()! as Map<String, dynamic>,
                    ),
                  );
                }
              } else if (item is Map<String, dynamic>) {
                _allProductsInBill.add(ProductOrderModel.fromJson(item));
              }
            }
          }
        }
      } else {
        _bill = null;
      }
    } catch (e) {
      print("Error fetching bill details: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  double _calculateBillTotal() {
    return _allProductsInBill.fold(0.0, (sum, p) => sum + p.price.values.first);
  }

  Future<void> _processPayment() async {
    if (_bill == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay cuenta abierta para esta mesa.')),
      );
      return;
    }

    try {
      final totalToPay = _calculateBillTotal();

      // 1) Marcar factura como pagada
      await FirebaseFirestore.instance
          .collection('bills')
          .doc(_bill!.id)
          .update({
        'state': 'paid',
        'endTime': Timestamp.now(),
        'totalAmount': totalToPay,
      });

      // 2) Marcar mesa como libre
      await FirebaseFirestore.instance
          .collection('tables')
          .doc(widget.table.id)
          .update({'state': 'libre'});

      // 3) Borrar órdenes y productos con batch
      final batch = FirebaseFirestore.instance.batch();
      for (final orderRef in _bill!.orderRefs) {
        final orderSnap = await orderRef.get();
        if (!orderSnap.exists) continue;
        final orderData = orderSnap.data() as Map<String, dynamic>;
        final rawProducts = orderData['products'];
        if (rawProducts is List) {
          for (final item in rawProducts) {
            if (item is DocumentReference) {
              batch.delete(item);
            }
          }
        }
        batch.delete(orderRef);
      }
      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pago procesado y datos borrados.')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => WaiterScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al procesar el pago: $e')),
      );
    }
  }

  Future<void> _selectPrinter() async {
    await Navigator.push<WifiPrinter?>(
      context,
      MaterialPageRoute(
        builder: (_) => WifiPrinterSelectionScreen(
          onSelected: (printer) {
            setState(() => _selectedPrinter = printer);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

 Future<void> _printBill() async {
  if (_selectedPrinter == null) {
    print('❌ Selecciona una impresora Wi-Fi');
    return;
  }

  String ip;

  try {
    // Buscar solo IPv4 para evitar problemas con IPv6 link-local
    final addrs = await InternetAddress.lookup(
      _selectedPrinter!.host,
      type: InternetAddressType.IPv4,
    );
    if (addrs.isEmpty) throw Exception('No se encontró IP IPv4');
    ip = addrs.first.address;
    print('✅ Dirección IPv4 de la impresora: $ip');
  } catch (e) {
    print('❌ Error resolviendo IP IPv4: $e');
    return;
  }

  final manager = WifiPrinterManager();
  final connected = await manager.connectPrinter(
    host: ip,
    port: _selectedPrinter!.port,
  );
  if (!connected) {
    print('❌ No se pudo conectar a la impresora');
    return;
  }
  print('✅ Conexión establecida con la impresora');

  final result = await manager.printTicket(
    products: _allProductsInBill,
    total: _calculateBillTotal(),
    tableNumber: widget.table.number.toString(),
  );
  await manager.disconnect();

  if (result == PosPrintResult.success) {
    print('✅ Ticket impreso correctamente');
  } else {
    print('❌ Error al imprimir el ticket: ${result.msg}');
  }
}

  @override
Widget build(BuildContext context) {
  if (_isLoading) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cargando Cuenta')),
      body: const Center(child: CircularProgressIndicator()),
    );
  }

  if (_bill == null) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cuenta')),
      body: Center(
        child: Text(
          'No hay cuenta abierta para la mesa ${widget.table.number}',
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ),
    );
  }

  return Scaffold(
    appBar: AppBar(
      title: Text('Cuenta - Mesa ${widget.table.number}'),
      centerTitle: true,
    ),
    body: Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Detalles de la Cuenta',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              ..._allProductsInBill.map((product) {
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.fastfood, size: 28, color: Colors.brown),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (product.addOns.isNotEmpty)
                                ...product.addOns.map((addon) => Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        '• $addon',
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[700]),
                                      ),
                                    )),
                            ],
                          ),
                        ),
                        Text(
                          '${product.price.values.first.toStringAsFixed(2)} €',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),

              const Divider(height: 32, thickness: 1),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total a Pagar:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${_calculateBillTotal().toStringAsFixed(2)} €',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Botones
        Container(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 48),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _selectPrinter,
                  icon: const Icon(Icons.print, color: Colors.white,),
                  label: Text(_selectedPrinter == null
                      ? 'Seleccionar impresora'
                      : _selectedPrinter!.name, style: TextStyle(color: Colors.white ,overflow: TextOverflow.ellipsis),),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _selectedPrinter == null
                      ? null
                      : () async {
                          await _printBill();
                          await _processPayment();
                        },
                  icon: const Icon(Icons.check_circle_outline, color: Colors.white,),
                  label: const Text('Procesar Pago', style: TextStyle(color: Colors.white ,overflow: TextOverflow.ellipsis),),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _selectedPrinter == null ? Colors.grey : Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

}
