import 'package:flutter/material.dart';

class KitchenScreen extends StatefulWidget {
  const KitchenScreen({super.key});

  @override
  _KitchenScreenState createState() => _KitchenScreenState();
}

class _KitchenScreenState extends State<KitchenScreen> {
  @override
  Widget build(BuildContext context) {
    return Container(child: Center(child: Text('Cocina')));
  }
}
