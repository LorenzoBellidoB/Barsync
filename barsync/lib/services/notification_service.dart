import 'dart:convert';
import 'dart:io';

import 'package:barsync/utils/sesion.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'orders_channel', // ID del canal
    'Pedidos', // Nombre visible
    description: 'Notificaciones de productos y pedidos',
    importance: Importance.high,
  );

  Future<void> initFCM() async {
    // iOS permissions
    if (Platform.isIOS) {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        print('🚫 Permiso de notificaciones denegado en iOS');
        return;
      }
    }

    // Android: Crear canal
    if (Platform.isAndroid) {
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_channel);
    }

    // Inicializar plugin de notificaciones locales
    const initializationSettingsAndroid = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initializationSettingsIOS = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Token
    final token = await _messaging.getToken();
    if (token != null) await _saveTokenToFirestore(token);

    _messaging.onTokenRefresh.listen(_saveTokenToFirestore);

    setupListeners();
  }

  Future<void> sendNotificationToToken({
    required String token,
    required String title,
    required String body,
  }) async {
    const url =
        'https://us-central1-barsync-68a03.cloudfunctions.net/notifyWaiter';

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'token': token, 'title': title, 'body': body}),
    );

    if (response.statusCode == 200) {
      print("Notificación enviada correctamente");
    } else {
      print("Error al enviar la notificación: ${response.body}");
    }
  }

  Future<void> _saveTokenToFirestore(String token) async {
    if (!Session().isLoggedIn) {
      print("⚠️ No hay usuario logueado, no se guarda token FCM.");
      return;
    }
    final user = Session().currentUser;
    print(user.toJson());
    print("🧾 ID del usuario actual: ${user.id}");

    final userRef = _db.collection('users').doc(user.id);
    await userRef.set({'fcmToken': token}, SetOptions(merge: true));
    print('✅ Token FCM guardado: $token');
  }

  void setupListeners() {
    // Foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage msg) {
      print('🔔 Notificación foreground: ${msg.notification?.title}');

      RemoteNotification? notification = msg.notification;
      AndroidNotification? android = msg.notification?.android;

      if (notification != null && android != null && Platform.isAndroid) {
        _flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              icon: android.smallIcon,
            ),
          ),
        );
      }
    });

    // App abierta desde notificación
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage msg) {
      print('📲 App abierta desde notificación: ${msg.notification?.title}');
    });

    // App lanzada desde terminada
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        print(
          '🟢 App iniciada por una notificación: ${message.notification?.title}',
        );
      }
    });

    // Background
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
  }
}

// Handler global para mensajes en background
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('📩 Mensaje en background: ${message.notification?.body}');
}
