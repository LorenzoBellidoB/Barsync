import 'package:barsync/models/tableModel.dart';
import 'package:barsync/pages/waiter/createOrder.dart';
import 'package:barsync/services/database/dataBaseManager.dart';
import 'package:barsync/utils/sesion.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class WaiterScreen extends StatefulWidget {
  final DocumentReference restaurantRef = Session().restaurantRef;

  WaiterScreen({super.key});

  @override
  State<WaiterScreen> createState() => _WaiterScreenState();
}

class _WaiterScreenState extends State<WaiterScreen>
    with SingleTickerProviderStateMixin {
  TableModel? _selectedTable;

  late TabController _tabController;

  @override
  /// Inicializa el estado del widget creando un TabController para dos pestañas: "Mesas" y "Barra".
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  /// Cancela la suscripci n al TabController y llama a `super.dispose()`
  /// para liberar cualquier otro recurso que el widget pueda estar utilizando.
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Selecciona una mesa y actualiza el estado de `_selectedTable` para que muestre
  /// su informaci n en el panel inferior. Se utiliza al hacer un LongPress en una
  /// mesa en el canvas.
  //
  /// Actualiza el estado de `_selectedTable` con el valor de `table`.

  void _selectTable(TableModel table) {
    setState(() => _selectedTable = table);
  }

  /// Limpia la selección actual de mesa y oculta el panel inferior.
  ///
  /// Se utiliza al hacer un tap en el bot n "Cerrar" en el panel inferior.
  ///
  /// Actualiza el estado de `_selectedTable` a `null`.
  void _clearSelection() {
    setState(() => _selectedTable = null);
  }

  /// Devuelve `true` si el panel inferior debe mostrarse y `false` en caso
  /// contrario. El panel se muestra solo si la mesa seleccionada no est  ocupada
  /// o si el camarero actual atiende esa mesa.
  bool _shouldShowPanel() {
    if (_selectedTable == null) return false;
    final table = _selectedTable!;
    final currentUser = Session().currentUser;
    return table.state != 'ocupado' || table.waiter?.id == currentUser.id;
  }

  /// Maneja el evento de tap en una mesa del canvas. Si el camarero actual
  /// atiende esa mesa, va directamente a la pantalla de orden. Si no est  ocupada,
  /// la selecciona para mostrar su informaci n en el panel inferior.
  void _onTableTap(TableModel table) {
    final currentUser = Session().currentUser;

    if (table.state == 'ocupado' && table.waiter?.id == currentUser.id) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => OrderScreen(table: table)),
      );
    } else if (table.state != 'ocupado') {
      _selectTable(table);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(23, 23, 34, 1),
        elevation: 0,
        automaticallyImplyLeading: false,
        flexibleSpace: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(left: 12.0, top: 12),
            child: Row(
              children: [
                Image.asset(
                  'assets/icons/barSyncApp.png',
                  width: 20,
                  height: 20,
                ),
                const SizedBox(width: 8),
                const Text(
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.table_restaurant, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Mesas',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_bar, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Barra',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('tables')
                        .where('restaurant', isEqualTo: widget.restaurantRef)
                        .orderBy('number')
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text('Error al cargar datos'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final allTables =
                      snapshot.data!.docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return TableModel.fromJson({...data, 'id': doc.id});
                      }).toList();

                  final mesas =
                      allTables
                          .where((t) => t.type.toLowerCase() == 'mesa')
                          .toList();
                  final taburetes =
                      allTables
                          .where((t) => t.type.toLowerCase() == 'taburete')
                          .toList();

                  return TabBarView(
                    controller: _tabController,
                    children: [
                      GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 1,
                            ),
                        itemCount: mesas.length,
                        itemBuilder: (context, index) {
                          final table = mesas[index];
                          return GestureDetector(
                            onTap: () => _onTableTap(table),
                            child: _TableWidget(
                              table: table,
                              isSelected: _selectedTable?.id == table.id,
                            ),
                          );
                        },
                      ),

                      GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 1,
                            ),
                        itemCount: taburetes.length,
                        itemBuilder: (context, index) {
                          final stool = taburetes[index];
                          return GestureDetector(
                            onTap: () => _onTableTap(stool),
                            child: _StoolWidget(
                              table: stool,
                              isSelected: _selectedTable?.id == stool.id,
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          if (_shouldShowPanel())
            _BottomPanel(table: _selectedTable!, onClose: _clearSelection),
        ],
      ),
    );
  }
}

class _TableWidget extends StatelessWidget {
  final TableModel table;
  final bool isSelected;

