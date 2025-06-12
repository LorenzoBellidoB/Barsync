import 'package:barsync/components/menu.dart';
import 'package:barsync/models/barModel.dart';
import 'package:barsync/models/tableModel.dart';
import 'package:barsync/services/database/databaseManager.dart';
import 'package:barsync/utils/sesion.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TableLayoutScreen extends StatefulWidget {
  final DocumentReference restaurantRef = Session().restaurantRef;

  TableLayoutScreen({super.key});

  @override
  State<TableLayoutScreen> createState() => _TableLayoutScreenState();
}

class _TableLayoutScreenState extends State<TableLayoutScreen> {
  final GlobalKey _canvasKey = GlobalKey();

  List<TableModel> _tables = [];
  List<BarModel> _bars = [];

  bool _addingMode = false;
  bool _addingStoolMode = false;
  bool _addingBarMode = false;

  TableModel? _selectedTable;
  BarModel? _selectedBar;

  // Controladores para el panel de edición:
  late TextEditingController _numberController;
  late TextEditingController _dinnersController;
  String _tipoValue = 'mesa';

  late TextEditingController _barWidthController;
  late TextEditingController _barHeightController;
  int _barRotationValue = 0; // 0 = horizontal, 90 = vertical

  @override
  void initState() {
    super.initState();
    _listenTables();
    _listenBars();
  }

  /// Escucha en tiempo real la colección de "mesas", filtrando por la referencia del restaurante.
  /// Actualiza el estado de `_tables` con la lista de mesas cada vez que hay un cambio en la colección.

  void _listenTables() {
    FirebaseFirestore.instance
        .collection('tables')
        .where('restaurant', isEqualTo: widget.restaurantRef)
        .snapshots()
        .listen((snap) {
          final temp =
              snap.docs.map((doc) {
                final data = doc.data();
                return TableModel.fromJson({...data, 'id': doc.id});
              }).toList();
          setState(() {
            _tables = temp;
          });
        });
  }

  /// Escucha en tiempo real la colección de "bars", filtrando por la referencia del
  /// restaurante. Actualiza el estado de `_bars` con la lista de barras cada vez que
  /// hay un cambio en la colección.
  void _listenBars() {
    FirebaseFirestore.instance
        .collection('bars')
        .where('restaurant', isEqualTo: widget.restaurantRef)
        .snapshots()
        .listen((snap) {
          final barsList =
              snap.docs.map((doc) {
                final data = doc.data();
                return BarModel.fromJson({...data, 'id': doc.id});
              }).toList();

          setState(() {
            _bars = barsList;
          });
        });
  }

  /// Pasa de coordenada global (pantalla) a local dentro de _canvasKey
  Offset _globalToLocal(Offset globalPos) {
    final renderBox =
        _canvasKey.currentContext!.findRenderObject() as RenderBox;
    return renderBox.globalToLocal(globalPos);
  }

  /// Gestiona el evento de tapUp en el canvas. Si estamos en modo "añadir mesa/taburete"
  /// o "añadir barra", crea un nuevo documento en la colección correspondiente
  /// con los datos pertinentes. Si estamos en modo "añadir barra", desactiva el modo
  /// "añadir barra" después de crear la barra.
  Future<void> _onTapUp(TapUpDetails details) async {
    final local = _globalToLocal(details.globalPosition);

    if (_addingMode) {
      final tipo = _addingStoolMode ? 'Taburete' : 'Mesa';
      final nuevos = _tables.where((t) => t.type == tipo).length + 1;

      final newData = {
        'number': nuevos,
        'dinners': 0,
        'state': 'libre',
        'location': {'x': local.dx, 'y': local.dy},
        'restaurant': widget.restaurantRef,
        'waiter': null,
        'currentOrder': null,
        'type': tipo,
      };

      final newDocRef = await FirebaseFirestore.instance
          .collection('tables')
          .add(newData);
      await newDocRef.update({'id': newDocRef.id});
    } else if (_addingBarMode) {
      final defaultWidth = 200.0;
      final defaultHeight = 30.0;
      final defaultRotation = 0;

      final dataBar = {
        'location': {'x': local.dx, 'y': local.dy},
        'restaurant': widget.restaurantRef,
        'width': defaultWidth,
        'height': defaultHeight,
        'rotation': defaultRotation,
      };

      final newBarRef = await FirebaseFirestore.instance
          .collection('bars')
          .add(dataBar);
      await newBarRef.update({'id': newBarRef.id});

      setState(() {
        _addingBarMode = false;
      });
    }
  }

