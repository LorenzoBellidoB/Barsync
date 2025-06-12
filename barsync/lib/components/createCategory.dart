import 'package:barsync/components/flushBar.dart';
import 'package:barsync/models/categoryModel.dart';
import 'package:barsync/services/database/dataBaseManager.dart';
import 'package:barsync/utils/sesion.dart';
import 'package:flutter/material.dart';

class CreateCategory extends StatefulWidget {
  final VoidCallback onClose;

  const CreateCategory({super.key, required this.onClose});

  @override
  _CreateCategoryState createState() => _CreateCategoryState();
}

class _CreateCategoryState extends State<CreateCategory> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  String? _imageUrl;

  bool _isSaving = false;

  void _createCategory() async {
    if (nameController.text.trim().isEmpty) return;

    setState(() {
      _isSaving = true;
    });

    try {
      CategoryModel categoria = CategoryModel(
        name: nameController.text,
        description: descriptionController.text,
        image: '',
        idRestaurant: Session().restaurantRef,
      );
      await addCategory(categoria);

      widget.onClose();
    } catch (e) {
      print("Error al crear categoría: $e");
      showErrorFlushbar(context, 'Error al crear categoría');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        width: 400,
        height: double.infinity,
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            left: BorderSide(color: Colors.grey.shade300, width: 2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Crear Categoría',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(icon: Icon(Icons.close), onPressed: widget.onClose),
              ],
            ),
            SizedBox(height: 24),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Nombre Categoría',
                filled: true,
                fillColor: Colors.grey.shade200,
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Descripción (opcional)',
                filled: true,
                fillColor: Colors.grey.shade200,
              ),
            ),
            SizedBox(height: 16),
            Container(
              width: double.infinity,
              height: 100,
              color: Colors.grey.shade100,
              child: Center(
                child: Text(
                  'IMAGEN',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Spacer(),
            ElevatedButton(
              onPressed: _isSaving ? null : _createCategory,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: Size(double.infinity, 48),
              ),
              child: Text('Crear', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
