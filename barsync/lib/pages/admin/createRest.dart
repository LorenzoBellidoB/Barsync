import 'package:barsync/components/alert.dart';
import 'package:barsync/components/menu.dart';
import 'package:barsync/models/restaurantModel.dart';
import 'package:barsync/models/userModel.dart';
import 'package:barsync/pages/admin/admin.dart';
import 'package:barsync/services/database/dataBaseManager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CreateRestScreen extends StatefulWidget {
  const CreateRestScreen({super.key});

  @override
  State<CreateRestScreen> createState() => _CreateRestScreenState();
}

class _CreateRestScreenState extends State<CreateRestScreen> {
  final Map<String, TextEditingController> restauranteControllers = {
    'nombre': TextEditingController(),
    'direccion': TextEditingController(),
    'telefono': TextEditingController(),
    'nombreJefe': TextEditingController(),
    'email': TextEditingController(),
  };

  final TextEditingController _camarerosCountController =
      TextEditingController();
  final TextEditingController _cocinerosCountController =
      TextEditingController();

  final List<String> estados = ['Activo', 'Inactivo'];
  String? estadoSeleccionado;

  List<Map<String, TextEditingController>> camareros = [];
  List<Map<String, TextEditingController>> cocineros = [];

  void updateDynamicFields() {
    int camarerosCount = int.tryParse(_camarerosCountController.text) ?? 0;
    int cocinerosCount = int.tryParse(_cocinerosCountController.text) ?? 0;

    setState(() {
      camareros = List.generate(camarerosCount, (_) {
        return {
          'nombre': TextEditingController(),
          'email': TextEditingController(),
          'rol': TextEditingController(text: 'Waiter'),
        };
      });

      cocineros = List.generate(cocinerosCount, (_) {
        return {
          'nombre': TextEditingController(),
          'email': TextEditingController(),
          'rol': TextEditingController(text: 'Cooker'),
        };
      });
    });
  }

  bool validateFields() {
    for (var key in restauranteControllers.keys) {
      if (restauranteControllers[key]!.text.isEmpty) {
        return false;
      }
    }
    if (estadoSeleccionado == null) return false;
    return true;
  }

  void createRestaurant() async {
    RestaurantModel restaurant = RestaurantModel(
      name: restauranteControllers['nombre']!.text,
      date: Timestamp.now(),
      state: estadoSeleccionado == 'Activo' ? true : false,
      address: restauranteControllers['direccion']!.text,
      phone: restauranteControllers['telefono']!.text,
      emailBoss: restauranteControllers['email']!.text,
    );
    try {
      final firestore = FirebaseFirestore.instance;
      // Guardar el restaurante
      String idRestaurante = await saveRestaurant(restaurant);
      print('Restaurante');
      print(restaurant.toJson());
      // Obtengo la referencia al restaurante
      final restaurantDoc = firestore
          .collection('restaurants')
          .doc(idRestaurante);
      // Crear camareros y cocineros del restaurante
      createWaitersCookersBoss(restaurantDoc);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Restaurante y usuarios creados correctamente."),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print(e);
    }
  }

