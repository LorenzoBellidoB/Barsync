import 'package:flutter/material.dart';

class RoomsScreen extends StatefulWidget {
  const RoomsScreen({super.key});

  @override
  _RoomsScreenState createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  @override
  Widget build(BuildContext context) {
    return Container(child: Center(child: Text('Salas')));
  }
}
