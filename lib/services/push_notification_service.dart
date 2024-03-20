// ignore_for_file: avoid_print

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_fcm/model/push_notification_model.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as flutter_local_notifications;

class PushNotificationService {
  Future<void> setupInteractedMessage() async {
    await Firebase.initializeApp();
    FirebaseMessaging.onMessageOpenedApp.listen(
      (RemoteMessage message) {
        PushNotification(title: message.notification?.title, body: message.notification?.title);
      },
    );
    enableIOSNotifications();
    getFirebaseToken();
    await registerNotificationListeners();
  }

  Future<void> registerNotificationListeners() async {
    final AndroidNotificationChannel channel = androidNotificationChannel();
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@drawable/ic_launcher');
    const DarwinInitializationSettings iOSSettings = DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
    );
    const InitializationSettings initSettings = InitializationSettings(android: androidSettings, iOS: iOSSettings);

    flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        final List<String> str = details.payload!.replaceAll('{', '').replaceAll('}', '').split(',');
        final Map<String, dynamic> result = <String, dynamic>{};
        for (int i = 0; i < str.length; i++) {
          final List<String> s = str[i].split(':');
          result.putIfAbsent(s[0].trim(), () => s[1].trim());
        }
        // notificationRedirect(result[keyTypeValue], result[keyType]);
      },
    );
// onMessage is called when the app is in foreground and a notification is received
    FirebaseMessaging.onMessage.listen((RemoteMessage? message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message?.data}');

      final RemoteNotification? notification = message!.notification;
      final AndroidNotification? android = message.notification?.android;
      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          flutter_local_notifications.NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              playSound: true,
              channelDescription: channel.description,
              icon: '@drawable/ic_launcher',
              importance: Importance.max,
              priority: Priority.max,
            ),
          ),
          payload: message.data.toString(),
        );
      }
    });
  }

  Future<void> enableIOSNotifications() async {
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true, // Required to display a heads up notification
      badge: true,
      sound: true,
    );
  }

  Future<String> getFirebaseToken() async {
    final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
    String token = '';
    firebaseMessaging.getToken().then((value) {
      if (!kReleaseMode) {
        print("FCM TOKEN =====> $value");
      }
      token = value.toString();
    });
    return token;
  }

  AndroidNotificationChannel androidNotificationChannel() => const AndroidNotificationChannel(
        'channel_id_6', // id
        'High Importance Notifications', // title
        description: 'This channel is used for important notifications.', // description
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('notification'),
      );
}
