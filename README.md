# BarSync

BarSync es una aplicación Flutter para gestionar el trabajo operativo de un restaurante desde distintos roles de usuario. El proyecto combina una app multiplataforma con Firebase y funciones backend para autenticación, datos en tiempo real, pedidos, mesas, productos, notificaciones y apoyo a impresión.

## 🚀 Demo

> Actualmente no hay una demo pública disponible. El proyecto puede ejecutarse en local siguiendo las instrucciones de instalación.

> Para probar la aplicación en un dispositivo Android, se puede generar un APK siguiendo los pasos indicados en la sección de instalación.

## 📸 Capturas

> Pendiente de añadir capturas de pantalla de la aplicación.

El repositorio sí incluye assets visuales de la app en `barsync/assets/images/` y `barsync/assets/icons/`, pero no se han detectado capturas finales de pantalla.

## 🧩 Funcionalidades

* Inicio de sesión con Firebase Authentication mediante email y contraseña.
* Recuperación y cambio de contraseña, incluyendo flujo de primer acceso.
* Navegación por roles: `Admin`, `Boss`, `Waiter` y `Cooker`.
* Administración de restaurantes y usuarios asociados a cada restaurante.
* Gestión de categorías y productos para el restaurante.
* Gestión visual de mesas y barras.
* Creación de pedidos por parte del camarero.
* Pantallas de cocina para pedidos pendientes y pedidos preparados.
* Marcado de productos como preparados y actualización de estado de pedidos.
* Gestión de cuentas/facturación de mesas.
* Persistencia en Cloud Firestore con streams en tiempo real.
* Uso de Firebase Cloud Messaging para notificaciones.
* Cloud Functions para enviar notificaciones y eliminar usuarios por email.
* Selección de imágenes con `image_picker`.
* Generación de documentos con `pdf` y `printing`.
* Integración con impresión térmica Bluetooth mediante `print_bluetooth_thermal` y `flutter_blue_plus`.

## 🛠️ Tecnologías utilizadas

**Mobile**

* Flutter
* Dart
* Material Design

**Backend y servicios**

* Firebase Authentication
* Cloud Firestore
* Firebase Storage
* Firebase Cloud Messaging
* Firebase Cloud Functions
* Node.js

**Librerías relevantes**

* `another_flushbar`
* `cloud_functions`
* `firebase_core`
* `firebase_auth`
* `cloud_firestore`
* `firebase_messaging`
* `firebase_storage`
* `flutter_local_notifications`
* `http`
* `image_picker`
* `pdf`
* `printing`
* `print_bluetooth_thermal`
* `flutter_blue_plus`

**Herramientas**

* Firebase CLI
* ESLint para Cloud Functions
* `flutter_launcher_icons`

## 🏗️ Arquitectura y estructura

El repositorio está organizado como una solución con una app Flutter y un backend Firebase separado.

```text
Barsync/
├── barsync/
│   ├── android/
│   ├── ios/
│   ├── lib/
│   │   ├── components/
│   │   ├── models/
│   │   ├── pages/
│   │   │   ├── admin/
│   │   │   ├── boss/
│   │   │   ├── kitchen/
│   │   │   ├── login/
│   │   │   └── waiter/
│   │   ├── services/
│   │   │   ├── auth/
│   │   │   └── database/
│   │   └── utils/
│   ├── assets/
│   └── pubspec.yaml
└── firebase-backend/
    ├── firebase.json
    └── functions/
        ├── index.js
        └── package.json
```

La app separa modelos, servicios, componentes reutilizables, utilidades y pantallas por rol. El backend Firebase contiene funciones HTTP/callable para tareas que no deben ejecutarse directamente desde el cliente.

## ⚙️ Instalación y ejecución

### App Flutter

```bash
cd barsync
flutter pub get
flutter run
```

Para generar un APK de Android:

```bash
flutter build apk --release
```

### Firebase Functions

```bash
cd firebase-backend/functions
npm install
npm run lint
npm run serve
```

Para desplegar las funciones:

```bash
npm run deploy
```

## 🧪 Tests

> Actualmente no se han detectado tests automatizados en el repositorio.

El proyecto incluye `flutter_test` como dependencia de desarrollo, pero no se ha encontrado carpeta `test/` con pruebas versionadas dentro de `barsync/`.

## 📦 Build o despliegue

App Android:

```bash
cd barsync
flutter build apk --release
```

Firebase Functions:

```bash
cd firebase-backend/functions
npm run deploy
```

## 🔐 Variables de entorno

No se ha detectado un archivo `.env.example`.

Configuración encontrada:

* `barsync/android/app/google-services.json`: configuración de Firebase para Android.
* `firebase-backend/.firebaserc`: referencia al proyecto Firebase `barsync-68a03`.
* `firebase-backend/firebase.json`: configuración de Cloud Functions.

Pendiente de confirmar:

* Configuración equivalente para iOS si se va a ejecutar en dispositivos Apple.
* Reglas de seguridad de Firestore/Storage.
* Documentación de permisos necesarios para notificaciones e impresión Bluetooth.
* Revisar el uso de contraseña inicial en la creación de usuarios antes de usar el proyecto fuera de un entorno controlado.

## 📌 Estado del proyecto

Proyecto personal/académico en desarrollo. El código muestra una base funcional amplia para gestión de restaurantes, pero todavía faltan elementos importantes para presentarlo como producto cerrado.

Posibles mejoras futuras:

* Añadir capturas reales de las pantallas principales.
* Documentar el modelo de datos de Firestore.
* Añadir tests para autenticación, servicios de base de datos y flujos críticos de pedidos.
* Centralizar configuración sensible y endpoints.
* Revisar textos/acentos en algunos comentarios y cadenas visibles.
* Añadir una guía de roles y permisos.

## 👨‍💻 Autor

Lorenzo Bellido Barrena

* Portfolio: https://lorenzo-bellido.vercel.app/
* LinkedIn: https://www.linkedin.com/in/lorenzo-bellido-barrena/
* GitHub: https://github.com/LorenzoBellidoBarrena
* Email: [lorenzobeba2@gmail.com](mailto:lorenzobeba2@gmail.com)
