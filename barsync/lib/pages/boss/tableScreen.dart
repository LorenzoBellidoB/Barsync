import 'package:barsync/components/menu.dart';
import 'package:barsync/models/tableModel.dart';
import 'package:barsync/utils/sesion.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TableLayoutScreen extends StatefulWidget {
  final DocumentReference restaurantRef = Session().restaurantRef;

  @override
  State<TableLayoutScreen> createState() => _TableLayoutScreenState();
}

class _TableLayoutScreenState extends State<TableLayoutScreen> {
  final GlobalKey _canvasKey = GlobalKey();
  List<TableModel> tables = [];
  bool addingMode = false;

  TableModel? selectedTable;

  Color getColorByDinners(int dinners) {
    return switch (dinners) {
      <= 0 => Colors.grey,
      <= 2 => Colors.green,
      <= 4 => Colors.blue,
      <= 6 => Colors.orange,
      _ => Colors.red, // Default
    };
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

  /// Convierte una posición global (en coordenadas de pantalla) a una posición local relativa al widget asociado a _canvasKey.
  /// Esto permite ubicar correctamente elementos dentro del canvas.
  Offset globalToLocal(Offset globalPos) {
    final renderBox =
        _canvasKey.currentContext!.findRenderObject() as RenderBox;
    return renderBox.globalToLocal(globalPos);
  }

  Future<void> onTapUp(TapUpDetails details) async {
    final local = globalToLocal(details.globalPosition);

    final newData = {
      'number': tables.length + 1,
      'dinners': 0,
      'state': 'libre',
      'location': {'x': local.dx, 'y': local.dy},
      'restaurant': widget.restaurantRef,
      'waiter': null,
      'currentOrder': null,
    };

    final newDoc = await FirebaseFirestore.instance
        .collection('tables')
        .add(newData);

    await newDoc.update({'id': newDoc.id});

    await widget.restaurantRef.update({
      'tables': FieldValue.arrayUnion([newDoc]),
    });
  }

  Future<void> updateTableLocation(TableModel table, Offset globalPos) async {
    final local = globalToLocal(globalPos);
    await FirebaseFirestore.instance.collection('tables').doc(table.id).update({
      'location': {'x': local.dx, 'y': local.dy},
    });
  }

  Future<void> deleteTable(TableModel t) async {
    await FirebaseFirestore.instance.collection('tables').doc(t.id).delete();
    await widget.restaurantRef.update({
      'tables': FieldValue.arrayRemove([
        FirebaseFirestore.instance.collection('tables').doc(t.id),
      ]),
    });
  }

  Widget buildDraggableTable(TableModel t) {
    final x = t.location['x'] ?? 0.0;
    final y = t.location['y'] ?? 0.0;

    return Positioned(
      left: x,
      top: y,
      child: GestureDetector(
        onLongPress: () {
          selectTable(t);
        },
        child: Draggable<TableModel>(
          data: t,
          feedback: buildTableWidget(t, dragging: true),
          childWhenDragging: Opacity(opacity: 0.3, child: buildTableWidget(t)),
          onDragEnd: (details) {
            updateTableLocation(t, details.offset);
          },
          child: buildTableWidget(t),
        ),
      ),
    );
  }

  Widget buildTableWidget(TableModel t, {bool dragging = false}) {
    return Container(
      width: 100,
      height: 100,
      child: Stack(
        children: [
          // Brazos en cruz
          Align(alignment: Alignment.topCenter, child: bar(20, 60, dragging)),
          Align(
            alignment: Alignment.bottomCenter,
            child: bar(20, 60, dragging),
          ),
          Align(alignment: Alignment.centerLeft, child: bar(60, 20, dragging)),
          Align(alignment: Alignment.centerRight, child: bar(60, 20, dragging)),

          // Círculo central
          Center(
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color:
                    dragging
                        ? getColorByDinners(t.dinners).withValues(alpha: 0.6)
                        : getColorByDinners(t.dinners),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '${t.number}',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
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
        elevation: 0,
        automaticallyImplyLeading:
            false, // Evita que Flutter reserve espacio para "leading"
        flexibleSpace: SafeArea(
          child: Padding(
            padding: EdgeInsets.only(left: 20, top: 12),
            child: Row(
              children: [
                Image.asset(
                  'assets/icons/barSyncApp.png',
                  width: 30,
                  height: 30,
                ),
                SizedBox(width: 8),
                Text(
                  'BarSync',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        backgroundColor: Color.fromRGBO(23, 23, 34, 1),
      ),
      body: Row(
        children: [
          Menu(role: 'Boss'),
          Expanded(
            child: GestureDetector(
              onTapUp: addingMode ? onTapUp : null,
              child: Container(
                key: _canvasKey,
                color: Colors.grey.shade100,
                width: double.infinity,
                height: double.infinity,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SizedBox(
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      child: Stack(
                        children: [
                          ...tables.map(buildDraggableTable).toList(),
                          if (selectedTable != null)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: buildEditPanel(),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: addingMode ? Colors.red : Colors.green,
        tooltip: addingMode ? 'Cancelar' : 'Añadir mesa',
        onPressed: () {
          setState(() {
            addingMode = !addingMode;
            selectedTable = null; // Oculta el panel si se está editando
          });
        },
        child: Icon(addingMode ? Icons.close : Icons.add),
      ),
    );
  }

  Widget buildEditPanel() {
    final numberController = TextEditingController(
      text: '${selectedTable!.number}',
    );
    final dinnersController = TextEditingController(
      text: '${selectedTable!.dinners}',
    );

    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        width: 300,
        height: 300,
        padding: const EdgeInsets.all(12),

        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Editar mesa',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => setState(() => selectedTable = null),
                ),
              ],
            ),
            const SizedBox(height: 16),

            TextField(
              controller: numberController,
              decoration: InputDecoration(labelText: 'Número'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            TextField(
              controller: dinnersController,
              decoration: InputDecoration(labelText: 'Comensales'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    final newNumber = int.tryParse(numberController.text);
                    final newDinners = int.tryParse(dinnersController.text);

                    if (newNumber != null && newDinners != null) {
                      await FirebaseFirestore.instance
                          .collection('tables')
                          .doc(selectedTable!.id)
                          .update({'number': newNumber, 'dinners': newDinners});

                      setState(() {
                        selectedTable = null;
                      });
                    }
                  },
                  icon: Icon(Icons.save),
                  label: Text('Guardar'),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    await deleteTable(selectedTable!);
                    setState(() {
                      selectedTable = null;
                    });
                  },
                  icon: Icon(Icons.delete),
                  label: Text('Eliminar'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