  /// Actualiza la posición de la mesa/taburete tras soltar (drag end)
  Future<void> _updateTableLocation(TableModel t, Offset globalPos) async {
    final local = _globalToLocal(globalPos);
    await FirebaseFirestore.instance.collection('tables').doc(t.id).update({
      'location': {'x': local.dx, 'y': local.dy},
    });
  }

  Color _getColorByDinners(int dinners) {
    return switch (dinners) {
      <= 0 => Colors.grey,
      <= 2 => Colors.green,
      <= 4 => Colors.blue,
      <= 6 => Colors.orange,
      _ => Colors.red,
    };
  }

  /// Selecciona una mesa/taburete y actualiza los campos de edici n en el panel
  /// inferior. Se utiliza al hacer un LongPress en una mesa/taburete en el canvas.
  ///
  /// Actualiza el estado de _selectedTable, _numberController,
  /// _dinnersController y _tipoValue con los valores de t.
  void _selectTable(TableModel t) {
    setState(() {
      _selectedTable = t;
      _numberController = TextEditingController(text: '${t.number}');
      _dinnersController = TextEditingController(text: '${t.dinners}');
      _tipoValue = t.type;
    });
  }

  Future<void> _updateBarLocation(BarModel bar, Offset globalPos) async {
    final local = _globalToLocal(globalPos);
    await FirebaseFirestore.instance.collection('bars').doc(bar.id).update({
      'location': {'x': local.dx, 'y': local.dy},
    });
  }

  /// Selecciona una barra y actualiza los campos de edicion en el panel
  /// inferior. Se utiliza al hacer un LongPress en una barra en el canvas.
  ///
  /// Actualiza el estado de _selectedBar, _barWidthController,
  /// _barHeightController y _barRotationValue con los valores de bar.
  void _selectBar(BarModel bar) {
    setState(() {
      _selectedBar = bar;
      _barWidthController = TextEditingController(text: '${bar.width}');
      _barHeightController = TextEditingController(text: '${bar.height}');
      _barRotationValue = bar.rotation;
      _addingBarMode = false;
    });
  }

  /// Cambia el valor de _barRotationValue entre 0 y 90, y
  /// intercambia el valor de los campos de texto de ancho y alto para
  /// reflejar el giro en la UI. Si _selectedBar es null, no hace nada.
  void _toggleBarRotation() {
    if (_selectedBar == null) return;

    final anchoActual =
        double.tryParse(_barWidthController.text) ?? _selectedBar!.width;
    final altoActual =
        double.tryParse(_barHeightController.text) ?? _selectedBar!.height;

    setState(() {
      if (_barRotationValue == 0) {
        _barRotationValue = 90;
        _barWidthController.text = '$altoActual';
        _barHeightController.text = '$anchoActual';
      } else {
        _barRotationValue = 0;
        _barWidthController.text = '$altoActual';
        _barHeightController.text = '$anchoActual';
      }
    });
  }

  /// Construye el Draggable para cada mesa/taburete
  Widget _buildDraggableTable(TableModel t) {
    final x = (t.location['x'] as num).toDouble();
    final y = (t.location['y'] as num).toDouble();

    return Positioned(
      left: x,
      top: y,
      child: GestureDetector(
        onLongPress: () {
          _selectTable(t);
        },
        child: Draggable<TableModel>(
          data: t,
          feedback: _buildTableWidget(t, dragging: true),
          childWhenDragging: Opacity(opacity: 0.3, child: _buildTableWidget(t)),
          onDragEnd: (details) {
            _updateTableLocation(t, details.offset);
          },
          child: _buildTableWidget(t),
        ),
      ),
    );
  }

