import 'dart:io';
import 'package:barsync/components/imagePicker.dart';
import 'package:barsync/models/productModel.dart';
import 'package:barsync/services/database/dataBaseManager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

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
  String? _existingImageUrl;
  File? _imageFile;

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

  @override
  /*************  ✨ Windsurf Command ⭐  *************/
  /// Inicializa los valores de los campos del formulario con los valores del
  /// producto a editar.
  ///
  /// Llena el mapa [_priceControllers] con los precios asociados a cada tama o
  /// y el mapa [extras] con los extras asociados al producto.
  /// *****  ab392d83-b5d7-4ab6-a4ed-0b33e025ec2e  ******
  void initState() {
    super.initState();
    name = widget.producto.name;
    _description = widget.producto.description ?? '';
    _productClass =
        widget.producto.eatTimes.isNotEmpty
            ? widget.producto.eatTimes.first
            : null;
    _existingImageUrl = widget.producto.image;

    for (var size in sizes.keys) {
      if (widget.producto.prices.containsKey(size)) {
        sizes[size] = true;
        _priceControllers[size] = TextEditingController(
          text: widget.producto.prices[size]?.toString(),
        );
      } else {
        sizes[size] = false;
        _priceControllers[size] = TextEditingController(text: '');
      }
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
        padding: EdgeInsets.only(left: 20, right: 58),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _styledTextField(
                      initialValue: name,
                      label: 'Nombre',
                      onSaved: (v) => name = v ?? '',
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _styledTextField(
                      initialValue: _description,
                      label: 'Descripción',
                      onSaved: (v) => _description = v ?? '',
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _productClass,
                decoration: _inputDecoration('Clase de Producto'),
                dropdownColor: Color(0xFF232334),
                style: TextStyle(color: Colors.white),
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
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Color(0xFF232334),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionTitle('Tamaños'),
                          _checkAllTile(sizes, () {
                            setState(() {
                              for (var k in sizes.keys) {
                                sizes[k] = true;
                              }
                            });
                          }),
                          ...sizes.keys.map((size) {
                            return Row(
                              children: [
                                Checkbox(
                                  value: sizes[size],
                                  onChanged:
                                      (b) => setState(() => sizes[size] = b!),
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
                                      style: TextStyle(color: Colors.white),
                                      controller: _priceControllers[size],
                                      decoration: _inputDecoration('Precio'),
                                      keyboardType: TextInputType.number,
                                      validator: (v) {
                                        if (sizes[size]! &&
                                            (v == null ||
                                                double.tryParse(v) == null)) {
                                          return 'Inv.';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                              ],
                            );
                          }),
                          SizedBox(height: 16),
                          _sectionTitle('Complementos'),
                          _checkAllTile(extras, () {
                            setState(() {
                              for (var k in extras.keys) {
                                extras[k] = true;
                              }
                            });
                          }),
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
                                          title: Text(
                                            ext,
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                          value: extras[ext],
                                          onChanged:
                                              (b) => setState(
                                                () => extras[ext] = b!,
                                              ),
                                          controlAffinity:
                                              ListTileControlAffinity.leading,
                                          contentPadding: EdgeInsets.zero,
                                          activeColor: Colors.amber,
                                        );
                                      }).toList(),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Color(0xFF232334),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ImagePickerWidget(
                        onImageSelected: (file) => _imageFile = file,
                        initialImageUrl: _existingImageUrl,
                      ),
                    ),
                  ),
                ],
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
                    icon: Icon(Icons.save),
                    label: Text('Guardar'),
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
    );
  }

  Widget _styledTextField({
    required String initialValue,
    required String label,
    FormFieldSetter<String>? onSaved,
    FormFieldValidator<String>? validator,
  }) {
    return TextFormField(
      initialValue: initialValue,
      style: TextStyle(color: Colors.white),
      decoration: _inputDecoration(label),
      onSaved: onSaved,
      validator: validator,
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white),
      filled: true,
      fillColor: Color(0xFF2E2E3E),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.amber),
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8.0),
    child: Text(
      text,
      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber),
    ),
  );

  Widget _checkAllTile(Map<String, bool> map, VoidCallback onChanged) {
    return CheckboxListTile(
      title: Text('Marcar todos', style: TextStyle(color: Colors.white)),
      value: !map.values.contains(false),
      onChanged: (_) => onChanged(),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      activeColor: Colors.amber,
    );
  }

  /// Valida el formulario y actualiza el producto en la base de datos.
  ///
  /// Si el formulario es válido, crea un objeto ProductModel con los datos
  /// actuales y llama a updateProduct para subir los cambios a la base de
  /// datos. Si el update es exitoso, navega hacia atrás. De lo contrario,
  /// muestra un SnackBar con un mensaje de error.
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

      String imageUrl = _existingImageUrl ?? '';

      if (_imageFile != null) {
        final uploadedUrl = await uploadImage(_imageFile, 'userId');
        if (uploadedUrl != null) {
          imageUrl = uploadedUrl;
        }
      }

      final updatedProduct = widget.producto.copyWith(
        name: name,
        description: _description,
        eatTimes: [_productClass!],
        prices: prices,
        addOns: selectedExtras,
        image: imageUrl,
      );

      final success = await updateProduct(updatedProduct);

      if (success) {
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error al actualizar el producto')),
        );
      }
    }
  }

  /// Sube una imagen a Firebase Storage y devuelve la URL de descarga.
  ///
  /// El archivo se guarda en la carpeta "products/image" con un nombre
  /// aleatorio (timestamp en milisegundos) y extensión ".jpg".
  ///
  /// Si ocurre un error al subir la imagen, se imprime un mensaje de error
  /// y se devuelve null.
  ///
  /// file es el archivo a subir.
  /// userId es el ID del usuario que sube la imagen (no se utiliza actualmente).
  ///
  Future<String?> uploadImage(File? file, String userId) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference ref = FirebaseStorage.instance.ref().child(
        'products/image/$fileName.jpg',
      );
      UploadTask uploadTask = ref.putFile(file!);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error al subir imagen: $e');
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
        .then((_) => print('Datos de imagen guardados en Firestore'))
        .catchError((error) => print('Error al guardar en Firestore: $error'));
  }
}
