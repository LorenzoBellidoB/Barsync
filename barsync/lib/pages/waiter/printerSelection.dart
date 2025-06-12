// import 'dart:io';

// import 'package:barsync/models/printModel.dart';
// import 'package:flutter/material.dart';
// import 'package:multicast_dns/multicast_dns.dart';

// class WifiPrinterSelectionScreen extends StatefulWidget {
//   final Function(WifiPrinter) onSelected;
//   const WifiPrinterSelectionScreen({super.key, required this.onSelected});
//   @override
//   _WifiPrinterSelectionScreenState createState() =>
//       _WifiPrinterSelectionScreenState();
// }

// class _WifiPrinterSelectionScreenState
//     extends State<WifiPrinterSelectionScreen> {
//   bool _scanning = true;
//   final List<WifiPrinter> _printers = [];

//   @override
//   void initState() {
//     super.initState();
//     _discoverPrinters();
//   }

//   Future<void> _discoverPrinters() async {
//   final mdns = MDnsClient();

//   try {
//     await mdns.start();
//   } on SocketException catch (e) {
//     // Android no soporta reusePort: true internamente, lo ignoramos
//     print('⚠️ MDNS start warning (ignorado): $e');
//   }

//   // Ya sea que start() funcionase o no, seguimos intentando el lookup
//   try {
//     await for (final PtrResourceRecord ptr in mdns.lookup<PtrResourceRecord>(
//       ResourceRecordQuery.serverPointer('_printer._tcp.local'),
//     )) {
//       await for (final SrvResourceRecord srv in mdns.lookup<SrvResourceRecord>(
//         ResourceRecordQuery.service(ptr.domainName),
//       )) {
//         setState(() {
//           _printers.add(WifiPrinter(
//             name: ptr.domainName,
//             host: srv.target,
//             port: srv.port,
//           ));
//         });
//       }
//     }
//   } catch (e) {
//     print('Error durante MDNS lookup: $e');
//   } finally {
//     mdns.stop();
//     setState(() => _scanning = false);
//   }
// }

//  @override
// Widget build(BuildContext context) {
//   return Scaffold(
//     appBar: AppBar(
//       title: const Text('Seleccionar impresora Wi-Fi'),
//       centerTitle: true,
//     ),
//     body: _scanning
//         ? const Center(child: CircularProgressIndicator())
//         : _printers.isEmpty
//             ? const Center(
//                 child: Text(
//                   'No se encontraron impresoras',
//                   style: TextStyle(fontSize: 16, color: Colors.grey),
//                 ),
//               )
//             : ListView.builder(
//                 padding: const EdgeInsets.all(12),
//                 itemCount: _printers.length,
//                 itemBuilder: (_, i) {
//                   final printer = _printers[i];
//                   return Card(
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     elevation: 3,
//                     margin: const EdgeInsets.symmetric(vertical: 8),
//                     child: ListTile(
//                       leading: const Icon(Icons.print, color: Colors.blue),
//                       title: Text(
//                         printer.name,
//                         style: const TextStyle(
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       subtitle: Text('${printer.host}:${printer.port}'),
//                       trailing: const Icon(Icons.arrow_forward_ios, size: 16),
//                       onTap: () => widget.onSelected(printer),
//                     ),
//                   );
//                 },
//               ),
//   );
// }

// }