  /// Dibuja visualmente la mesa o el taburete
  Widget _buildTableWidget(TableModel t, {bool dragging = false}) {
    if (t.type == 'Mesa') {
      return SizedBox(
        width: 100,
        height: 100,
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: _barWidget(20, 60, dragging),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: _barWidget(20, 60, dragging),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: _barWidget(60, 20, dragging),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: _barWidget(60, 20, dragging),
            ),
            Center(
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color:
                      dragging
                          ? _getColorByDinners(t.dinners).withAlpha(60)
                          : _getColorByDinners(t.dinners),
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
    } else {
      return Container(
        width: 35,
        height: 35,
        decoration: BoxDecoration(
          color:
              dragging
                  ? _getColorByDinners(t.dinners).withAlpha(60)
                  : _getColorByDinners(t.dinners),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          '${t.number}',
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      );
    }
  }

  Widget _barWidget(double width, double height, bool dragging) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: dragging ? Colors.blueGrey.withAlpha(6) : Colors.blueGrey[800],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildDraggableBar(BarModel bar) {
    final x = (bar.location['x'] as num).toDouble();
    final y = (bar.location['y'] as num).toDouble();

    return Positioned(
      left: x,
      top: y,
      child: GestureDetector(
        onLongPress: () {
          _selectBar(bar);
        },
        child: Draggable<BarModel>(
          data: bar,
          feedback: _buildBarWidget(bar, dragging: true),
          childWhenDragging: Opacity(opacity: 0.3, child: _buildBarWidget(bar)),
          onDragEnd: (details) {
            _updateBarLocation(bar, details.offset);
          },
          child: _buildBarWidget(bar),
        ),
      ),
    );
  }

  Widget _buildBarWidget(BarModel bar, {bool dragging = false}) {
    final w = bar.width;
    final h = bar.height;
    final color = dragging ? Colors.brown[200]! : Colors.brown[400]!;

    if (bar.rotation == 0) {
      return Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.brown[800]!, width: 2),
        ),
        alignment: Alignment.center,
        child: const Text(
          'BARRA',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      );
    } else {
      return Transform.rotate(
        angle: 90 * 3.1415926535 / 180,
        alignment: Alignment.center,
        child: Container(
          width: h,
          height: w,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.brown[800]!, width: 2),
          ),
          alignment: Alignment.center,
          child: const Text(
            'BARRA',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
  }

  Widget _buildBarEditPanel() {
    return Positioned(
      right: 16,
      top: 16,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 200,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Editar Barra',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _barWidthController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Ancho',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 8,
                  ),
                ),
              ),

              const SizedBox(height: 8),
              TextField(
                controller: _barHeightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Alto',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 8,
                  ),
                ),
              ),

              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Rotación'),
                  const Spacer(),
                  Switch(
                    value: _barRotationValue == 90,
                    onChanged: (_) {
                      _toggleBarRotation();
                    },
                  ),
                ],
              ),

              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        saveBarEdits(
                          _selectedBar!,
                          _barWidthController.text as double,
                          _barHeightController.text as double,
                          _barRotationValue,
                        );
                      },
                      child: const Text('Guardar'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: _deleteBar,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteBar() async {
    if (_selectedBar == null) return;

    final id = _selectedBar!.id;
    await FirebaseFirestore.instance.collection('bars').doc(id).delete();

    setState(() {
      _selectedBar = null;
    });
  }

  Future<void> _onDeletePressed() async {
    if (_selectedTable != null) {
      await deleteTable(_selectedTable!, widget.restaurantRef);
      setState(() {
        _selectedTable = null;
      });
    }
  }

  Widget _buildEditPanel() {
    if (_selectedTable == null) return const SizedBox();

    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        width: 300,
        height: 360,
        padding: const EdgeInsets.all(12),
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Editar ${_selectedTable!.type == 'Mesa' ? 'Mesa' : 'Taburete'}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _selectedTable = null),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _numberController,
              decoration: const InputDecoration(labelText: 'Número'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _dinnersController,
              decoration: const InputDecoration(labelText: 'Comensales'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _tipoValue,
              decoration: const InputDecoration(labelText: 'Tipo'),
              items: const [
                DropdownMenuItem(value: 'mesa', child: Text('Mesa')),
                DropdownMenuItem(value: 'taburete', child: Text('Taburete')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _tipoValue = val;
                  });
                }
              },
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    saveTableEdits(
                      _selectedTable!,
                      int.parse(_numberController.text),
                      int.parse(_dinnersController.text),
                      _tipoValue,
                    );
                    _selectedTable = null;
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar'),
                ),
                ElevatedButton.icon(
                  onPressed: _onDeletePressed,
                  icon: const Icon(Icons.delete),
                  label: const Text('Eliminar'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomMenu() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: () {
            setState(() {
              _addingMode = true;
              _addingStoolMode = false;
              _addingBarMode = false;
              _selectedTable = null;
              _selectedBar = null;
            });
          },
          icon: const Icon(Icons.event_seat),
          label: const Text('Añadir Mesa'),
          style: ElevatedButton.styleFrom(
            backgroundColor:
                (_addingMode && !_addingStoolMode && !_addingBarMode)
                    ? Colors.green
                    : Colors.grey[700],
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: () {
            setState(() {
              _addingMode = true;
              _addingStoolMode = true;
              _addingBarMode = false;
              _selectedTable = null;
              _selectedBar = null;
            });
          },
          icon: const Icon(Icons.chair),
          label: const Text('Añadir Taburete'),
          style: ElevatedButton.styleFrom(
            backgroundColor:
                (_addingMode && _addingStoolMode && !_addingBarMode)
                    ? Colors.green
                    : Colors.grey[700],
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: () {
            setState(() {
              _addingMode = false;
              _addingStoolMode = false;
              _addingBarMode = true;
              _selectedTable = null;
              _selectedBar = null;
            });
          },
          icon: const Icon(Icons.view_week),
          label: const Text('Añadir Barra'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _addingBarMode ? Colors.green : Colors.grey[700],
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: () {
            setState(() {
              _addingMode = false;
              _addingStoolMode = false;
              _addingBarMode = false;
              _selectedTable = null;
              _selectedBar = null;
            });
          },
          icon: const Icon(Icons.cancel),
          label: const Text('Cancelar'),
          style: ElevatedButton.styleFrom(
            backgroundColor:
                (!_addingMode && !_addingBarMode)
                    ? Colors.red
                    : Colors.grey[700],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        flexibleSpace: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(left: 20, top: 12),
            child: Row(
              children: [
                Image.asset(
                  'assets/icons/barSyncApp.png',
                  width: 30,
                  height: 30,
                ),
                const SizedBox(width: 8),
                const Text(
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
        backgroundColor: const Color.fromRGBO(23, 23, 34, 1),
      ),
      body: Row(
        children: [
          Menu(role: 'Boss'),

          Expanded(
            child: GestureDetector(
              onTapUp: (_addingMode || _addingBarMode) ? _onTapUp : null,
              child: Container(
                key: _canvasKey,
                color: Colors.grey.shade100,
                width: double.infinity,
                height: double.infinity,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        ..._bars.map((bar) => _buildDraggableBar(bar)),

                        ..._tables.map(_buildDraggableTable),

                        if (_selectedTable != null) _buildEditPanel(),

                        if (_selectedBar != null) _buildBarEditPanel(),

                        Positioned(
                          bottom: 16,
                          left: 0,
                          right: 0,
                          child: _buildBottomMenu(),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