  void createWaitersCookersBoss(DocumentReference id) async {
    List<UserModel> listUsers = [];

    UserModel boss = UserModel(
      id: '',
      name: restauranteControllers['nombreJefe']!.text,
      rol: 'Boss',
      email: restauranteControllers['email']!.text,
      register_date: Timestamp.now(),
      idRestaurante: id,
      fcmToken: '',
    );
    print(boss.toJson());
    try {
      if (await usersDuplicated(boss.email)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Jefe con email inválido."),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        await createOrUpdateAuthUserAndSave(boss, id);
        print(boss.toJson());
        listUsers.add(boss);
      }
    } catch (e) {
      print(e);
    }

    print("CAMAREROS:");
    for (var c in camareros) {
      UserModel camarero = UserModel(
        id: '',
        name: c['nombre']!.text,
        email: c['email']!.text,
        rol: c['rol']!.text,
        register_date: Timestamp.now(),
        idRestaurante: id,
        fcmToken: '',
      );

      try {
        if (await usersDuplicated(camarero.email)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Camarero con email inválido."),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          await createOrUpdateAuthUserAndSave(camarero, id);
          print(camarero.toJson());
          listUsers.add(camarero);
        }
      } catch (e) {
        print(e);
      }
    }

    print("COCINEROS:");
    for (var c in cocineros) {
      UserModel cocinero = UserModel(
        id: '',
        name: c['nombre']!.text,
        email: c['email']!.text,
        rol: c['rol']!.text,
        register_date: Timestamp.now(),
        idRestaurante: id,
        fcmToken: '',
      );

      try {
        if (await usersDuplicated(cocinero.email)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Cocinero con email inválido."),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          await createOrUpdateAuthUserAndSave(cocinero, id);
          print(cocinero.toJson());
          listUsers.add(cocinero);
        }
      } catch (e) {
        print(e);
      }
    }

    try {
      await updateUsersRestaurant(id, listUsers);
    } catch (e) {
      print('Error al actualizar restaurante: $e');
    }
  }

  @override
  void dispose() {
    for (var c in camareros) {
      c.forEach((_, controller) => controller.dispose());
    }
    for (var c in cocineros) {
      c.forEach((_, controller) => controller.dispose());
    }
    for (var controller in restauranteControllers.values) {
      controller.dispose();
    }
    _camarerosCountController.dispose();
    _cocinerosCountController.dispose();
    super.dispose();
  }