  const _TableWidget({super.key, required this.table, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth;
        final dragging = isSelected;

        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: _bar(size * 0.2, size * 0.6, dragging),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: _bar(size * 0.2, size * 0.6, dragging),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: _bar(size * 0.6, size * 0.2, dragging),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: _bar(size * 0.6, size * 0.2, dragging),
              ),
              Center(
                child: Container(
                  width: size * 0.6,
                  height: size * 0.6,
                  decoration: BoxDecoration(
                    color: _TableColor.getColor(
                      dinners: table.dinners,
                      state: table.state,
                      selected: dragging,
                    ),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${table.number}',
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

  Widget _bar(double width, double height, bool selected) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: selected ? Colors.blueGrey.withAlpha(6) : Colors.blueGrey[800],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _StoolWidget extends StatelessWidget {
  final TableModel table;
  final bool isSelected;

  const _StoolWidget({super.key, required this.table, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth;
        final selected = isSelected;
        final color = _TableColor.getColor(
          dinners: table.dinners,
          state: table.state,
          selected: selected,
        );

        return Center(
          child: Container(
            width: size * 0.6,
            height: size * 0.6,
            decoration: BoxDecoration(
              color: selected ? color.withAlpha(6) : color,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '${table.number}',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        );
      },
    );
  }
}

class _TableColor {
  static Color getColor({
    required int dinners,
    required String? state,
    required bool selected,
  }) {
    Color base;
    switch (state) {
      case 'ocupado':
        base = Colors.red;
        break;
      case 'reservado':
        base = Colors.purple;
        break;
      case 'libre':
        base = Colors.green;
        break;
      default:
        base = Colors.grey;
    }
    return selected ? base.withAlpha(6) : base;
  }
}

class _BottomPanel extends StatefulWidget {
  final TableModel table;
  final VoidCallback onClose;

  const _BottomPanel({super.key, required this.table, required this.onClose});

  @override
  State<_BottomPanel> createState() => __BottomPanelState();
}

class __BottomPanelState extends State<_BottomPanel> {
  late TextEditingController _dinnersController;

  @override
  void initState() {
    super.initState();
    _dinnersController = TextEditingController(text: '${widget.table.dinners}');
  }

  @override
  void dispose() {
    _dinnersController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final table = widget.table;
    final isReserved = table.state == 'reservado';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color.fromRGBO(23, 23, 34, 1),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(table),
            const SizedBox(height: 16),
            _buildDinnersField(),
            const SizedBox(height: 24),
            _buildActionButton(table),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(TableModel t) {
    return Row(
      children: [
        Text(
          '${t.type} ${t.number} ${t.state == "Reservado" ? "(Reservado)" : ""}',

          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: widget.onClose,
        ),
      ],
    );
  }

  Widget _buildDinnersField() {
    return TextField(
      style: const TextStyle(color: Colors.white),
      controller: _dinnersController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color.fromRGBO(35, 35, 50, 1),
        labelText: 'Comensales',
        labelStyle: const TextStyle(color: Colors.white70),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blueAccent),
        ),
      ),
    );
  }

  Widget _buildActionButton(TableModel table) {
    final isReserved = table.state == 'reservado';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          onPressed: () => _onMakeOrder(table),
          icon: const Icon(Icons.receipt_long),
          label: const Text('Realizar comanda'),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          onPressed: () async {
            final newState = isReserved ? 'libre' : 'reservado';
            table.state = newState;

            final tableRef = FirebaseFirestore.instance
                .collection('tables')
                .doc(table.id);

            await tableRef.update({'state': newState});
            widget.onClose(); // Cierra el panel después de la acción
          },
          icon: Icon(isReserved ? Icons.cancel : Icons.bookmark_add_outlined),
          label: Text(isReserved ? 'Cancelar' : 'Reservar'),
        ),
      ],
    );
  }

  /// Realiza una comanda en la mesa [table].
  ///
  /// Primero, actualiza la cantidad de comensales y el estado de la mesa
  /// a "ocupado". Luego, si hay alguna factura anterior en estado "paid",
  /// la elimina. Finalmente, navega a la pantalla de creación de pedido.
  ///
  Future<void> _onMakeOrder(TableModel table) async {
    final newDinners = int.tryParse(_dinnersController.text);
    if (newDinners == null) return;

    final userRef = getUserById(Session().currentUser);
    final tableRef = FirebaseFirestore.instance
        .collection('tables')
        .doc(table.id);

    await tableRef.update({
      'dinners': newDinners,
      'state': 'ocupado',
      'waiter': userRef,
    });

    try {
      final querySnap =
          await FirebaseFirestore.instance
              .collection('bills')
              .where('table', isEqualTo: getTableRefById(table.id))
              .where('state', isEqualTo: 'paid')
              .limit(1)
              .get();

      if (querySnap.docs.isNotEmpty) {
        await querySnap.docs.first.reference.delete();
      }
    } catch (e) {}

    widget.onClose();

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => OrderScreen(table: table)),
    );
  }
}
