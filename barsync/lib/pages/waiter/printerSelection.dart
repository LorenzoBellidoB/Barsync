import 'package:barsync/utils/print.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class PrinterSelectionScreen extends StatefulWidget {
  final Function(String mac) onSelected;
  PrinterSelectionScreen({required this.onSelected});

  @override
  State<PrinterSelectionScreen> createState() => _PrinterSelectionScreenState();
}

class _PrinterSelectionScreenState extends State<PrinterSelectionScreen> {
  final selector = PrinterSelector();
  List<BluetoothDevice> _devices = [];
  bool _scanning = true;

  @override
  void initState() {
    super.initState();
    selector.scanDevices().then((list) {
      setState(() {
        _devices = list;
        _scanning = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Seleccionar impresora')),
      body:
          _scanning
              ? Center(child: CircularProgressIndicator())
              : ListView.builder(
                itemCount: _devices.length,
                itemBuilder: (_, i) {
                  final d = _devices[i];
                  return ListTile(
                    title: Text(d.advName.isEmpty ? d.remoteId.str : d.advName),
                    subtitle: Text(d.remoteId.str),
                    onTap: () => widget.onSelected(d.remoteId.str),
                  );
                },
              ),
    );
  }
}
