import 'dart:ui';

import 'package:barsync/models/billModel.dart';
import 'package:barsync/models/productOrderModel.dart';
import 'package:barsync/models/tableModel.dart';
import 'package:barsync/pages/waiter/waiterScreen.dart';
import 'package:barsync/services/database/dataBaseManager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  @override
  void initState() {
    super.initState();
    _fetchBillDetails();
  }

  Future<void> _fetchBillDetails() async {
    setState(() => _isLoading = true);

    try {
      final billSnap =
          await FirebaseFirestore.instance
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
        for (DocumentReference orderRef in _bill!.orderRefs) {
          final orderSnap = await orderRef.get();
          if (!orderSnap.exists) continue;

          final orderData = orderSnap.data() as Map<String, dynamic>;
          final rawProducts = orderData['products'];

          if (rawProducts is List) {
            for (final item in rawProducts) {
              if (item is DocumentReference) {
                final productSnap = await item.get();
                if (productSnap.exists) {
                  final productData =
                      productSnap.data() as Map<String, dynamic>;
                  _allProductsInBill.add(
                    ProductOrderModel.fromJson(productData),
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
        SnackBar(content: Text('No hay cuenta abierta para esta mesa.')),
      );
      return;
    }

    try {
      // 1) Marcamos factura como “paid”
      final totalAPagar = _calculateBillTotal();
      await FirebaseFirestore.instance
          .collection('bills')
          .doc(_bill!.id)
          .update({
            'state': 'paid',
            'endTime': Timestamp.now(),
            'totalAmount': totalAPagar,
          });

      // 2) Marcamos mesa como “libre”
      await FirebaseFirestore.instance
          .collection('tables')
          .doc(widget.table.id)
          .update({'state': 'libre'});

      // 3) Borramos órdenes y productos asociados usando batch
      final WriteBatch batch = FirebaseFirestore.instance.batch();

      for (DocumentReference orderRef in _bill!.orderRefs) {
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

      // 4) Notificación de éxito y volver a lista de camareros
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pago procesado y datos borrados con éxito!')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => WaiterScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al procesar el pago: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Cargando Cuenta')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_bill == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Cuenta')),
        body: Center(
          child: Text(
            'No hay cuenta abierta para la mesa ${widget.table.number}',
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Cuenta de Mesa ${widget.table.number}')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Text(
                  'Detalles de la Cuenta',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 16),
                ..._allProductsInBill.map((product) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              ...product.addOns.map(
                                (addon) => Padding(
                                  padding: const EdgeInsets.only(top: 2.0),
                                  child: Text(
                                    "- $addon",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          '\$${product.price.values.first.toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 16, color: Colors.black),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                Divider(height: 32, color: Colors.grey),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total a Pagar:',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      '\$${_calculateBillTotal().toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
              right: 16,
              left: 16,
              top: 10,
              bottom: 48,
            ),
            child: ElevatedButton(
              onPressed: _processPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: Size(double.infinity, 60),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Procesar Pago',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