  Widget buildTextField(
    String label,
    TextEditingController controller, {
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
    void Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      onChanged: onChanged,

      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.grey[800],
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: const Icon(Icons.edit, color: Colors.grey, size: 20),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).primaryColor),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        backgroundColor: const Color.fromRGBO(23, 23, 34, 1),
        flexibleSpace: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(left: 20, top: 12),
            child: Row(
              children: [
                Image.asset(
                  'assets/icons/barSyncApp.png',
                  width: 30,
                  height: 30,
                ),
                const SizedBox(width: 8),
                const Text(
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
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Menú lateral (reutilizamos tu widget Menu)
          Menu(role: 'Admin'),

          // Contenido principal que aprovecha todo el ancho (menos margen)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 36, bottom: 16),
              child: Padding(
                // Márgenes laterales en tablet: 16 px a cada lado
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Crear Restaurante',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(thickness: 1),

                    // =======================================
                    // Card: Datos generales del restaurante
                    // =======================================
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 16),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 20,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Columna Izquierda
                              Expanded(
                                child: Column(
                                  children: [
                                    buildTextField(
                                      "Restaurante",
                                      restauranteControllers['nombre']!,
                                    ),
                                    const SizedBox(height: 20),
                                    buildTextField(
                                      "Dirección",
                                      restauranteControllers['direccion']!,
                                    ),
                                    const SizedBox(height: 20),
                                    buildTextField(
                                      "Nombre Jefe",
                                      restauranteControllers['nombreJefe']!,
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 20),

                              // Columna Derecha
                              Expanded(
                                child: Column(
                                  children: [
                                    DropdownButtonFormField<String>(
                                      value: estadoSeleccionado,
                                      decoration: InputDecoration(
                                        labelText: "Estado",
                                        labelStyle: TextStyle(
                                          color: Colors.grey[800],
                                          fontWeight: FontWeight.w600,
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.grey.shade400,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.grey.shade300,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color:
                                                Theme.of(context).primaryColor,
                                          ),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                      ),
                                      items:
                                          estados.map((estado) {
                                            return DropdownMenuItem<String>(
                                              value: estado,
                                              child: Text(estado),
                                            );
                                          }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          estadoSeleccionado = value;
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 20),
                                    buildTextField(
                                      "Teléfono",
                                      restauranteControllers['telefono']!,
                                      keyboardType: TextInputType.phone,
                                    ),
                                    const SizedBox(height: 20),
                                    buildTextField(
                                      "Email",
                                      restauranteControllers['email']!,
                                      keyboardType: TextInputType.emailAddress,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const Divider(thickness: 1),

                    // =========================================
                    // Card: Conteo de camareros y cocineros
                    // =========================================
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 20,
                          ),
                          child: Row(
                            children: [
                              // Columna Izquierda
                              Expanded(
                                child: buildTextField(
                                  "Número de Camareros",
                                  _camarerosCountController,
                                  keyboardType: TextInputType.number,
                                  onChanged: (_) => updateDynamicFields(),
                                ),
                              ),

                              const SizedBox(width: 20),

                              // Columna Derecha
                              Expanded(
                                child: buildTextField(
                                  "Número de Camareros",
                                  _cocinerosCountController,
                                  keyboardType: TextInputType.number,
                                  onChanged: (_) => updateDynamicFields(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ====================================
                    // Sección dinámica: Camareros
                    // ====================================
                    if (camareros.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          "Camareros",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      ...camareros.asMap().entries.map((entry) {
                        final camarero = entry.value;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  // Nombre
                                  Expanded(
                                    child: buildTextField(
                                      "Nombre ${entry.key + 1}",
                                      camarero['nombre']!,
                                    ),
                                  ),

                                  const SizedBox(width: 20),

                                  // Email
                                  Expanded(
                                    child: buildTextField(
                                      "Email ${entry.key + 1}",
                                      camarero['email']!,
                                      keyboardType: TextInputType.emailAddress,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ],

                    // ====================================
                    // Sección dinámica: Cocineros
                    // ====================================
                    if (cocineros.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          "Cocineros",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      ...cocineros.asMap().entries.map((entry) {
                        final cocinero = entry.value;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  // Nombre
                                  Expanded(
                                    child: buildTextField(
                                      "Nombre ${entry.key + 1}",
                                      cocinero['nombre']!,
                                    ),
                                  ),

                                  const SizedBox(width: 20),

                                  // Email
                                  Expanded(
                                    child: buildTextField(
                                      "Email ${entry.key + 1}",
                                      cocinero['email']!,
                                      keyboardType: TextInputType.emailAddress,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ],

                    const SizedBox(height: 30),

                    // ====================================
                    // Botones Crear / Cancelar
                    // ====================================
                    Center(
                      child: Wrap(
                        spacing: 20,
                        runSpacing: 10,
                        children: [
                          // ===================
                          // Botón Crear
                          // ===================
                          ElevatedButton.icon(
                            onPressed: () {
                              if (!validateFields()) {
                                showDialog(
                                  context: context,
                                  builder:
                                      (_) => CustomAlertDialog(
                                        title: 'Campos incompletos',
                                        message:
                                            'Completa todos los campos antes de continuar.',
                                        buttonText: 'Aceptar',
                                        colorbg: Color.fromRGBO(23, 23, 34, 1),
                                        icon: Icons.warning_amber_rounded,
                                        textColor: Colors.white,
                                        buttonColor: Colors.orange,
                                      ),
                                );
                                return;
                              }
                              createRestaurant();
                              Navigator.pop(context);
                            },
                            icon: const Icon(
                              Icons.add_business,
                              size: 22,
                              color: Colors.white,
                            ),
                            label: const Padding(
                              padding: EdgeInsets.only(left: 8),
                              child: Text(
                                'Crear Restaurante',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 28,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 6,
                              shadowColor: Theme.of(
                                context,
                              ).primaryColor.withOpacity(0.5),
                            ),
                          ),

                          // ===================
                          // Botón Cancelar
                          // ===================
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                camareros.clear();
                                cocineros.clear();
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const AdminScreen(),
                                  ),
                                );
                              });
                            },
                            icon: const Icon(
                              Icons.cancel_outlined,
                              size: 22,
                              color: Colors.white,
                            ),
                            label: const Padding(
                              padding: EdgeInsets.only(left: 8),
                              child: Text(
                                'Cancelar',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.secondary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 28,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 6,
                              shadowColor: Theme.of(
                                context,
                              ).colorScheme.secondary.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
