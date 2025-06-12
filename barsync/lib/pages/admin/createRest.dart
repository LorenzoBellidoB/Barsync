import 'package:barsync/components/alert.dart';
import 'package:barsync/components/flushBar.dart';
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
    'cif': TextEditingController(),
  };

  final TextEditingController _camarerosCountController =
      TextEditingController();
  final TextEditingController _cocinerosCountController =
      TextEditingController();

  final List<String> estados = ['Activo', 'Inactivo'];
  String? estadoSeleccionado;

  List<Map<String, TextEditingController>> camareros = [];
  List<Map<String, TextEditingController>> cocineros = [];

  /// El valor actual de `_camarerosCountController.text` y
  /// `_cocinerosCountController.text` se utiliza para crear una lista de
  /// `TextEditingController` con el número de elementos solicitado. El contenido
  /// de cada elemento se inicializa con un valor predeterminado.
  /// Luego, se llama a `setState` para reflejar el cambio en el estado de la
  /// pantalla.
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

  /// Verifica que todos los campos del formulario esten completos y no vacios.
  bool validateFields() {
    for (var key in restauranteControllers.keys) {
      if (restauranteControllers[key]!.text.isEmpty) {
        return false;
      }
    }
    if (estadoSeleccionado == null) return false;
    return true;
  }

  /// Crea un nuevo restaurante con los datos del formulario, y crea a los
  /// camareros, cocineros y jefe del restaurante en la base de datos.
  ///
  /// Primero, se crea un `RestaurantModel` con los datos del formulario,
  /// y se guarda en la base de datos mediante `saveRestaurant`.
  /// Luego, se obtiene la referencia al restaurante recien creado,
  /// y se crean los camareros, cocineros y jefe del restaurante
  /// mediante `createWaitersCookersBoss`.
  ///
  /// Si ocurre un error, se muestra una alerta con el mensaje de error.
  ///
  /// Si se completa correctamente, se muestra una snackbar con un mensaje
  /// de exito.
  void createRestaurant() async {
    RestaurantModel restaurant = RestaurantModel(
      name: restauranteControllers['nombre']!.text,
      date: Timestamp.now(),
      state: estadoSeleccionado == 'Activo' ? true : false,
      address: restauranteControllers['direccion']!.text,
      phone: restauranteControllers['telefono']!.text,
      emailBoss: restauranteControllers['email']!.text,
      cif: restauranteControllers['cif']!.text,
    );
    try {
      final firestore = FirebaseFirestore.instance;
      String idRestaurante = await saveRestaurant(restaurant);
      print('Restaurante');
      print(restaurant.toJson());

      final restaurantDoc = firestore
          .collection('restaurants')
          .doc(idRestaurante);

      createWaitersCookersBoss(restaurantDoc);
      showSuccessFlushbar(
        context,
        'Restaurante y usuarios creados correctamente.',
      );
      Navigator.pop(context);
    } catch (e) {
      showErrorFlushbar(context, 'Error al crear el restaurante: $e');
    }
  }

  /// Crea los camareros, cocineros y jefe del restaurante en la base de datos.
  ///
  /// Primero, se crea un `UserModel` para el jefe del restaurante,
  /// y se verifica si ya existe un usuario con ese email.
  /// Si existe, se muestra una alerta con un mensaje de error.
  /// Si no existe, se crea el usuario en la base de datos mediante
  /// `createOrUpdateAuthUserAndSave`, y se agrega a la lista de usuarios.
  ///
  /// Luego, se crean los camareros y cocineros del restaurante de la misma manera,
  /// y se agregan a la lista de usuarios.
  ///
  /// Finalmente, se actualiza el restaurante con las referencias a los usuarios
  /// mediante `updateUsersRestaurant`.
  ///
  /// Si ocurre un error, se muestra una alerta con el mensaje de error.
  ///
  /// Si se completa correctamente, se muestra una snackbar con un mensaje
  /// de exito.
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
        showErrorFlushbar(context, 'Jefe con email inválido.');
      } else {
        await createOrUpdateAuthUserAndSave(boss, id);
        print(boss.toJson());
        listUsers.add(boss);
      }
    } catch (e) {
      showErrorFlushbar(context, e.toString());
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
          showErrorFlushbar(context, 'Camarero con email inválido.');
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
          showErrorFlushbar(context, 'Cocinero con email inválido.');
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
      showErrorFlushbar(context, 'Error al actualizar restaurante: $e');
    }
  }

  @override
  /// Cancela la suscripción al stream de restaurantes y
  /// descarta todos los controladores de texto de la pantalla,
  /// incluyendo los de los campos de camareros y cocineros.
  /// Luego, llama a `super.dispose()` para liberar cualquier
  /// otro recurso que el widget pueda estar utilizando.
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
          const Menu(role: 'Admin'),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 36, bottom: 16),
              child: Padding(
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
                                    const SizedBox(height: 20),
                                    buildTextField(
                                      "CIF",
                                      restauranteControllers['cif']!,
                                      keyboardType: TextInputType.text,
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
                              Expanded(
                                child: buildTextField(
                                  "Número de Camareros",
                                  _camarerosCountController,
                                  keyboardType: TextInputType.number,
                                  onChanged: (_) => updateDynamicFields(),
                                ),
                              ),

                              const SizedBox(width: 20),

                              Expanded(
                                child: buildTextField(
                                  "Número de Cocineros",
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
                                  Expanded(
                                    child: buildTextField(
                                      "Nombre ${entry.key + 1}",
                                      camarero['nombre']!,
                                    ),
                                  ),

                                  const SizedBox(width: 20),

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
                      }),
                    ],

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
                                  Expanded(
                                    child: buildTextField(
                                      "Nombre ${entry.key + 1}",
                                      cocinero['nombre']!,
                                    ),
                                  ),

                                  const SizedBox(width: 20),

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
                      }),
                    ],

                    const SizedBox(height: 30),

                    Center(
                      child: Wrap(
                        spacing: 20,
                        runSpacing: 10,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              if (!validateFields()) {
                                showDialog(
                                  context: context,
                                  builder:
                                      (_) => const CustomAlertDialog(
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
                              ).colorScheme.secondary.withAlpha(50),
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
