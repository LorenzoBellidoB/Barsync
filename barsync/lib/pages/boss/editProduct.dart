import 'dart:io';
import 'package:barsync/models/productModel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:barsync/services/database/dataBaseManager.dart'
    as databaseManager;

class EditProduct extends StatefulWidget {
  final ProductModel producto;

  const EditProduct({super.key, required this.producto});

  @override
  State<EditProduct> createState() => EditProductState();
}

class EditProductState extends State<EditProduct> {
  final _formKey = GlobalKey<FormState>();
  final ScrollController _extrasScrollController = ScrollController();

  String name = '';
  String? _productClass;
  String _description = '';

  Map<String, bool> sizes = {
    'Pequeño': false,
    'Mediano': false,
    'Grande': false,
  };
  Map<String, bool> extras = {
    'Mayonesa': false,
    'Ketchup': false,
    'Barbacoa': false,
    'Ali oli': false,
    'Patatas': false,
    'Queso': false,
  };

  final Map<String, TextEditingController> _priceControllers = {};
  File? _imageFile;

  @override
  void initState() {
    super.initState();

    name = widget.producto.name;
    _description = widget.producto.description ?? '';
    _productClass =
        widget.producto.eatTimes.isNotEmpty
            ? widget.producto.eatTimes.first
            : null;

    int i = 0;
    for (var size in sizes.keys) {
      bool isSelected = i < widget.producto.prices.length;
      sizes[size] = isSelected;
      _priceControllers[size] = TextEditingController(
        text: isSelected ? widget.producto.prices[i].toString() : '',
      );
      if (isSelected) i++;
    }

    for (var extra in widget.producto.addOns) {
      if (extras.containsKey(extra)) {
        extras[extra] = true;
      }
    }
  }

  @override
  void dispose() {
    for (var c in _priceControllers.values) {
      c.dispose();
    }
    _extrasScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Image.asset('assets/icons/barSyncApp.png', width: 30, height: 30),
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
        backgroundColor: Color.fromRGBO(23, 23, 34, 1),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Container(color: Color.fromRGBO(60, 60, 71, 1), height: 1.5),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.only(top: 32, left: 58, right: 58),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: name,
                      decoration: InputDecoration(labelText: 'Nombre'),
                      onSaved: (v) => name = v ?? '',
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      initialValue: _description,
                      decoration: InputDecoration(labelText: 'Descripción'),
                      onSaved: (v) => _description = v ?? '',
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _productClass,
                decoration: InputDecoration(labelText: 'Clase de Producto'),
                items:
                    ['Desayuno', 'Comida', 'Cena', 'Cualquiera']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                onChanged: (v) => setState(() => _productClass = v),
                validator: (v) => v == null ? 'Selecciona una clase' : null,
              ),
              SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tamaños',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        CheckboxListTile(
                          title: Text('Marcar todos'),
                          value: !sizes.values.contains(false),
                          onChanged: (all) {
                            setState(() {
                              for (var k in sizes.keys) {
                                sizes[k] = all!;
                              }
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        ),
                        SizedBox(
                          height: 145,
                          child: Column(
                            children:
                                sizes.keys.map((size) {
                                  return Row(
                                    children: [
                                      Checkbox(
                                        value: sizes[size],
                                        onChanged:
                                            (b) => setState(
                                              () => sizes[size] = b!,
                                            ),
                                      ),
                                      Text(size),
                                      SizedBox(width: 8),
                                      if (sizes[size]!)
                                        Expanded(
                                          child: TextFormField(
                                            controller: _priceControllers[size],
                                            decoration: InputDecoration(
                                              labelText: 'Precio',
                                              isDense: true,
                                            ),
                                            keyboardType: TextInputType.number,
                                            validator: (v) {
                                              if (sizes[size]! &&
                                                  (v == null ||
                                                      double.tryParse(v) ==
                                                          null)) {
                                                return 'Inv.';
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                    ],
                                  );
                                }).toList(),
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Complementos',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        CheckboxListTile(
                          title: Text('Marcar todos'),
                          value: !extras.values.contains(false),
                          onChanged: (all) {
                            setState(() {
                              for (var k in extras.keys) {
                                extras[k] = all!;
                              }
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        ),
                        SizedBox(
                          height: 120,
                          child: Scrollbar(
                            thumbVisibility: true,
                            controller: _extrasScrollController,
                            child: SingleChildScrollView(
                              controller: _extrasScrollController,
                              child: Column(
                                children:
                                    extras.keys.map((ext) {
                                      return CheckboxListTile(
                                        title: Text(ext),
                                        value: extras[ext],
                                        onChanged:
                                            (b) => setState(
                                              () => extras[ext] = b!,
                                            ),
                                        controlAffinity:
                                            ListTileControlAffinity.leading,
                                        contentPadding: EdgeInsets.zero,
                                      );
                                    }).toList(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: Container(
                      height: 150,
                      color: Colors.grey[200],
                      child:
                          _imageFile == null
                              ? Center(child: Text('IMAGEN'))
                              : Image.file(_imageFile!, fit: BoxFit.cover),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    icon: Icon(Icons.cancel),
                    label: Text('Cancelar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  SizedBox(width: 16),
                  ElevatedButton.icon(
                    icon: Icon(Icons.check),
                    label: Text('Guardar'),
                    onPressed: submitForm,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final prices = <double>[];
      sizes.forEach((size, selected) {
        if (selected) {
          prices.add(double.parse(_priceControllers[size]!.text));
        }
      });

      final selectedExtras =
          extras.entries.where((e) => e.value).map((e) => e.key).toList();

      final updatedProduct = widget.producto.copyWith(
        name: name,
        description: _description,
        eatTimes: [_productClass!],
        prices: prices,
        addOns: selectedExtras,
      );

      final success = await databaseManager.updateProduct(updatedProduct);

      if (success) {
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error al actualizar el producto')),
        );
      }
    }
  }
}
