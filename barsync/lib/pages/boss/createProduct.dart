import 'dart:io';
import 'package:barsync/components/imagePicker.dart';
import 'package:barsync/models/productModel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:barsync/utils/sesion.dart';
import 'package:barsync/services/database/dataBaseManager.dart'
    as databaseManager;

class CreateProduct extends StatefulWidget {
  final DocumentReference categoryId;

  const CreateProduct({super.key, required this.categoryId});

  @override
  State<CreateProduct> createState() => CreateProductState();
}

class CreateProductState extends State<CreateProduct> {
  final _formKey = GlobalKey<FormState>();
  final ScrollController _extrasScrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

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
    for (var size in sizes.keys) {
      _priceControllers[size] = TextEditingController();
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
      body: Padding(
        padding: EdgeInsets.only(top: 32, left: 20, right: 58),
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
                      onSaved: (v) => name = v ?? '',
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
                            controller:
                                _extrasScrollController, // <-- Pásalo aquí
                            child: SingleChildScrollView(
                              controller:
                                  _extrasScrollController, // <-- Y aquí también
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
                      child: ImagePickerWidget(
                        onImageSelected: (file) {
                          setState(() {
                            _imageFile = file;
                          });
                        },
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

      final prices = <String, double>{};
      sizes.forEach((size, selected) {
        if (selected) {
          final text = _priceControllers[size]?.text ?? '';
          final value = double.tryParse(text);
          if (value != null) {
            prices[size] = value;
          }
        }
      });

      final selectedExtras =
          extras.entries.where((e) => e.value).map((e) => e.key).toList();
      String userId = Session().currentUser.id;

      // 🔄 Esperar correctamente a que se suba la imagen
      String? url = await uploadImage(_imageFile, userId);

      if (url == null) {
        // Mostrar error y cancelar
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al subir la imagen.')));
        return;
      }

      // Guardar imagen en colección 'images'
      await saveImageData(url, name, userId);

      ProductModel producto = ProductModel(
        name: name,
        idRestaurant: Session().restaurantRef,
        idCategory: widget.categoryId,
        description: _description,
        addOns: selectedExtras,
        image: url,
        eatTimes: _productClass != null ? [_productClass!] : [],
        prices: prices,
      );

      final productRef = await databaseManager.addProduct(producto);

      await widget.categoryId.update({
        'products': FieldValue.arrayUnion([productRef]),
      });

      Navigator.of(context).pop();
    }
  }

  Future<String?> uploadImage(File? file, String userId) async {
    try {
      // Generar nombre único con timestamp:
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference ref = FirebaseStorage.instance.ref().child(
        'products/image/$fileName.jpg',
      );

      // Iniciar la carga del archivo:
      UploadTask uploadTask = ref.putFile(file!);
      TaskSnapshot snapshot = await uploadTask;
      // Una vez subido, obtener URL de descarga:
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } on FirebaseException catch (e) {
      // Manejar errores (ej. permisos, tamaño, etc)
      print('Error al subir imagen: $e');
      return null;
    }
  }

  Future<void> saveImageData(String imageUrl, String nombre, String usuarioId) {
    CollectionReference images = FirebaseFirestore.instance.collection(
      'images',
    );
    return images
        .add({
          'url': imageUrl,
          'nombre': nombre,
          'fecha': Timestamp.now(),
          'usuario': usuarioId,
        })
        .then((_) {
          print('Datos de imagen guardados en Firestore');
        })
        .catchError((error) {
          print('Error al guardar en Firestore: $error');
        });
  }
}
