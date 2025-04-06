import 'package:flutter/material.dart';

class BossScreen extends StatefulWidget {
  const BossScreen({super.key});

  @override
  _BossScreenState createState() => _BossScreenState();
}

class _BossScreenState extends State<BossScreen> {
  @override
  Widget build(BuildContext context) {
    return Container(child: Center(child: Text('Jefe')));
  }
}
