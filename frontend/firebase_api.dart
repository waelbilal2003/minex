import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'notification_storage.dart';
import 'app_globals.dart';

// الدالة التي يتم استدعاؤها عندما يكون التطبيق مغلقًا تمامًا
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("📱 [الخلفية] استلام إشعار: ${message.messageId}");

  // حفظ الإشعار في التخزين المحلي
  await _saveNotificationToStorage(message);
}

// دالة مساعدة لحفظ الإشعار
Future<void> _saveNotificationToStorage(RemoteMessage message) async {
  Map<String, dynamic> notificationData = {
    'id': message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
    'title':
        message.notification?.title ?? message.data['title'] ?? 'إشعار جديد',
    'content': message.notification?.body ?? message.data['body'] ?? '',
    'type': message.data['type'] ?? 'system',
    'related_id': message.data['related_id'],
    'related_type': message.data['related_type'],
    'is_read': 0,
    'created_at': DateTime.now().toIso8601String(),
    'data': message.data,
  };

  await NotificationStorage.saveNotification(notificationData);
  print('✅ تم حفظ الإشعار: ${notificationData['title']}');
}

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;

  // مثيل للإشعارات المحلية (لإظهار إشعارات عندما يكون التطبيق مفتوح)
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // التعامل مع الإشعارات عند النقر عليها
  void _handleMessage(RemoteMessage? message) {
    if (message == null) return;

    print('📱 تم النقر على الإشعار: ${message.messageId}');

    // حفظ الإشعار (في حالة لم يتم حفظه من قبل)
    _saveNotificationToStorage(message);

    // الانتقال إلى صفحة الإشعارات
    navigatorKey.currentState?.pushNamed('/notifications');
  }

  // تهيئة الإشعارات المحلية (لعرضها في المقدمة)
  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // عند النقر على الإشعار المحلي
        print('📱 تم النقر على إشعار محلي');
        navigatorKey.currentState?.pushNamed('/notifications');
      },
    );

    // إنشاء قناة إشعارات لـ Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'إشعارات مهمة',
      description: 'هذه القناة للإشعارات المهمة',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // عرض إشعار محلي
  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'high_importance_channel',
      'إشعارات مهمة',
      channelDescription: 'هذه القناة للإشعارات المهمة',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.messageId.hashCode,
      message.notification?.title ?? message.data['title'] ?? 'إشعار جديد',
      message.notification?.body ?? message.data['body'] ?? '',
      notificationDetails,
    );
  }

  // تهيئة الإعدادات والمستمعات
  Future<void> initNotifications() async {
    try {
      // طلب الإذن من المستخدم
      NotificationSettings settings =
          await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      print('📱 حالة الإذن: ${settings.authorizationStatus}');

      // تهيئة الإشعارات المحلية
      await _initLocalNotifications();

      // جلب الـ FCM Token
      final fcmToken = await _firebaseMessaging.getToken();
      print("📱 FCM Token: $fcmToken");

      // الاستماع لتحديثات التوكن
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        print("📱 تم تحديث FCM Token: $newToken");
        // يمكنك إرسال التوكن الجديد للسيرفر هنا
      });

      // ============================================
      // 1️⃣ التطبيق مفتوح (في المقدمة - Foreground)
      // ============================================
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        print('📱 [مفتوح] استلام إشعار: ${message.messageId}');
        print('📱 العنوان: ${message.notification?.title}');
        print('📱 المحتوى: ${message.notification?.body}');
        print('📱 البيانات: ${message.data}');

        // ✅ حفظ الإشعار في التخزين المحلي
        await _saveNotificationToStorage(message);

        // ✅ عرض إشعار محلي للمستخدم
        await _showLocalNotification(message);
      });

      // ============================================
      // 2️⃣ التطبيق في الخلفية (Background)
      // ============================================
      FirebaseMessaging.onMessageOpenedApp
          .listen((RemoteMessage message) async {
        print('📱 [خلفية - تم فتحه] استلام إشعار: ${message.messageId}');

        // ✅ حفظ الإشعار
        await _saveNotificationToStorage(message);

        // ✅ معالجة النقر
        _handleMessage(message);
      });

      // ============================================
      // 3️⃣ التطبيق مغلق تماماً (Terminated)
      // ============================================
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      // التحقق من وجود إشعار تم النقر عليه لفتح التطبيق
      RemoteMessage? initialMessage =
          await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        print('📱 [مغلق - تم فتحه] استلام إشعار: ${initialMessage.messageId}');
        await _saveNotificationToStorage(initialMessage);
        _handleMessage(initialMessage);
      }

      print('✅ تم تهيئة Firebase Messaging بنجاح');
    } catch (e) {
      print('❌ خطأ في تهيئة الإشعارات: $e');
    }
  }
}
