import 'package:barsync/models/ordersModel.dart';
import 'package:barsync/models/productModel.dart';
import 'package:barsync/models/productOrderModel.dart';
import 'package:barsync/models/tableModel.dart';
import 'package:barsync/services/database/dataBaseManager.dart';
import 'package:barsync/utils/sesion.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:barsync/services/database/dataBaseManager.dart'
    as databaseManager;

class OrderScreen extends StatefulWidget {
  final TableModel? table;
  const OrderScreen({Key? key, required this.table}) : super(key: key);

  @override
  _OrderScreenState createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> eatTimes = ['Bebida', 'Entrantes', 'Comida', 'Postres'];

  Map<String, List<ProductModel>> productsByTime = {};

  Map<DocumentReference<Object?>, String> categoryNames = {};

  List<ProductOrderModel> orderProducts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: eatTimes.length, vsync: this);
    _fetchCategories();
    _fetchProducts();
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

  void _addToOrder(ProductModel product) async {
    final selection = await _selectOptions(product);
    if (selection == null || selection['sizes']!.isEmpty) return;

    final selectedSizes = selection['sizes']!;
    final selectedAddOns = selection['addons']!;

    setState(() {
      for (var size in selectedSizes) {
        orderProducts.add(
          ProductOrderModel(
            id: product.id,
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
    var selSizes = <String>{};
    var selAddons = <String>{};

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
              final allSizes = selSizes.length == sizes.length;
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
                        'Selecciona Tamaño(s)',
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
                              allSizes
                                  ? 'Deseleccionar todos'
                                  : 'Seleccionar todos',
                              style: TextStyle(color: Colors.white),
                            ),
                            selected: allSizes,
                            selectedColor: const Color(0xFF004C99),
                            backgroundColor: const Color(0xFF2A2E3D),
                            onSelected:
                                (_) => setState(
                                  () =>
                                      selSizes = allSizes ? {} : sizes.toSet(),
                                ),
                          ),
                          ...sizes.map(
                            (s) => ChoiceChip(
                              label: Text(
                                s,
                                style: TextStyle(color: Colors.white),
                              ),
                              selected: selSizes.contains(s),
                              selectedColor: const Color(0xFF004C99),
                              backgroundColor: const Color(0xFF2A2E3D),
                              onSelected:
                                  (_) => setState(() {
                                    if (!selSizes.remove(s)) selSizes.add(s);
                                  }),
                            ),
                          ),
                        ],
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
                                (_) => setState(
                                  () =>
                                      selAddons =
                                          allAddons ? {} : addons.toSet(),
                                ),
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
                              () => Navigator.pop(context, {
                                'sizes': selSizes.toList(),
                                'addons': selAddons.toList(),
                              }),
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
                            'Mesa: ${widget.table?.number}',
                            style: TextStyle(color: Colors.white),
                          ),
                          Text(
                            'Comensales: ${widget.table?.dinners}',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                      Divider(color: Colors.white),
                      ...orderProducts.map(
                        (product) => Padding(
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
                                'Total: \$${_total().toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Divider(color: Colors.white),
                      SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          ElevatedButton(
                            onPressed: () {},
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
                            onPressed: () {
                              OrderModel order = OrderModel(
                                id: '',
                                state: 'pendiente',
                                time: Timestamp.now(),
                                products: orderProducts,
                                table: getTableRefById(widget.table?.id),
                                idRestaurant: Session().restaurantRef,
                                waiter: getUserById(Session().currentUser),
                              );
                              databaseManager.createOrder(order);
                              print(order.toJson());
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              minimumSize: Size(160, 50),
                            ),
                            child: Text(
                              'Enviar Comanda',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              minimumSize: Size(110, 50),
                            ),
                            child: Text(
                              'Pagar',
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
      body: Stack(
        children: [
          TabBarView(
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
                                                        color: Colors.grey[300],
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
                                            borderRadius: BorderRadius.vertical(
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

          // —— AQUÍ SOLO HE AÑADIDO ESTE BOTÓN ——
          if (orderProducts.isNotEmpty)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 12,
                  right: 12,
                  left: 12,
                  bottom: 48,
                ),
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
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
