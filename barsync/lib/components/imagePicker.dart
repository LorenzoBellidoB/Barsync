import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerWidget extends StatefulWidget {
  final Function(File?) onImageSelected;
  final String? initialImageUrl; // NUEVO

  const ImagePickerWidget({
    Key? key,
    required this.onImageSelected,
    this.initialImageUrl,
  }) : super(key: key);

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  String? _networkImageUrl;

  @override
  void initState() {
    super.initState();
    _networkImageUrl = widget.initialImageUrl;
    print(_networkImageUrl);
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? picked = await _picker.pickImage(
      source: source,
      maxWidth: 800,
      imageQuality: 80,
    );

    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
        _networkImageUrl =
            null; // Si se selecciona una nueva, borramos la anterior
      });
      widget.onImageSelected(_imageFile);
    }
  }

  void _removeImage() {
    setState(() {
      _imageFile = null;
      _networkImageUrl = null;
    });
    widget.onImageSelected(null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_imageFile != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 200,
              height: 200,
              child: Image.file(_imageFile!, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _removeImage,
            icon: Icon(Icons.delete, color: Colors.red),
            label: Text('Eliminar imagen', style: TextStyle(color: Colors.red)),
          ),
        ] else if (_networkImageUrl != null &&
            _networkImageUrl!.isNotEmpty) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 200,
              height: 200,
              child: Image.network(
                _networkImageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: const Icon(
                      Icons.broken_image,
                      size: 80,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            ),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40),
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              color: Colors.grey[100],
            ),
            child: Center(child: Text('No se ha seleccionado imagen')),
          ),
        ],
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            ElevatedButton.icon(
              onPressed: () => _pickImage(ImageSource.gallery),
              icon: Icon(Icons.photo_library),
              label: Text('Galería'),
            ),
            ElevatedButton.icon(
              onPressed: () => _pickImage(ImageSource.camera),
              icon: Icon(Icons.camera_alt),
              label: Text('Cámara'),
            ),
          ],
        ),
      ],
    );
  }
}
