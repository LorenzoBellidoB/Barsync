class AddOnsModel {
  String id = '';
  String name;
  String description = '';

  AddOnsModel({required this.id, required this.name, this.description = ''});

  // Convertir objeto a JSON (para Firebase)
  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'rol': description};
  }

  // Crear objeto desde JSON sin id
  // factory AddOnsModel.fromJsonWithoutId(Map<String, dynamic> json) {
  //   return AddOnsModel(
  //     name: json['name'],
  //     email: json['email'],
  //     password: json['password'],
  //     rol: json['role'],
  //     register_date: json['register_date'],
  //   );
  // }

  // Crear objeto desde JSON (desde Firebase)
  factory AddOnsModel.fromJson(Map<String, dynamic> json) {
    return AddOnsModel(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
    );
  }
}
