import 'package:barsync/models/productOrderModel.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

class PrinterSelector {
  /// Escanea dispositivos Bluetooth por 4 segundos
  Future<List<BluetoothDevice>> scanDevices() async {
    // Si estás en Android 12+, antes de esto pide permisos con permission_handler
    final List<BluetoothDevice> devices = [];

    // 1) Nos suscribimos al Stream de resultados
    final subscription = FlutterBluePlus.scanResults.listen((results) {
      for (final result in results) {
        final device = result.device;
        // Comparamos remoteId (MAC). Ya no usamos 'name', usamos 'platformName'
        if (!devices.any((d) => d.remoteId == device.remoteId)) {
          devices.add(device);
          print(
            '→ Nuevo dispositivo: '
            '${device.platformName.isNotEmpty ? device.platformName : device.remoteId.str} '
            '(${device.remoteId.str})',
          );
        }
      }
    });

    // 2) Iniciamos escaneo por 4 segundos
    print('🔵 Iniciando escaneo Bluetooth por 8 seg...');
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 8));

    // 3) Esperamos 4 segundos
    await Future.delayed(const Duration(seconds: 4));

    // 4) Detenemos escaneo y cancelamos suscripción
    await FlutterBluePlus.stopScan();
    await subscription.cancel();

    // 5) Imprimimos el resumen final
    print('✅ Escaneo completado. Dispositivos encontrados: ${devices.length}');
    if (devices.isEmpty) {
      print('   (No se encontró ningún dispositivo)');
    } else {
      for (final d in devices) {
        print(
          ' • ${d.platformName.isNotEmpty ? d.platformName : d.remoteId.str} '
          '(${d.remoteId.str})',
        );
      }
    }

    return devices;
  }

  /// Conecta a la impresora mediante dirección MAC
  Future<bool> connectPrinter(String macAddress) async {
    final isConnected = await PrintBluetoothThermal.connect(
      macPrinterAddress: macAddress,
    );
    return isConnected;
  }

  /// Envía los bytes ESC/POS a la impresora
  Future<bool> writeBytes(List<int> bytes) async {
    final result = await PrintBluetoothThermal.writeBytes(bytes);
    return result;
  }
}

/// Construye el ticket de impresión
Future<List<int>> buildTicket({
  required List<ProductOrderModel> products,
  required double total,
  required String tableNumber,
}) async {
  final CapabilityProfile profile = await CapabilityProfile.load();
  final Generator generator = Generator(PaperSize.mm80, profile);

  final List<int> bytes = [];

  // Título centrado y en negrita
  bytes.addAll(
    generator.text(
      'Factura Mesa $tableNumber',
      styles: PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
      linesAfter: 1,
    ),
  );

  bytes.addAll(generator.hr());

  // Cada producto
  for (final product in products) {
    bytes.addAll(
      generator.row([
        PosColumn(text: product.name, width: 8),
        PosColumn(
          text: '\$${product.price.values.first.toStringAsFixed(2)}',
          width: 4,
          styles: PosStyles(align: PosAlign.right),
        ),
      ]),
    );

    // Si tiene add-ons, los listamos en letra más pequeña (fontB)
    for (final addon in product.addOns) {
      bytes.addAll(
        generator.text(
          '- $addon',
          styles: PosStyles(fontType: PosFontType.fontB, align: PosAlign.left),
        ),
      );
    }
  }

  bytes.addAll(generator.hr(ch: '=', linesAfter: 1));

  // Fila del total en negrita
  bytes.addAll(
    generator.row([
      PosColumn(text: 'TOTAL', width: 8, styles: PosStyles(bold: true)),
      PosColumn(
        text: '\$${total.toStringAsFixed(2)}',
        width: 4,
        styles: PosStyles(bold: true, align: PosAlign.right),
      ),
    ]),
  );

  bytes.addAll(generator.feed(2));
  bytes.addAll(generator.cut());

  return bytes;
}

/// Devuelve una cadena de texto “simulada” de cómo quedaría el ticket.
String buildTicketTextPreview({
  required List<ProductOrderModel> products,
  required double total,
  required String tableNumber,
}) {
  final buffer = StringBuffer();

  buffer.writeln('========== FACTURA MESA $tableNumber ==========');
  buffer.writeln('');

  for (final product in products) {
    final price = product.price.values.first.toStringAsFixed(2);
    buffer.writeln('${product.name.padRight(30)} \$${price.padLeft(6)}');

    // Mostrar add-ons, si los hubiera
    for (final addon in product.addOns) {
      buffer.writeln('  - $addon');
    }
  }

  buffer.writeln('');
  buffer.writeln('==============================================');
  buffer.writeln(
    'TOTAL'.padRight(30) + ' \$${total.toStringAsFixed(2).padLeft(6)}',
  );
  buffer.writeln('==============================================');

  return buffer.toString();
}
