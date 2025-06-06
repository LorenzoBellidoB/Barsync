import 'package:barsync/pages/waiter/billingScreen.dart';
import 'package:barsync/models/billModel.dart';
import 'package:barsync/models/ordersModel.dart';
import 'package:barsync/models/productModel.dart';
import 'package:barsync/models/productOrderModel.dart';
import 'package:barsync/models/tableModel.dart';
import 'package:barsync/services/database/dataBaseManager.dart';
import 'package:barsync/utils/sesion.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderScreen extends StatefulWidget {
  final TableModel table;
  const OrderScreen({Key? key, required this.table}) : super(key: key);

  @override
  _OrderScreenState createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> eatTimes = ['Bebida', 'Entrantes', 'Comida', 'Otros'];

  Map<String, List<ProductModel>> productsByTime = {};

  Map<DocumentReference<Object?>, String> categoryNames = {};

  List<ProductOrderModel> orderProducts = [];

  BillModel? _currentBill;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: eatTimes.length, vsync: this);
    _fetchCategories();
    _fetchProducts();
    _fetchCurrentBill();
  }

  void _fetchCategories() async {
    final catSnap =
        await FirebaseFirestore.instance.collection('categories').get();
    setState(() {
      categoryNames = {
        for (var doc in catSnap.docs)
          doc.reference: (doc.data() as Map<String, dynamic>)['name'] as String,
      };
    });
  }

  void _fetchProducts() {
    FirebaseFirestore.instance.collection('products').snapshots().listen((
      snap,
    ) {
      final all = snap.docs.map((d) => ProductModel.fromFirestore(d)).toList();
      setState(() {
        productsByTime = {
          for (var t in eatTimes)
            t: all.where((p) => p.eatTimes.contains(t)).toList(),
        };
      });
    });
  }

  Future<void> _fetchCurrentBill() async {
    if (widget.table == null) return;

    final billSnap =
        await FirebaseFirestore.instance
            .collection('bills')
            .where('table', isEqualTo: getTableRefById(widget.table.id))
            .where('state', isEqualTo: 'open') // Look for an open bill
            .limit(1)
            .get();

    if (billSnap.docs.isNotEmpty) {
      setState(() {
        _currentBill = BillModel.fromJson(
          billSnap.docs.first.data(),
          billSnap.docs.first.id,
        );
      });
    } else {
      // No open bill found, create a new one
      _createNewBill();
    }
  }

  Future<void> _createNewBill() async {
    if (widget.table == null) return;

    final newBill = BillModel(
      table: getTableRefById(widget.table.id),
      idRestaurant: Session().restaurantRef,
      startTime: Timestamp.now(),
      state: 'open',
    );

    final docRef = await FirebaseFirestore.instance
        .collection('bills')
        .add(newBill.toJson());
    setState(() {
      _currentBill = newBill..id = docRef.id;
    });
  }

  void _addToOrder(ProductModel product) async {
    final selection = await _selectOptions(product);
    if (selection == null || selection['sizes']!.isEmpty) return;

    final selectedSizes = selection['sizes']!;
    final selectedAddOns = selection['addons']!;

    setState(() {
      for (var size in selectedSizes) {
        orderProducts.add(
          ProductOrderModel(
            id: '',
            name: product.name,
            addOns: selectedAddOns,
            price: {size: product.prices[size] ?? 0.0},
            idRestaurant: product.idRestaurant,
            idCategory: product.idCategory,
          ),
        );
      }
    });
  }

  Future<Map<String, List<String>>?> _selectOptions(
    ProductModel product,
  ) async {
    final sizes = product.prices.keys.toList();
    final addons = product.addOns;
    String? selSize; // Solo un tamaño seleccionado
    Set<String> selAddons = {};

    return showModalBottomSheet<Map<String, List<String>>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color.fromRGBO(23, 23, 34, 1),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (_) => StatefulBuilder(
            builder: (context, setState) {
              final allAddons = selAddons.length == addons.length;
              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  top: 16,
                  left: 16,
                  right: 16,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selecciona Tamaño',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            sizes
                                .map(
                                  (s) => ChoiceChip(
                                    label: Text(
                                      s,
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    selected: selSize == s,
                                    selectedColor: const Color(0xFF004C99),
                                    backgroundColor: const Color(0xFF2A2E3D),
                                    onSelected:
                                        (_) => setState(() {
                                          selSize = (selSize == s) ? null : s;
                                        }),
                                  ),
                                )
                                .toList(),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Selecciona Add-ons',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            label: Text(
                              allAddons
                                  ? 'Deseleccionar todos'
                                  : 'Seleccionar todos',
                              style: TextStyle(color: Colors.white),
                            ),
                            selected: allAddons,
                            selectedColor: const Color(0xFF004C99),
                            backgroundColor: const Color(0xFF2A2E3D),
                            onSelected:
                                (_) => setState(() {
                                  selAddons = allAddons ? {} : addons.toSet();
                                }),
                          ),
                          ...addons.map(
                            (a) => ChoiceChip(
                              label: Text(
                                a,
                                style: TextStyle(color: Colors.white),
                              ),
                              selected: selAddons.contains(a),
                              selectedColor: const Color(0xFF004C99),
                              backgroundColor: const Color(0xFF2A2E3D),
                              onSelected:
                                  (_) => setState(() {
                                    if (!selAddons.remove(a)) selAddons.add(a);
                                  }),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF006BC2),
                            minimumSize: Size(60, 50),
                          ),
                          onPressed:
                              () => Navigator.pop<Map<String, List<String>>>(
                                context,
                                {
                                  'sizes':
                                      selSize != null ? [selSize!] : <String>[],
                                  'addons':
                                      selAddons
                                          .map((e) => e.toString())
                                          .toList(),
                                },
                              ),
                          child: const Text(
                            'Aceptar',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }

  double _total() =>
      orderProducts.fold(0.0, (sum, p) => sum + p.price.values.first);

  void _showOrderSummary() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (context) => DraggableScrollableSheet(
            expand: false,
            builder:
                (context, scrollController) => Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListView(
                    controller: scrollController,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Mesa: ${widget.table.number}',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Comensales: ${widget.table.dinners}',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                      Divider(color: Colors.white),
                      ...orderProducts.map((product) {
                        final unitPrice = product.price.values.first;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              ...product.addOns.map(
                                (addon) => Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: Text(
                                    '- $addon',
                                    style: TextStyle(color: Colors.grey[300]),
                                  ),
                                ),
                              ),
                              Text(
                                textAlign: TextAlign.right,
                                'Subtotal: ${unitPrice.toStringAsFixed(2)}€',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        );
                      }),
                      Divider(color: Colors.white),
                      SizedBox(height: 8),
                      Text(
                        'Total: ${_total().toStringAsFixed(2)}€',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      Divider(color: Colors.white),
                      SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                orderProducts.clear();
                              });
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color.fromARGB(255, 153, 0, 0),
                              minimumSize: Size(110, 50),
                            ),
                            child: Text(
                              'Cancelar',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          ElevatedButton(
                            onPressed:
                                orderProducts.isNotEmpty
                                    ? () async {
                                      if (_currentBill == null) {
                                        print(
                                          "Error: No bill found for this table.",
                                        );
                                        return;
                                      }

                                      // Create the order

                                      OrderModel order = OrderModel(
                                        id: '', // Firestore will assign an ID

                                        state: 'pendiente',

                                        time: Timestamp.now(),
                                        products: orderProducts,

                                        table: getTableRefById(widget.table.id),

                                        idRestaurant: Session().restaurantRef,
                                        waiter: getUserById(
                                          Session().currentUser,
                                        ),
                                      );

                                      final orderDocRef = await createOrder(
                                        order,
                                      );

                                      // Update the current bill with the new order's reference

                                      await FirebaseFirestore.instance
                                          .collection('bills')
                                          .doc(_currentBill!.id)
                                          .update({
                                            'orderRefs': FieldValue.arrayUnion([
                                              orderDocRef,
                                            ]),

                                            'totalAmount':
                                                _currentBill!.totalAmount +
                                                _total(), // Update total
                                          });

                                      // Clear orderProducts for the next order

                                      setState(() {
                                        orderProducts.clear();

                                        // Optionally, show a success message

                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Comanda enviada y añadida a la cuenta!',
                                            ),
                                          ),
                                        );

                                        Navigator.pop(
                                          context,
                                        ); // Close the summary bottom sheet
                                      });
                                    }
                                    : null,
                            style: ButtonStyle(
                              backgroundColor: WidgetStateProperty.resolveWith<
                                Color?
                              >((Set<WidgetState> states) {
                                if (states.contains(WidgetState.disabled)) {
                                  return Colors
                                      .grey[400]; // Color cuando el botón está deshabilitado
                                }
                                return Colors
                                    .green; // Color por defecto cuando el botón está habilitado
                              }),
                              foregroundColor: WidgetStateProperty.all(
                                Colors.white,
                              ), // Color del texto siempre blanco
                            ),
                            child: Text(
                              'Enviar Comanda',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromRGBO(23, 23, 34, 1),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Image.asset('assets/icons/barSyncApp.png', width: 20, height: 20),
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
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false,
          labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.white,
          tabs: eatTimes.map((t) => Tab(child: Text(t))).toList(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children:
                  eatTimes.map((t) {
                    final list = productsByTime[t] ?? [];

                    if (t == 'Comida') {
                      final byCategory = <String, List<ProductModel>>{};
                      for (var p in list) {
                        final name =
                            categoryNames[p.idCategory] ?? 'Sin categoría';
                        byCategory.putIfAbsent(name, () => []).add(p);
                      }

                      return ListView(
                        padding: EdgeInsets.all(8),
                        children:
                            byCategory.entries.map((entry) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                      horizontal: 8,
                                    ),
                                    child: Text(
                                      entry.key,
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  GridView.builder(
                                    shrinkWrap: true,
                                    physics: NeverScrollableScrollPhysics(),
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 3,
                                          crossAxisSpacing: 4,
                                          mainAxisSpacing: 4,
                                          childAspectRatio: 3 / 4,
                                        ),
                                    itemCount: entry.value.length,
                                    itemBuilder: (_, i) {
                                      final product = entry.value[i];
                                      return GestureDetector(
                                        onTap: () => _addToOrder(product),
                                        child: Card(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              Expanded(
                                                child:
                                                    product.image.isNotEmpty
                                                        ? ClipRRect(
                                                          borderRadius:
                                                              BorderRadius.vertical(
                                                                top:
                                                                    Radius.circular(
                                                                      12,
                                                                    ),
                                                              ),
                                                          child: Image.network(
                                                            product.image,
                                                            fit: BoxFit.cover,
                                                          ),
                                                        )
                                                        : Container(
                                                          color:
                                                              Colors.grey[300],
                                                          child: Icon(
                                                            Icons.restaurant,
                                                            size: 50,
                                                            color: Colors.grey,
                                                          ),
                                                        ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.all(
                                                  8.0,
                                                ),
                                                child: Text(
                                                  product.name,
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              );
                            }).toList(),
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 4,
                          childAspectRatio: 3 / 4,
                        ),
                        itemCount: list.length,
                        itemBuilder: (_, i) {
                          final product = list[i];
                          return GestureDetector(
                            onTap: () => _addToOrder(product),
                            child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child:
                                        product.image.isNotEmpty
                                            ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.vertical(
                                                    top: Radius.circular(12),
                                                  ),
                                              child: Image.network(
                                                product.image,
                                                fit: BoxFit.cover,
                                              ),
                                            )
                                            : Container(
                                              color: Colors.grey[300],
                                              child: Icon(
                                                Icons.restaurant,
                                                size: 50,
                                                color: Colors.grey,
                                              ),
                                            ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      product.name,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
              right: 12,
              left: 12,
              bottom: 48,
              top: 8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50),
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: _showOrderSummary,
                    child: Text(
                      "Ver Comanda (${orderProducts.length})",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => BillingScreen(table: widget.table),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50), // 👈 misma altura
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          20,
                        ), // 👈 mismo estilo
                      ),
                    ),
                    child: Text(
                      'Pagar Cuenta',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
