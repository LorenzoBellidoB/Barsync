import 'package:flutter/material.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromRGBO(23, 23, 34, 1),
        elevation: 0,
        automaticallyImplyLeading:
            false, // Evita que Flutter reserve espacio para "leading"
        flexibleSpace: SafeArea(
          child: Padding(
            padding: EdgeInsets.only(left: 12.0, top: 12),
            child: Row(
              children: [
                Image.asset(
                  'assets/icons/barSyncApp.png',
                  width: 20,
                  height: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'BarSync',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
