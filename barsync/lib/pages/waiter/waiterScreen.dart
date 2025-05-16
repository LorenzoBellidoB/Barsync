import 'package:barsync/models/tableModel.dart';
import 'package:barsync/models/userModel.dart';
import 'package:barsync/pages/waiter/createOrder.dart';
import 'package:barsync/services/database/dataBaseManager.dart'
    as dataBaseManager;
import 'package:barsync/utils/sesion.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class WaiterScreen extends StatefulWidget {
  final DocumentReference restaurantRef = Session().restaurantRef;

  @override
  State<WaiterScreen> createState() => _WaiterScreenState();
}

class _WaiterScreenState extends State<WaiterScreen> {
  List<TableModel> tables = [];

  TableModel? selectedTable;

  Color getColorByDinners(int dinners, String? state) {
    switch (state) {
      case 'ocupado':
        return Colors.red;
      case 'reservado':
        return Colors.purple;
      case 'libre':
        return Colors.green;
      // Puedes agregar más estados si es necesario
      case null:
      default:
        return Colors.grey;
    }
  }

  void selectTable(TableModel table) {
    setState(() {
      selectedTable = table;
    });
  }

  @override
  void initState() {
    super.initState();
    listenTables();
  }

  void listenTables() {
    FirebaseFirestore.instance
        .collection('tables')
        .where('restaurant', isEqualTo: widget.restaurantRef)
        .orderBy('number')
        .snapshots()
        .listen((snap) {
          setState(() {
            tables =
                snap.docs.map((doc) {
                  final data = doc.data();
                  return TableModel.fromJson({...data, 'id': doc.id});
                }).toList();
          });
        });
  }

  Widget buildTableWidget(TableModel t, {bool dragging = false}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double size = constraints.maxWidth;

        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: bar(size * 0.2, size * 0.6, dragging),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: bar(size * 0.2, size * 0.6, dragging),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: bar(size * 0.6, size * 0.2, dragging),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: bar(size * 0.6, size * 0.2, dragging),
              ),
              Center(
                child: Container(
                  width: size * 0.6,
                  height: size * 0.6,
                  decoration: BoxDecoration(
                    color:
                        dragging
                            ? getColorByDinners(t.dinners, t.state).withAlpha(6)
                            : getColorByDinners(t.dinners, t.state),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${t.number}',
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget bar(double width, double height, bool dragging) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: dragging ? Colors.blueGrey.withAlpha(6) : Colors.blueGrey[800],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

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
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1,
                ),
                itemCount: tables.length,
                itemBuilder: (context, index) {
                  final table = tables[index];
                  return GestureDetector(
                    onTap: () => selectTable(table),
                    child: buildTableWidget(table),
                  );
                },
              ),
            ),
          ),

          // Panel inferior (solo si hay mesa seleccionada)
          if (selectedTable != null && selectedTable?.state != 'ocupado')
            buildPanel(),
        ],
      ),
    );
  }

  Widget buildPanel() {
    final dinnersController = TextEditingController(
      text: '${selectedTable!.dinners}',
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color.fromRGBO(23, 23, 34, 1),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Mesa ${selectedTable?.number} ${selectedTable?.state == "reservado" ? "(Reservado)" : ""}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.white),
                  onPressed: () => setState(() => selectedTable = null),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              style: TextStyle(color: Colors.white),
              controller: dinnersController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                filled: true,
                fillColor: Color.fromRGBO(35, 35, 50, 1),
                labelText: 'Comensales',
                labelStyle: TextStyle(color: Colors.white70),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white24),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blueAccent),
                ),
              ),
            ),

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent, // Azul brillante
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () async {
                    final newDinners = int.tryParse(dinnersController.text);
                    DocumentReference user = dataBaseManager.getUserById(
                      Session().currentUser,
                    );
                    if (newDinners != null) {
                      DocumentReference orderRef = await dataBaseManager
                          .createOrder(
                            user,
                            selectedTable!.id,
                            selectedTable!.idRestaurant,
                          );
                      await FirebaseFirestore.instance
                          .collection('tables')
                          .doc(selectedTable!.id)
                          .update({
                            'dinners': newDinners,
                            'state': 'ocupado',
                            'waiter': user,
                            'currentOrder': orderRef,
                          });

                      setState(() => selectedTable = null);
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateOrderScreen(),
                      ),
                    );
                  },
                  icon: Icon(Icons.receipt_long),
                  label: Text('Realizar comanda'),
                ),
              ],
            ),
            SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}
