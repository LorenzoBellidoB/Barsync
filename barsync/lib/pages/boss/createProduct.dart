import 'dart:io';
import 'package:barsync/components/flushBar.dart';
import 'package:barsync/components/imagePicker.dart';
import 'package:barsync/models/productModel.dart';
import 'package:barsync/services/database/dataBaseManager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:barsync/utils/sesion.dart';

class CreateProduct extends StatefulWidget {
  final DocumentReference categoryId;

  const CreateProduct({super.key, required this.categoryId});

  @override
  State<CreateProduct> createState() => CreateProductState();
}

class CreateProductState extends State<CreateProduct> {
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
      backgroundColor: Color(0xFF171722),
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
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
        backgroundColor: Color(0xFF171722),
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: _inputDecoration('Nombre'),
                      style: TextStyle(color: Colors.white),
                      onSaved: (v) => name = v ?? '',
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      decoration: _inputDecoration('Descripción'),
                      style: TextStyle(color: Colors.white),
                      onSaved: (v) => _description = v ?? '',
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: _inputDecoration('Clase de Producto'),
                dropdownColor: Color(0xFF232334),
                style: TextStyle(color: Colors.white),
                items:
                    ['Bebida', 'Entrantes', 'Comida', 'Otros']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                onChanged: (v) => _productClass = v,
                validator: (v) => v == null ? 'Selecciona una clase' : null,
              ),
              SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionCard(
                          title: 'Tamaños',
                          child: Column(
                            children: [
                              CheckboxListTile(
                                activeColor: Colors.amber,
                                checkColor: Colors.black,
                                title: Text(
                                  'Marcar todos',
                                  style: TextStyle(color: Colors.white),
                                ),
                                value: !sizes.values.contains(false),
                                onChanged: (all) {
                                  setState(() {
                                    for (var k in sizes.keys) {
                                      sizes[k] = all!;
                                    }
                                  });
                                },
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                              ),
                              ...sizes.keys.map((size) {
                                return Row(
                                  children: [
                                    Checkbox(
                                      value: sizes[size],
                                      onChanged:
                                          (val) => setState(
                                            () => sizes[size] = val!,
                                          ),
                                      checkColor: Colors.black,
                                      activeColor: Colors.amber,
                                    ),
                                    Text(
                                      size,
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    SizedBox(width: 8),
                                    if (sizes[size]!)
                                      Expanded(
                                        child: TextFormField(
                                          controller: _priceControllers[size],
                                          decoration: _inputDecoration(
                                            'Precio',
                                          ),
                                          keyboardType: TextInputType.number,
                                          style: TextStyle(color: Colors.white),
                                          validator: (v) {
                                            if (sizes[size]! &&
                                                (v == null ||
                                                    double.tryParse(v) ==
                                                        null)) {
                                              return 'Inválido';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                  ],
                                );
                              }),
                            ],
                          ),
                        ),
                        SizedBox(height: 16),
                        _sectionCard(
                          title: 'Complementos',
                          child: Column(
                            children: [
                              CheckboxListTile(
                                activeColor: Colors.amber,
                                checkColor: Colors.black,
                                title: Text(
                                  'Marcar todos',
                                  style: TextStyle(color: Colors.white),
                                ),
                                value: !extras.values.contains(false),
                                onChanged: (all) {
                                  setState(() {
                                    for (var k in extras.keys) {
                                      extras[k] = all!;
                                    }
                                  });
                                },
                                controlAffinity:
                                    ListTileControlAffinity.leading,
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
                                              activeColor: Colors.amber,
                                              checkColor: Colors.black,
                                              title: Text(
                                                ext,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                              value: extras[ext],
                                              onChanged:
                                                  (val) => setState(
                                                    () => extras[ext] = val!,
                                                  ),
                                              controlAffinity:
                                                  ListTileControlAffinity
                                                      .leading,
                                            );
                                          }).toList(),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Column(
                        spacing: 298,
                        children: [
                          ImagePickerWidget(
                            onImageSelected: (file) {
                              setState(() {
                                _imageFile = file;
                              });
                            },
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton.icon(
                                icon: Icon(Icons.cancel, color: Colors.white),
                                label: Text('Cancelar'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[700],
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                ),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                              SizedBox(width: 16),
                              ElevatedButton.icon(
                                icon: Icon(Icons.check),
                                label: Text('Crear'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber[700],
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                                onPressed: submitForm,
                              ),
                            ],
                          ),
                        ],
                      ),
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

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white70),
      filled: true,
      fillColor: Colors.white10,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Card(
      color: Color(0xFF232334),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: Colors.amber,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }

  /// Este metodo se encarga de validar el formulario, subir la imagen del
  /// producto, crear el objeto ProductModel y guardarlo en la base de
  /// datos. Luego, actualiza la categoria correspondiente para que incluya
  /// el nuevo producto.
  ///
  /// Si ocurre un error al subir la imagen, se muestra un SnackBar
  /// indicando el error.
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
      String? url = await uploadImage(_imageFile, userId);

      if (url == null) {
        showErrorFlushbar(context, 'Error al subir la imagen.');
        return;
      }

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

      final productRef = await addProduct(producto);
      await widget.categoryId.update({
        'products': FieldValue.arrayUnion([productRef]),
      });
      Navigator.of(context).pop();
    }
  }

  /// Sube un archivo de imagen a Firebase Storage en el directorio 'products/image'.
  ///  Si el archivo proporcionado es `null` o no existe, devuelve una URL de imagen predeterminada.
  ///  La imagen se sube con un nombre de archivo que incluye el ID del usuario y la marca de tiempo actual.
  ///  Tras una carga exitosa, la función devuelve la URL de descarga de la imagen subida.
  ///  En caso de un error durante la carga, registra el error y devuelve `null`.
  ///  Args:
  ///  file (File?): El archivo de imagen que se va a subir.
  ///  userId (String): El ID del usuario que sube la imagen.
  ///  Returns:
  ///  Future<String?>: Un Future que se resuelve en la URL de descarga de la imagen subida,
  ///  o `null` si ocurre un error durante la carga.

  Future<String?> uploadImage(File? file, String userId) async {
    try {
      if (file == null || !file.existsSync()) {
        return 'https://firebasestorage.googleapis.com/v0/b/barsync-68a03.firebasestorage.app/o/products%2Fimage%2FbarSyncApp.png?alt=media&token=cc4dda3f-3ff1-4357-b73e-71d728299891';
      }

      String fileName =
          '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference ref = FirebaseStorage.instance.ref().child(
        'products/image/$fileName',
      );
      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      showErrorFlushbar(context, ('Error al subir imagen: $e'));
      return null;
    }
  }

  /// Guarda los datos de una imagen en Firestore en la coleccion "images".
  ///
  /// La imagen se guarda con los siguientes campos:
  ///  - url (String): La URL de descarga de la imagen.
  ///  - nombre (String): El nombre de la imagen.
  ///  - fecha (Timestamp): La marca de tiempo actual.
  ///  - usuario (String): El ID del usuario que subi  la imagen.
  ///
  /// Si la imagen se guarda correctamente, se imprime un mensaje de confirmacion.
  /// Si ocurre un error durante la carga, se imprime un mensaje de error con el
  /// error obtenido.
  ///
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
