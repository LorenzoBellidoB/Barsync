import 'dart:io';

import 'package:barsync/models/billModel.dart';
import 'package:barsync/models/printModel.dart';
import 'package:barsync/models/productOrderModel.dart';
import 'package:barsync/models/restaurantModel.dart';
import 'package:barsync/models/tableModel.dart';
import 'package:barsync/pages/waiter/printerSelection.dart';
import 'package:barsync/pages/waiter/waiterScreen.dart';
import 'package:barsync/services/database/databaseManager.dart';
import 'package:barsync/utils/print.dart';
import 'package:barsync/utils/sesion.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:esc_pos_printer_plus/esc_pos_printer_plus.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class BillingScreen extends StatefulWidget {
  final TableModel table;
  final String waiter;

  const BillingScreen({super.key, required this.table, required this.waiter});

  @override
  _BillingScreenState createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  BillModel? _bill;
  final List<ProductOrderModel> _allProductsInBill = [];
  bool _isLoading = true;
  WifiPrinter? _selectedPrinter;
  late RestaurantModel restaurant;

  @override
  void initState() {
    super.initState();
    _fetchBillDetails();
  }

  Future<void> _fetchBillDetails() async {
    setState(() => _isLoading = true);
    try {
      restaurant = await getRestaurantById(Session().restaurantRef.id);
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

  // This function is for ESC/POS printers. Keep it only if you plan to support them.
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

  // This function is for ESC/POS printers. Keep it only if you plan to support them.
  Future<void> _printBill() async {
    if (_selectedPrinter == null) {
      print('❌ Selecciona una impresora Wi-Fi');
      return;
    }

    String ip;

    try {
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

  // CORRECTED: _printBillPdf function
  Future<void> _printBillPdf(String tableNumber, RestaurantModel restaurant) async {
    final doc = pw.Document(); // Crea un nuevo documento PDF

    // Para agrupar productos por cantidad si aparecen múltiples veces
    final Map<String, int> productQuantities = {};
    final Map<String, ProductOrderModel> productDetails = {};

    for (final p in _allProductsInBill) {
      final key = '${p.name}_${p.addOns.join(',')}'; // Clave para agrupar (nombre + add-ons)
      productQuantities[key] = (productQuantities[key] ?? 0) + 1;
      productDetails[key] = p; // Guardamos el detalle del producto original
    }

    // Contenido del PDF
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80, // Formato de rollo de 80mm
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  restaurant.name,
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  restaurant.cif,
                  style: pw.TextStyle(
                    fontSize: 10,
                  ),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  restaurant.address,
                  style: pw.TextStyle(
                    fontSize: 10,
                  ),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  'Tlf: ${restaurant.phone}',
                  style: pw.TextStyle(
                    fontSize: 10,
                  ),
                ),
              ),
              pw.Align(
                alignment: pw.Alignment.topLeft,
                child: pw.Text(
                  'Mesa: $tableNumber',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                )),
              pw.SizedBox(height: 6),
                pw.Align(
                alignment: pw.Alignment.topLeft,
                child: pw.Text(
                  'Factura simplificada: ${_bill?.id}',
                  style: pw.TextStyle(
                    fontSize: 8,
                  ),
                )),
              pw.SizedBox(height: 10),
              pw.Divider(),
              pw.SizedBox(height: 10),

              // Productos (agrupados)
              // Aquí es donde se hizo la corrección:
              ...productQuantities.entries.map((entry) { // Usamos .map para transformar cada entrada en un Widget
                final key = entry.key;
                final quantity = entry.value;
                final p = productDetails[key]!; // Obtenemos los detalles del producto

                return pw.Column( // Envuelve los elementos de cada producto en un Column de PDF
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Expanded(
                          child: pw.Text(
                            '$quantity  ${p.name}',
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ),
                        pw.Text(
                          '${(p.price.values.first * quantity).toStringAsFixed(2)} EUR',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                    if (p.addOns.isNotEmpty) // Mostrar add-ons si existen
                      for (final addon in p.addOns)
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(left: 10),
                          child: pw.Text(
                            '- $addon',
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                        ),
                    pw.SizedBox(height: 5), // Espacio entre productos
                  ],
                );
              }), // Cierre del .map

              pw.SizedBox(height: 10),
              pw.Divider(borderStyle: pw.BorderStyle.dashed), // Línea divisoria
              pw.SizedBox(height: 10),

              // Total
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'TOTAL',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    '${_calculateBillTotal().toStringAsFixed(2)} EUR',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
               
                pw.Align(
                alignment: pw.Alignment.topLeft,
                child: pw.Text(
                  'Atendido por: ${widget.waiter}',
                  style: const pw.TextStyle(fontSize: 10),
                )),
                pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Text(
                  '¡Gracias por su visita!',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
               pw.Center(
                child: pw.Text(
                  'I.V.A incluido',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
            ],
          );
        },
      ),
    );

    // Muestra la vista previa de impresión y permite al usuario seleccionar la impresora
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Ticket_Mesa_${tableNumber}_${DateTime.now().millisecondsSinceEpoch}.pdf', // Nombre del archivo sugerido
    );

    print('✅ PDF del ticket generado y enviado al sistema de impresión.');
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
                }),

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

          // Botones (opción más simple: solo imprimir PDF y procesar pago)
          Container(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 48),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _printBillPdf(widget.table.number.toString(), restaurant);
                    },
                    icon: const Icon(Icons.print, color: Colors.white),
                    label: const Text('Imprimir Ticket (PDF)', style: TextStyle(color: Colors.white, overflow: TextOverflow.ellipsis)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await _processPayment();
                    },
                    icon: const Icon(Icons.check_circle_outline, color: Colors.white,),
                    label: const Text('Procesar Pago', style: TextStyle(color: Colors.white ,overflow: TextOverflow.ellipsis),),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
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