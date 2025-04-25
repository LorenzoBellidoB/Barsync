import 'dart:io';
import 'package:barsync/models/productModel.dart';
import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';

class CreateProduct extends StatefulWidget {
  final String categoryId;

  const CreateProduct({super.key, required this.categoryId});

  @override
  State<CreateProduct> createState() => CreateProductState();
}

class CreateProductState extends State<CreateProduct> {
  final _formKey = GlobalKey<FormState>();

  String _name = '';
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
    sizes.keys.forEach((size) {
      _priceControllers[size] = TextEditingController();
    });
  }

  @override
  void dispose() {
    _priceControllers.values.forEach((c) => c.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalles del Producto'),
        backgroundColor: Color(0xFF171722),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Nombre y Descripción en fila
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(labelText: 'Nombre'),
                      onSaved: (v) => _name = v ?? '',
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(labelText: 'Descripción'),
                      onSaved: (v) => _description = v ?? '',
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16),

              // Clase de producto
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Clase de Producto'),
                items:
                    ['Desayuno', 'Comida', 'Cena', 'Cualquiera']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                onChanged: (v) => _productClass = v,
                validator: (v) => v == null ? 'Selecciona una clase' : null,
              ),

              SizedBox(height: 24),

              // Sección de tamaños/complementos e imagen
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
                              sizes.keys.forEach((k) => sizes[k] = all!);
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        ),
                        Container(
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
                              extras.keys.forEach((k) => extras[k] = all!);
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        ),
                        Container(
                          height: 120,
                          child: Scrollbar(
                            thumbVisibility: true,
                            child: SingleChildScrollView(
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
                    child: GestureDetector(
                      onTap: () async {
                        // final picked = await ImagePicker().pickImage(
                        //   source: ImageSource.gallery,
                        // );
                        // if (picked != null) {
                        //   setState(() => _imageFile = File(picked.path));
                        // }
                      },
                      child: Container(
                        height: 150,
                        color: Colors.grey[200],
                        child:
                            _imageFile == null
                                ? Center(child: Text('IMAGEN'))
                                : Image.file(_imageFile!, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 24),

              // Botones
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
                    label: Text('Crear'),
                    onPressed: _submitForm,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final prices = <String, double>{};
      sizes.forEach((size, selected) {
        if (selected) {
          prices[size] = double.parse(_priceControllers[size]!.text);
        }
      });
      final selectedExtras =
          extras.entries.where((e) => e.value).map((e) => e.key).toList();

      // Lógica para guardar el producto en Firestore aquí

      Navigator.of(context).pop();
    }
  }
}
