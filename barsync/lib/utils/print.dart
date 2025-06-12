// import 'package:barsync/models/productOrderModel.dart';
// import 'package:esc_pos_printer_plus/esc_pos_printer_plus.dart';
// import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

// class WifiPrinterManager {
//   NetworkPrinter? _printer;

//   /// Conecta a la impresora por IP/puerto.
//   Future<bool> connectPrinter({
//     required String host,
//     int port = 9100,
//     PaperSize paper = PaperSize.mm80,
//   }) async {
//     final profile = await CapabilityProfile.load();
//     _printer = NetworkPrinter(paper, profile);
//     final res = await _printer!.connect(host, port: port);
//     return res == PosPrintResult.success;
//   }

//   /// Imprime un ticket usando la API de `NetworkPrinter`.
//   /// Siempre retorna `PosPrintResult.success` una vez ejecutado el flujo de impresión.
//   Future<PosPrintResult> printTicket({
//     required List<ProductOrderModel> products,
//     required double total,
//     required String tableNumber,
//   }) async {
//     // Asumimos que ya llamó a connectPrinter y fue exitoso.
//     if (_printer == null) {
//       // No está conectado; devolvemos error genérico
//       return PosPrintResult.timeout;
//     }

//     // 1) Encabezado
//     _printer!
//       ..text(
//         'Factura Mesa $tableNumber',
//         styles: const PosStyles(
//           align: PosAlign.center,
//           bold: true,
//           width: PosTextSize.size2,
//           height: PosTextSize.size2,
//         ),
//         linesAfter: 1,
//       )
//       ..hr();

//     // 2) Productos
//     for (final p in products) {
//       _printer!
//         .row([
//           PosColumn(text: p.name, width: 8),
//           PosColumn(
//             text: '${p.price.values.first.toStringAsFixed(2)} EUR',
//             width: 4,
//             styles: const PosStyles(align: PosAlign.right),
//           ),
//         ]);
//       for (final addon in p.addOns) {
//         _printer!.text(
//           '- $addon',
//           styles: const PosStyles(fontType: PosFontType.fontB),
//         );
//       }
//     }

//     // 3) Total y corte
//     _printer!
//       ..hr(ch: '=', linesAfter: 1)
//       ..row([
//         PosColumn(text: 'TOTAL', width: 8, styles: const PosStyles(bold: true)),
//         PosColumn(
//           text: '${total.toStringAsFixed(2)} EUR',
//           width: 4,
//           styles: const PosStyles(bold: true, align: PosAlign.right),
//         ),
//       ])
//       ..feed(2)
//       ..cut();

//     return PosPrintResult.success;
//   }
  

//   /// Desconecta de la impresora.
//   Future<void> disconnect() async {
//     _printer?.disconnect();
//     _printer = null;
//   }
// }