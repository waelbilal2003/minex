import 'package:firebase_messaging/firebase_messaging.dart';

import 'app_globals.dart'; // moved navigatorKey to avoid circular import

// الدالة التي يتم استدعاؤها عندما يكون التطبيق مغلقًا
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
}

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;

  // التعامل مع الإشعارات عند النقر عليها
  void _handleMessage(RemoteMessage? message) {
    if (message == null) return;

    // افتح صفحة الإشعارات عند النقر على أي إشعار
    navigatorKey.currentState?.pushNamed('/notifications');
  }

  // تهيئة الإعدادات والمستمعات
  Future<void> initNotifications() async {
    // طلب الإذن من المستخدم (ضروري لـ iOS و أندرويد 13+)
    await _firebaseMessaging.requestPermission();

    // جلب الـ FCM Token الفريد لهذا الجهاز
    final fcmToken = await _firebaseMessaging.getToken();
    print("FCM Token: $fcmToken");
    // ❗️❗️ هذا التوكن هو الذي يجب إرساله إلى زميلتك في الباك ايند
    // وحفظه مع بيانات المستخدم بعد تسجيل الدخول.

    // التعامل مع الإشعارات عند النقر عليها سواء كان التطبيق في الخلفية أو مغلقًا
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

    // التعامل مع الإشعارات التي تصل والتطبيق في المقدمة (مفتوح)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
        // هنا يمكنك إظهار تنبيه أو أي واجهة مخصصة داخل التطبيق
      }
    });

    // المستمع للإشعارات في الخلفية
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }
}
