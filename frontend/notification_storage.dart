import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationStorage {
  static const String _notificationsKey = 'stored_notifications';

  // حفظ إشعار جديد
  static Future<void> saveNotification(
      Map<String, dynamic> notification) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // جلب الإشعارات المحفوظة
      List<Map<String, dynamic>> notifications = await getNotifications();

      // إضافة timestamp إذا لم يكن موجود
      if (!notification.containsKey('created_at')) {
        notification['created_at'] = DateTime.now().toIso8601String();
      }

      // إضافة معرف فريد إذا لم يكن موجود
      if (!notification.containsKey('id')) {
        notification['id'] = DateTime.now().millisecondsSinceEpoch.toString();
      }

      // إضافة حالة القراءة
      if (!notification.containsKey('is_read')) {
        notification['is_read'] = 0;
      }

      // إضافة الإشعار الجديد في البداية
      notifications.insert(0, notification);

      // حفظ القائمة المحدثة
      String jsonString = jsonEncode(notifications);
      await prefs.setString(_notificationsKey, jsonString);

      print('✅ تم حفظ الإشعار بنجاح: ${notification['title']}');
    } catch (e) {
      print('❌ خطأ في حفظ الإشعار: $e');
    }
  }

  // جلب جميع الإشعارات المحفوظة
  static Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? jsonString = prefs.getString(_notificationsKey);

      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      print('❌ خطأ في جلب الإشعارات: $e');
      return [];
    }
  }

  // تحديث حالة الإشعار (مقروء/غير مقروء)
  static Future<void> markAsRead(String notificationId) async {
    try {
      List<Map<String, dynamic>> notifications = await getNotifications();

      for (var notification in notifications) {
        if (notification['id'] == notificationId) {
          notification['is_read'] = 1;
          break;
        }
      }

      final prefs = await SharedPreferences.getInstance();
      String jsonString = jsonEncode(notifications);
      await prefs.setString(_notificationsKey, jsonString);
    } catch (e) {
      print('❌ خطأ في تحديث حالة الإشعار: $e');
    }
  }

  // تحديد جميع الإشعارات كمقروءة
  static Future<void> markAllAsRead() async {
    try {
      List<Map<String, dynamic>> notifications = await getNotifications();

      for (var notification in notifications) {
        notification['is_read'] = 1;
      }

      final prefs = await SharedPreferences.getInstance();
      String jsonString = jsonEncode(notifications);
      await prefs.setString(_notificationsKey, jsonString);
    } catch (e) {
      print('❌ خطأ في تحديث الإشعارات: $e');
    }
  }

  // مسح كل الإشعارات المحفوظة
  static Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_notificationsKey);
      print('✅ تم مسح جميع الإشعارات');
    } catch (e) {
      print('❌ خطأ في مسح الإشعارات: $e');
    }
  }

  // الحصول على عدد الإشعارات غير المقروءة
  static Future<int> getUnreadCount() async {
    try {
      List<Map<String, dynamic>> notifications = await getNotifications();
      return notifications.where((n) => n['is_read'] != 1).length;
    } catch (e) {
      print('❌ خطأ في حساب الإشعارات غير المقروءة: $e');
      return 0;
    }
  }
}
