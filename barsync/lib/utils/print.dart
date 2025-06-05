import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

Future<List<int>> generateTicket() async {
  final profile = await CapabilityProfile.load();
  final generator = Generator(PaperSize.mm80, profile);
  List<int> bytes = [];

  bytes += generator.text(
    'Restaurante XYZ',
    styles: PosStyles(align: PosAlign.center, bold: true),
  );
  bytes += generator.text('Mesa: 5');
  bytes += generator.text('Fecha: 2025-06-05 19:22');
  bytes += generator.hr();
  bytes += generator.row([
    PosColumn(text: 'Producto', width: 6),
    PosColumn(text: 'Cant', width: 2),
    PosColumn(
      text: 'Precio',
      width: 4,
      styles: PosStyles(align: PosAlign.right),
    ),
  ]);
  bytes += generator.row([
    PosColumn(text: 'Pizza', width: 6),
    PosColumn(text: '1', width: 2),
    PosColumn(
      text: '10.00 EUR',
      width: 4,
      styles: PosStyles(align: PosAlign.right),
    ),
  ]);
  bytes += generator.hr();
  bytes += generator.text(
    'Total: 10.00 EUR',
    styles: PosStyles(align: PosAlign.right, bold: true),
  );
  bytes += generator.feed(2);
  bytes += generator.cut();

  return bytes;
}

void printTicket(List<int> bytes) async {
  final result = await PrintBluetoothThermal.writeBytes(bytes);
  if (result) {
    print('Impresión exitosa');
  } else {
    print('Error en la impresión');
  }
}
