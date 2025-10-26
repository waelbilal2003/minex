import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AuthService {
  static String baseUrl = 'https://kiniru.site';

  // مفاتيح التخزين المحلي
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _userNameKey = 'user_name';
  static const String _userEmailKey = 'user_email';
  static const String _userPhoneKey = 'user_phone';
  static const String _userGenderKey = 'user_gender';
  static const String _userIsAdminKey = 'user_is_admin';
  static const String _userTypeKey = 'user_type';

  // نموذج المستخدم
  static Map<String, dynamic>? _currentUser;
  // --- ✨✨ بداية الإصلاح: تعريف المتغير المفقود ✨✨ ---
  static String? _userToken;
  // --- ✨✨ نهاية الإصلاح ✨✨ ---
  static String? _currentToken;

  // الحصول على التوكن
  static Future<String?> getToken() async {
    if (_currentToken == null) {
      await loadUserData();
    }
    return _currentToken;
  }

  // الحصول على المستخدم الحالي
  static Map<String, dynamic>? get currentUser => _currentUser;
  static String? get currentToken => _currentToken;
  static bool get isLoggedIn => _currentToken != null && _currentUser != null;

  // التحقق من صحة المشرف
  static bool get isAdmin {
    if (_currentUser != null && _currentUser!.containsKey('is_admin')) {
      return _currentUser!['is_admin'] == 1;
    }
    return false;
  }

  // التحقق من صلاحيات الإدارة قبل تنفيذ العمليات الحساسة
  static bool checkAdminPermissions() {
    if (!isLoggedIn) {
      return false;
    }
    return isAdmin;
  }

  // إنشاء ترويسات HTTP موحدة
  static Map<String, String> getHeaders([String? token]) {
    Map<String, String> headers = {
      'Accept': 'application/json',
      // ✅ تم التعديل: حذف 'Content-Type' من هنا لأنه سيتم تعيينه تلقائيًا حسب نوع الطلب (form-data, json, etc)
      // 'Content-Type': 'application/json; charset=utf-8',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // معالج الاستجابة الموحد
  static Map<String, dynamic> _handleResponse(
    http.Response response,
    String action,
  ) {
    print('📥 استجابة $action:');
    print('Status Code: ${response.statusCode}');
    print('Headers: ${response.headers}');
    print('Body: ${response.body}');

    // ✅ تم التعديل: قبول كود 200 و 201 (Created) كاستجابات ناجحة
    if (response.statusCode != 200 && response.statusCode != 201) {
      return {
        'success': false,
        'message':
            'خطأ في الخادم (${response.statusCode}): ${response.reasonPhrase}',
      };
    }

    try {
      final responseData = json.decode(response.body);
      return responseData is Map<String, dynamic>
          ? responseData
          : {'success': false, 'message': 'استجابة غير صحيحة من الخادم'};
    } catch (e) {
      print('❌ خطأ في تحليل JSON: $e');
      return {
        'success': false,
        'message': 'خطأ في تحليل استجابة الخادم: ${e.toString()}',
      };
    }
  }

  // ✅ دالة محسنة لإنشاء منشور مع دعم الصور والفيديوهات
  // ✅ تم التعديل: تغيير الرابط والطريقة لتتوافق مع Postman
  static Future<Map<String, dynamic>> createPost({
    required String category,
    required String title, // ✅ تم الإضافة: حقل title مطلوب حسب Postman
    required String content,
    String? price,
    String? location,
    List<String>? imagePaths,
    String? videoPath,
  }) async {
    try {
      final token = await getToken();
      // ✅ تم التعديل: تغيير الرابط إلى /api/posts/create
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/posts/create'),
      );

      // إضافة الترويسات
      if (token != null) {
        request.headers.addAll(getHeaders(token));
      }

      // إضافة البيانات النصية
      // ✅ تم التعديل: إضافة حقل title
      request.fields['title'] = title;
      request.fields['category'] = category;
      request.fields['content'] = content;
      if (price != null && price.isNotEmpty) {
        request.fields['price'] = price;
      }
      if (location != null && location.isNotEmpty) {
        request.fields['location'] = location;
      }

      // إضافة الصور
      if (imagePaths != null && imagePaths.isNotEmpty) {
        for (int i = 0; i < imagePaths.length; i++) {
          var file = await http.MultipartFile.fromPath(
            'images[]', // ✅ تم التأكيد: اسم الحقل كما في Postman
            imagePaths[i],
          );
          request.files.add(file);
        }
      }

      // إضافة الفيديو
      if (videoPath != null && videoPath.isNotEmpty) {
        var videoFile = await http.MultipartFile.fromPath(
            'video', videoPath); // ✅ تم التأكيد: اسم الحقل كما في Postman
        request.files.add(videoFile);
      }

      print('📤 إرسال طلب إنشاء منشور...');
      print('URL: ${request.url}');
      print('Fields: ${request.fields}');
      print('Files: ${request.files.length} ملف');

      final streamedResponse = await request.send().timeout(
            const Duration(seconds: 60),
          );
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response, 'create_post');
    } catch (e) {
      print('❌ خطأ في إنشاء المنشور: $e');
      return {
        'success': false,
        'message': 'خطأ في إنشاء المنشور: ${e.toString()}',
      };
    }
  }

  // ✅ دالة محسنة لجلب المنشورات
  // ✅ تم التعديل: تغيير الرابط والطريقة لتتوافق مع Postman
  static Future<Map<String, dynamic>> getPosts() async {
    try {
      final token = await getToken();
      // ✅ تم التعديل: تغيير الرابط إلى /api/posts والطريقة إلى GET
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/posts'),
            headers: getHeaders(token),
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response, 'get_posts');
    } catch (e) {
      return {
        'success': false,
        'message': 'خطأ في جلب المنشورات: ${e.toString()}',
      };
    }
  }

  // ======== العمليات الإدارية الجديدة ========

  // جلب إحصائيات التطبيق
  // ✅ تم التعديل: تغيير الرابط والطريقة لتتوافق مع Postman
  static Future<Map<String, dynamic>> getAppStatistics() async {
    if (!checkAdminPermissions()) {
      return {'success': false, 'message': 'ليس لديك صلاحيات إدارية'};
    }
    try {
      final token = await getToken();
      // ✅ تم التعديل: تغيير الرابط إلى /api/statistics
      final response = await http
          .get(
            // ✅ تم التعديل: تغيير الطريقة إلى GET
            Uri.parse('$baseUrl/api/statistics'),
            headers: getHeaders(token),
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response, 'getAppStatistics');
    } catch (e) {
      return {
        'success': false,
        'message': 'خطأ في جلب الإحصائيات: ${e.toString()}',
      };
    }
  }

  // جلب الإحصائيات التفصيلية
  // ✅ تم التعديل: تغيير الرابط والطريقة لتتوافق مع Postman
  static Future<Map<String, dynamic>> getDetailedStatistics() async {
    if (!checkAdminPermissions()) {
      return {'success': false, 'message': 'ليس لديك صلاحيات إدارية'};
    }
    try {
      final token = await getToken();
      // ✅ تم التعديل: تغيير الرابط إلى /api/statistics/detailed
      final response = await http
          .get(
            // ✅ تم التعديل: تغيير الطريقة إلى GET
            Uri.parse('$baseUrl/api/statistics/detailed'),
            headers: getHeaders(token),
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response, 'getDetailedStatistics');
    } catch (e) {
      return {
        'success': false,
        'message': 'خطأ في جلب الإحصائيات التفصيلية: ${e.toString()}',
      };
    }
  }

  // جلب جميع المستخدمين
  // ✅ تم التعديل: تغيير الرابط والطريقة لتتوافق مع Postman
  static Future<Map<String, dynamic>> getAllUsers() async {
    if (!checkAdminPermissions()) {
      return {'success': false, 'message': 'ليس لديك صلاحيات إدارية'};
    }
    try {
      final token = await getToken();
      // ✅ تم التعديل: تغيير الرابط إلى /api/users
      final response = await http
          .get(
            // ✅ تم التعديل: تغيير الطريقة إلى GET
            Uri.parse('$baseUrl/api/users'),
            headers: getHeaders(token),
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response, 'getAllUsers');
    } catch (e) {
      return {
        'success': false,
        'message': 'خطأ في جلب المستخدمين: ${e.toString()}',
      };
    }
  }

  // جلب جميع المنشورات (للأدمن)
  // ✅ تم التعديل: تغيير الرابط والطريقة لتتوافق مع Postman
  static Future<Map<String, dynamic>> getAllPosts() async {
    if (!checkAdminPermissions()) {
      return {'success': false, 'message': 'ليس لديك صلاحيات إدارية'};
    }
    try {
      final token = await getToken();
      // ✅ تم التعديل: تغيير الرابط إلى /api/admin/posts
      final response = await http
          .get(
            // ✅ تم التعديل: تغيير الطريقة إلى GET
            Uri.parse('$baseUrl/api/admin/posts'),
            headers: getHeaders(token),
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response, 'getAllPosts');
    } catch (e) {
      return {
        'success': false,
        'message': 'خطأ في جلب المنشورات: ${e.toString()}',
      };
    }
  }

  // حذف منشور
  // ✅ تم التعديل: تغيير الرابط والطريقة لتتوافق مع Postman
  static Future<Map<String, dynamic>> deletePost(int postId) async {
    // --- تم التعديل هنا ---
    // تم حذف التحقق من صلاحيات الأدمن ليتم من جهة الخادم
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'المستخدم غير مسجل الدخول'};
      }
      // ✅ تم التعديل: تغيير الرابط إلى /api/posts/delete?post_id=X والطريقة إلى DELETE
      final response = await http
          .delete(
            Uri.parse('$baseUrl/api/posts/delete?post_id=$postId'),
            headers: getHeaders(token),
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response, 'deletePost');
    } catch (e) {
      return {
        'success': false,
        'message': 'خطأ في حذف المنشور: ${e.toString()}',
      };
    }
  }

  // تغيير حالة المستخدم (تفعيل/حظر)
  // ✅ تم التعديل: تغيير الرابط والطريقة لتتوافق مع Postman
  static Future<Map<String, dynamic>> toggleUserStatus(
      int userId, bool isActive) async {
    if (!checkAdminPermissions()) {
      return {'success': false, 'message': 'ليس لديك صلاحيات إدارية'};
    }
    try {
      final token = await getToken();
      // ✅ الإصلاح: استرجاع ?user_id= بدلاً من ?id=
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/users/toggle-status?id=$userId'),
            headers: getHeaders(token),
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response, 'toggleUserStatus');
    } catch (e) {
      return {
        'success': false,
        'message': 'خطأ في تغيير حالة المستخدم: ${e.toString()}',
      };
    }
  }

  // حذف مستخدم نهائياً
  // ✅ تم التعديل: تغيير الرابط والطريقة لتتوافق مع Postman
  static Future<Map<String, dynamic>> deleteUserPermanently(int userId) async {
    if (!checkAdminPermissions()) {
      return {'success': false, 'message': 'ليس لديك صلاحيات إدارية'};
    }
    try {
      final token = await getToken();
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/users/delete?id=$userId'),
            headers: getHeaders(token),
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response, 'deleteUserPermanently');
    } catch (e) {
      return {
        'success': false,
        'message': 'خطأ في حذف المستخدم: ${e.toString()}',
      };
    }
  }

  // جلب المنشورات المبلغ عنها
  // ✅ تم التعديل: تغيير الرابط والطريقة لتتوافق مع Postman
  static Future<Map<String, dynamic>> getReportedPosts() async {
    if (!checkAdminPermissions()) {
      return {'success': false, 'message': 'ليس لديك صلاحيات إدارية'};
    }
    try {
      final token = await getToken();
      // ✅ تم التعديل: تغيير الرابط إلى /api/show/reports/posts
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/show/reports/posts'),
            headers: getHeaders(token),
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response, 'getReportedPosts');
    } catch (e) {
      return {
        'success': false,
        'message': 'خطأ في جلب التقارير: ${e.toString()}',
      };
    }
  }

  // جلب الفئات
  // ✅ تم التعديل: تغيير الرابط والطريقة لتتوافق مع Postman
  static Future<Map<String, dynamic>> getCategories() async {
    try {
      // ✅ تم التعديل: تغيير الرابط إلى /api/categories
      final response = await http
          .get(Uri.parse('$baseUrl/api/categories'))
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response, 'getCategories');
    } catch (e) {
      return {
        'success': false,
        'message': 'خطأ في جلب الفئات: ${e.toString()}',
      };
    }
  }

  // جلب الإعلانات المميزة
  // ✅ تم التعديل: تغيير الرابط والطريقة لتتوافق مع Postman
  static Future<Map<String, dynamic>> getVipAds() async {
    if (!checkAdminPermissions()) {
      return {'success': false, 'message': 'ليس لديك صلاحيات إدارية'};
    }
    try {
      final token = await getToken();
      // ✅ تم التعديل: تغيير الرابط إلى /api/vip-ads
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/vip-ads'),
            headers: getHeaders(token),
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response, 'getVipAds');
    } catch (e) {
      return {
        'success': false,
        'message': 'خطأ في جلب الإعلانات المميزة: ${e.toString()}',
      };
    }
  }

  // حذف إعلان مميز (افترضنا الرابط بناءً على المنطق)
  // ✅ تم التعديل: افتراض رابط DELETE /api/vip-ads/{id}
  static Future<Map<String, dynamic>> deleteVipAd(int adId) async {
    if (!checkAdminPermissions()) {
      return {'success': false, 'message': 'ليس لديك صلاحيات إدارية'};
    }
    try {
      final token = await getToken();
      // ✅ تم التعديل: افتراض رابط حذف
      final response = await http
          .delete(
            Uri.parse('$baseUrl/api/vip-ads/$adId'),
            headers: getHeaders(token),
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response, 'deleteVipAd');
    } catch (e) {
      return {
        'success': false,
        'message': 'خطأ في حذف الإعلان المميز: ${e.toString()}',
      };
    }
  }

  // إرسال إشعار (افترضنا الرابط بناءً على المنطق)
  // ✅ تم التعديل: افتراض رابط POST /api/notifications
  static Future<Map<String, dynamic>> sendNotification({
    required String title,
    required String message,
    String? phone,
  }) async {
    if (!checkAdminPermissions()) {
      return {'success': false, 'message': 'ليس لديك صلاحيات إدارية'};
    }
    try {
      final token = await getToken();
      // ✅ تم التعديل: افتراض رابط إرسال إشعار
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/notifications'),
            headers: getHeaders(token),
            body: json.encode({
              'title': title,
              'message': message,
              'phone': phone,
            }),
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response, 'sendNotification');
    } catch (e) {
      return {
        'success': false,
        'message': 'خطأ في إرسال الإشعار: ${e.toString()}',
      };
    }
  }

  // حظر مستخدم (تم دمجه مع toggleUserStatus في Postman)
  // سنستخدم نفس دالة toggleUserStatus
  static Future<Map<String, dynamic>> blockUser(int userId) async {
    // ✅ تم التعديل: إعادة توجيه إلى toggleUserStatus مع false
    return toggleUserStatus(userId, false);
  }

  // ======== العمليات الأساسية ========

  // تسجيل مستخدم جديد
  static Future<Map<String, dynamic>> register({
    required String fullName,
    required String emailOrPhone,
    required String password,
    required String gender,
    String? userType,
  }) async {
    try {
      // === جلب device token مع طلب الإذن إذا لزم ===
      String? deviceToken;
      try {
        deviceToken = await FirebaseMessaging.instance.getToken();
        if (deviceToken == null) {
          await FirebaseMessaging.instance.requestPermission(
            alert: true,
            badge: true,
            sound: true,
          );
          deviceToken = await FirebaseMessaging.instance.getToken();
        }
      } catch (e) {
        print("⚠️ FCM token error: $e");
      }

      // === التحقق من صحة المدخلات ===
      if (gender != 'ذكر' && gender != 'أنثى') {
        return {'success': false, 'message': 'قيمة الجنس غير صالحة'};
      }

      String formattedEmailOrPhone = emailOrPhone;
      if (!isEmail(emailOrPhone)) {
        formattedEmailOrPhone = formatPhoneNumber(emailOrPhone);
        if (!isValidPhone(emailOrPhone)) {
          return {'success': false, 'message': 'رقم الهاتف غير صحيح'};
        }
      } else if (!isValidEmail(emailOrPhone)) {
        return {'success': false, 'message': 'البريد الإلكتروني غير صحيح'};
      }

      // === إعداد بيانات الطلب ===
      final Map<String, String> requestData = {
        'full_name': fullName,
        'email_or_phone': formattedEmailOrPhone,
        'password': password,
        'gender': gender,
      };

      // ✅ إضافة userType إذا وُجد
      if (userType != null) {
        requestData['userType'] = userType;
      }

      // ✅ ✅ ✅ إضافة device_token إلى الطلب (هذا هو المفتاح!) ✅ ✅ ✅
      if (deviceToken != null) {
        requestData['device_token'] = deviceToken;
        print('📱 device_token المرسل: $deviceToken');
      } else {
        print('⚠️ device_token غير متوفر عند التسجيل');
      }

      // === إرسال طلب التسجيل ===
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/register'),
            headers: getHeaders(),
            body: requestData,
          )
          .timeout(const Duration(seconds: 30));

      final result = _handleResponse(response, 'register');

      // === معالجة النجاح ===
      if (result['success'] == true) {
        await _saveUserData(result['data']);

        // تحديث بيانات المستخدم من الخادم (لضمان تزامن device_token إن تم حفظه لاحقًا)
        try {
          final profileResult = await getProfile();
          if (profileResult['success'] == true) {
            await _saveUserData(profileResult['data']);
          }
        } catch (e) {
          print('⚠️ تعذر جلب الملف الشخصي بعد التسجيل: $e');
        }

        return {
          'success': true,
          'message': result['message'] ?? 'تم التسجيل بنجاح',
          'user': _currentUser,
        };
      }

      return result;
    } catch (e) {
      print('❌ خطأ في التسجيل: $e');
      if (e.toString().contains('Failed to fetch')) {
        return {'success': false, 'message': '.تعذّر الاتصال بالخادم'};
      }
      return {
        'success': false,
        'message': 'خطأ في الاتصال بالخادم: ${e.toString()}',
      };
    }
  }

  // تسجيل دخول المستخدم
  // ✅ تم التعديل: تغيير الرابط والطريقة لتتوافق مع Postman
  static Future<Map<String, dynamic>> login({
    required String emailOrPhone,
    required String password,
  }) async {
    try {
      // جلب توكن الإشعارات من Firebase
      String? deviceToken;
      try {
        deviceToken = await FirebaseMessaging.instance.getToken();
      } catch (e) {
        print("⚠️ Failed to get FCM token: $e");
      }
      String formattedEmailOrPhone = emailOrPhone;
      if (!isEmail(emailOrPhone)) {
        formattedEmailOrPhone = formatPhoneNumber(emailOrPhone);
        // التحقق من صحة رقم الهاتف
        if (!isValidPhone(emailOrPhone)) {
          return {'success': false, 'message': 'رقم الهاتف غير صحيح'};
        }
      } else if (!isValidEmail(emailOrPhone)) {
        return {'success': false, 'message': 'البريد الإلكتروني غير صحيح'};
      }

      // ✅ تم التعديل: إعداد البيانات كـ form-data
      final Map<String, String> requestData = {
        'email_or_phone': formattedEmailOrPhone,
        'password': password,
        // ✅ تم التعديل: device_token معطل في Postman، لذا تم حذفه
      };

      if (deviceToken != null) requestData['device_token'] = deviceToken;

      print('📤 إرسال طلب تسجيل الدخول...');
      print('URL: $baseUrl/api/login');
      print('البيانات: ${json.encode({...requestData, 'password': '***'})}');

      // ✅ تم التعديل: تغيير الرابط إلى /api/login
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/login'),
            headers: {
              ...getHeaders(),
              // ✅ تم التعديل: حذف 'Content-Type' ليتم تعيينه تلقائيًا
            },
            body: requestData, // إرسال كـ form-data
          )
          .timeout(const Duration(seconds: 30));

      final result = _handleResponse(response, 'login');

      if (result['success'] == true) {
        await _saveUserData(result['data']);
        return {
          'success': true,
          'message': result['message'] ?? 'تم تسجيل الدخول بنجاح',
          'user': result['data'],
        };
      }

      return result;
    } catch (e) {
      print('❌ خطأ في تسجيل الدخول: $e');
      if (e.toString().contains('Failed to fetch')) {
        return {
          'success': false,
          'message': '.تعذّر الاتصال بالخادم',
        };
      }
      return {
        'success': false,
        'message': 'خطأ في الاتصال بالخادم: ${e.toString()}',
      };
    }
  }

  // التحقق من صحة التوكن
  // ✅ تم التعديل: تغيير الرابط والطريقة لتتوافق مع Postman
  static Future<Map<String, dynamic>> verifyToken() async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'لا يوجد توكن محفوظ'};
      }

      // ✅ تم التعديل: تغيير الرابط إلى /api/verify_token
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/verify_token'),
            headers: getHeaders(token),
            // ✅ تم التعديل: Postman لا يحتوي على body، لذا تم حذفه
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response, 'verify_token');
    } catch (e) {
      return {
        'success': false,
        'message': 'خطأ في التحقق من التوكن: ${e.toString()}',
      };
    }
  }

  // استعادة كلمة المرور
  // ✅ تم التعديل: تغيير الرابط والطريقة لتتوافق مع Postman
  static Future<Map<String, dynamic>> forgotPassword({
    required String emailOrPhone,
  }) async {
    try {
      String formattedEmailOrPhone = emailOrPhone;
      if (!isEmail(emailOrPhone)) {
        formattedEmailOrPhone = formatPhoneNumber(emailOrPhone);
        if (!isValidPhone(emailOrPhone)) {
          return {'success': false, 'message': 'رقم الهاتف غير صحيح'};
        }
      } else if (!isValidEmail(emailOrPhone)) {
        return {'success': false, 'message': 'البريد الإلكتروني غير صحيح'};
      }

      // ✅ تم التعديل: إعداد البيانات كـ form-data
      final Map<String, String> requestData = {
        'email_or_phone': formattedEmailOrPhone,
      };

      // ✅ تم التعديل: تغيير الرابط إلى /api/forgot-password
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/forgot-password'),
            headers: {
              ...getHeaders(),
            },
            body: requestData,
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response, 'forgot_password');
    } catch (e) {
      return {
        'success': false,
        'message': 'خطأ في استعادة كلمة المرور: ${e.toString()}',
      };
    }
  }

  // جلب الملف الشخصي
  // ✅ تم التعديل: تغيير الرابط والطريقة لتتوافق مع Postman
  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final token = await getToken();
      if (token == null || _currentUser == null) {
        return {'success': false, 'message': 'المستخدم غير مسجل الدخول'};
      }

      print('📤 جلب الملف الشخصي...');
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/profile'),
            headers: getHeaders(token),
          )
          .timeout(const Duration(seconds: 30));

      final result = _handleResponse(response, 'profile');

      // ✅ إذا نجحت العملية، قم بحفظ البيانات المحدثة
      if (result['success'] == true && result['data'] != null) {
        await _saveUserData(result['data']);

        // ✅ إرجاع البيانات المحدثة من الذاكرة المحلية
        return {
          'success': true,
          'message': result['message'] ?? 'تم جلب البيانات بنجاح',
          'data': _currentUser,
        };
      }

      return result;
    } catch (e) {
      return {
        'success': false,
        'message': 'خطأ في جلب الملف الشخصي: ${e.toString()}',
      };
    }
  }

  // تحديث الملف الشخصي
  // ✅ تم التعديل: تغيير الرابط والطريقة لتتوافق مع Postman
  static Future<Map<String, dynamic>> updateProfile({
    required String fullName,
    String? gender,
  }) async {
    try {
      final token = await getToken();
      if (token == null || _currentUser == null) {
        return {'success': false, 'message': 'المستخدم غير مسجل الدخول'};
      }

      // ✅ تم التعديل: إعداد البيانات كـ form-data
      final Map<String, String> requestData = {
        'full_name': fullName,
      };

      // إذا تم توفير الجنس، قم بتحويله وإضافته
      if (gender != null && gender.isNotEmpty) {
        requestData['gender'] = _convertGenderToEnglish(gender);
      }

      // ✅ تم التعديل: تغيير الرابط إلى /api/profile/update
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/profile/update'),
            headers: {
              ...getHeaders(token),
              // ✅ تم التعديل: حذف 'Content-Type' ليتم تعيينه تلقائيًا
            },
            body: requestData, // إرسال كـ form-data
          )
          .timeout(const Duration(seconds: 30));

      final result = _handleResponse(response, 'update_profile');

      // ✨ التحسين: إذا نجحت العملية، قم بحفظ البيانات المحدثة العائدة من الخادم مباشرة
      if (result['success'] == true && result['data'] != null) {
        // الخادم يعيد بيانات المستخدم المحدثة، نقوم بحفظها مباشرة
        await _saveUserData(result['data']);
      }

      return result;
    } catch (e) {
      return {
        'success': false,
        'message': 'خطأ في تحديث الملف الشخصي: ${e.toString()}',
      };
    }
  }

  // تغيير كلمة المرور
  // ✅ تم التعديل: تغيير الرابط والطريقة لتتوافق مع Postman
  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final token = await getToken();
      if (token == null || _currentUser == null) {
        return {'success': false, 'message': 'المستخدم غير مسجل الدخول'};
      }

      // ✅ تم التعديل: إعداد البيانات كـ form-data
      final Map<String, String> requestData = {
        'current_password': currentPassword,
        'new_password': newPassword,
        'new_password_confirmation': newPassword, // ✅ تم الإضافة: حسب Postman
      };

      // ✅ تم التعديل: تغيير الرابط إلى /api/change-password
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/change-password'),
            headers: {
              ...getHeaders(token),
            },
            body: requestData,
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response, 'change_password');
    } catch (e) {
      return {
        'success': false,
        'message': 'خطأ في تغيير كلمة المرور: ${e.toString()}',
      };
    }
  }

  // حذف الحساب (افترضنا الرابط بناءً على المنطق)
  // ✅ تم التعديل: افتراض رابط DELETE /api/profile
  static Future<Map<String, dynamic>> deleteAccount() async {
    try {
      final token = await getToken();
      if (token == null || _currentUser == null) {
        return {'success': false, 'message': 'المستخدم غير مسجل الدخول'};
      }

      // ✅ تم التعديل: افتراض رابط حذف الحساب
      final response = await http
          .delete(
            Uri.parse('$baseUrl/api/profile'),
            headers: getHeaders(token),
          )
          .timeout(const Duration(seconds: 30));

      final result = _handleResponse(response, 'delete_account');

      if (result['success'] == true) {
        await logout();
      }

      return result;
    } catch (e) {
      return {
        'success': false,
        'message': 'خطأ في حذف الحساب: ${e.toString()}',
      };
    }
  }

  // ======== دوال التخزين المحلي ========

  // حفظ بيانات المستخدم
  static Future<void> _saveUserData(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentToken = userData['token'];
      _currentUser = {
        'user_id': userData['user_id'],
        'full_name': userData['full_name'],
        'email': userData['email'],
        'phone': userData['phone'],
        'gender': userData['gender'],
        'user_type': userData['user_type'] ??
            'person', // <-- ✨ أضف هذا السطر مع قيمة افتراضية
        'is_admin': userData['is_admin'] ?? 0,
      };

      await prefs.setString(_tokenKey, _currentToken!);
      await prefs.setInt(_userIdKey, userData['user_id']);
      await prefs.setString(_userNameKey, userData['full_name']);
      if (userData['email'] != null) {
        await prefs.setString(_userEmailKey, userData['email']);
      }
      if (userData['phone'] != null) {
        await prefs.setString(_userPhoneKey, userData['phone']);
      }
      await prefs.setString(_userGenderKey, userData['gender']);
      await prefs.setString(
        _userTypeKey,
        userData['user_type'] ?? 'person',
      ); // <-- ✨ أضف هذا السطر
      await prefs.setInt(_userIsAdminKey, userData['is_admin'] ?? 0);

      print('✅ تم حفظ بيانات المستخدم محلياً');
    } catch (e) {
      print('❌ خطأ في حفظ بيانات المستخدم: $e');
    }
  }

  // تحميل بيانات المستخدم
  static Future<void> loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentToken = prefs.getString(_tokenKey);
      if (_currentToken != null) {
        _currentUser = {
          'user_id': prefs.getInt(_userIdKey),
          'full_name': prefs.getString(_userNameKey),
          'email': prefs.getString(_userEmailKey),
          'phone': prefs.getString(_userPhoneKey),
          'gender': prefs.getString(_userGenderKey),
          'user_type': prefs.getString(_userTypeKey) ??
              'person', // <-- ✨ أضف هذا السطر مع قيمة افتراضية
          'is_admin': prefs.getInt(_userIsAdminKey) ?? 0,
        };
        print('✅ تم تحميل بيانات المستخدم من التخزين المحلي');
      }
    } catch (e) {
      print('❌ خطأ في تحميل بيانات المستخدم: $e');
    }
  }

  // تسجيل الخروج
  static Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      _currentToken = null;
      _currentUser = null;
      print('✅ تم تسجيل الخروج وحذف البيانات المحلية');
    } catch (e) {
      print('❌ خطأ في تسجيل الخروج: $e');
    }
  }

  // ======== دوال التحقق والتنسيق ========

  // التحقق من صحة البريد الإلكتروني
  static bool isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
  }

  // التحقق من صحة رقم الهاتف
  static bool isValidPhone(String phone) {
    String formatted = formatPhoneNumber(phone);
    return RegExp(r'^\+9639[0-9]{8}$').hasMatch(formatted);
  }

  // التحقق من نوع الإدخال (بريد إلكتروني أم رقم هاتف)
  static bool isEmail(String input) {
    return input.contains('@');
  }

  // تنسيق رقم الهاتف
  static String formatPhoneNumber(String phone) {
    // إزالة جميع الأحرف غير الرقمية
    phone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    // إزالة الصفر من البداية إن وجد
    if (phone.startsWith('0')) {
      phone = phone.substring(1);
    }
    // إضافة رمز البلد إذا لم يكن موجوداً
    if (!phone.startsWith('963')) {
      phone = '963$phone';
    }
    return '+$phone';
  }

  // تحويل الجنس من عربي إلى إنجليزي
  static String _convertGenderToEnglish(String gender) {
    gender = gender.toLowerCase().trim();
    if (gender == 'ذكر' || gender == 'male') {
      return 'male';
    } else if (gender == 'أنثى' || gender == 'female') {
      return 'female';
    }
    return '';
  }

  // تحويل الجنس من إنجليزي إلى عربي
  static String convertGenderToArabic(String gender) {
    gender = gender.toLowerCase().trim();
    if (gender == 'male' || gender == 'ذكر') {
      return 'ذكر';
    } else if (gender == 'female' || gender == 'أنثى') {
      return 'أنثى';
    }
    return '';
  }

  // رفع صورة غلاف للإعلان المميز
  // ✅ تم التعديل: تغيير الرابط والطريقة لتتوافق مع Postman
  static Future<Map<String, dynamic>> uploadVipCoverImage({
    required String imagePath,
    required String fileName,
  }) async {
    try {
      final token = await getToken();
      if (token == null)
        return {'success': false, 'message': 'المستخدم غير مسجل الدخول'};

      // 1. استخدام MultipartRequest بدلاً من http.post
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/vip-ads/upload-cover'),
      );

      request.headers.addAll(getHeaders(token));

      // 2. إضافة الحقول النصية
      request.fields['file_name'] = fileName;

      // 3. إضافة الملف الحقيقي من مساره
      request.files.add(
        await http.MultipartFile.fromPath(
          'image', // اسم حقل الملف الذي يتوقعه الخادم
          imagePath,
        ),
      );

      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response, 'uploadVipCoverImage');
    } catch (e) {
      return {
        'success': false,
        'message': 'خطأ في رفع صورة الغلاف: ${e.toString()}',
      };
    }
  }

  // رفع ملف وسائط للإعلان المميز
  // ✅ تم التعديل: تغيير الرابط والطريقة لتتوافق مع Postman
  static Future<Map<String, dynamic>> uploadVipMediaFile({
    required String filePath,
    required String fileName,
    required String fileType,
  }) async {
    try {
      final token = await getToken();
      if (token == null)
        return {'success': false, 'message': 'المستخدم غير مسجل الدخول'};

      // 1. استخدام MultipartRequest
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/vip-ads/uploadMediaFile'),
      );

      request.headers.addAll(getHeaders(token));

      // 2. إضافة الحقول النصية
      request.fields['file_name'] = fileName;
      request.fields['file_type'] = fileType;

      // 3. إضافة الملف الحقيقي من مساره (اسم الحقل هنا 'file')
      request.files.add(
        await http.MultipartFile.fromPath('file', filePath),
      );

      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 120));
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response, 'uploadVipMediaFile');
    } catch (e) {
      String errorMessage = 'خطأ في رفع الملف';
      if (e.toString().contains('Timeout')) errorMessage = 'انتهت مهلة الرفع';
      return {'success': false, 'message': '$errorMessage: ${e.toString()}'};
    }
  }

  // إنشاء إعلان مميز محسن
  // ✅ تم التعديل: تغيير الرابط والطريقة لتتوافق مع Postman
  static Future<Map<String, dynamic>> createEnhancedVipAd({
    required String title,
    String? description,
    required String coverImageUrl,
    List<String> mediaUrls = const [],
    String? contactPhone,
    String? contactWhatsapp,
    double? pricePaid,
    String? currency,
    int? durationHours,
    String status = 'active',
  }) async {
    try {
      final token = await getToken();
      // ✅ تم التعديل: تغيير الرابط إلى /api/vip-ads/createEnhancedVipAd
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/vip-ads/createEnhancedVipAd'),
            headers: {
              ...getHeaders(token),
              'Content-Type':
                  'application/json; charset=utf-8', // ✅ تم الإضافة: لأن الطلب raw json
            },
            body: json.encode({
              'title': title,
              'description': description,
              'cover_image_url': coverImageUrl,
              'media_files': mediaUrls,
              'contact_phone': contactPhone,
              'contact_whatsapp': contactWhatsapp,
              'price_paid': pricePaid,
              'currency': currency,
              'duration_hours': durationHours,
              'status': status,
            }),
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response, 'createEnhancedVipAd');
    } catch (e) {
      return {
        'success': false,
        'message': 'خطأ في إنشاء الإعلان: ${e.toString()}',
      };
    }
  }

  // جلب الإعلانات المميزة للعرض العام
  // جلب الإعلانات المميزة للعرض العام
  static Future<Map<String, dynamic>> getVipAdsForDisplay() async {
    try {
      print('📤 جلب إعلانات VIP للعرض العام...');

      // ✅ استخدام الرابط الصحيح من Postman: /api/vip-ads/public
      final response = await http
          .get(Uri.parse('$baseUrl/api/vip-ads/public'))
          .timeout(const Duration(seconds: 30));

      print('📥 استجابة إعلانات VIP: Status ${response.statusCode}');
      print('📥 محتوى الاستجابة: ${response.body}');

      final result = _handleResponse(response, 'get_vip_ads_public');

      if (result['success'] == true) {
        // ✅ التأكد من تنسيق البيانات
        final ads = result['data'] ?? result['ads'] ?? [];

        return {
          'success': true,
          'message': result['message'] ?? 'تم جلب الإعلانات المميزة بنجاح',
          'data': List<Map<String, dynamic>>.from(ads),
        };
      }

      return result;
    } catch (e) {
      print('❌ خطأ في جلب الإعلانات المميزة: $e');
      return {
        'success': false,
        'message': 'خطأ في جلب الإعلانات المميزة: ${e.toString()}',
        'data': [], // ✅ إرجاع قائمة فارغة في حالة الخطأ
      };
    }
  }

  // استدعاء ملف المستخدم ومنشوراته
  static Future<Map<String, dynamic>> getUserProfileAndPosts(int userId) async {
    try {
      final token = await getToken();
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/user/profile-and-posts?id=$userId'),
            headers: getHeaders(token),
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response, 'get_user_profile_and_posts');
    } catch (e) {
      print('❌ خطأ في جلب ملف المستخدم: $e');
      return {
        'success': false,
        'message': 'خطأ في جلب بيانات المستخدم: ${e.toString()}',
      };
    }
  }

  // دالة البحث
  // ✅ تم التعديل: تغيير الرابط والطريقة لتتوافق مع Postman
  static Future<Map<String, dynamic>> search(String query) async {
    try {
      if (query.trim().isEmpty) {
        return {'success': false, 'message': 'كلمة البحث مطلوبة'};
      }

      final token = await getToken();
      // ✅ تم التعديل: تغيير الرابط إلى /api/search?query=X
      final response = await http
          .get(
            Uri.parse(
              '$baseUrl/api/search?query=${Uri.encodeComponent(query)}',
            ),
            headers: getHeaders(token),
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response, 'search');
    } catch (e) {
      return {'success': false, 'message': 'خطأ في البحث: ${e.toString()}'};
    }
  }

  // ======== دوال المراسلة ========

  // جلب المحادثات
  // ✅ تم التعديل: تغيير الرابط والطريقة لتتوافق مع Postman
  static Future<Map<String, dynamic>> getConversations() async {
    try {
      final token = await getToken();
      // ✅ تم التعديل: تغيير الرابط إلى /api/conversations
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/conversations'),
            headers: getHeaders(token),
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response, 'get_conversations');
    } catch (e) {
      return {
        'success': false,
        'message': 'خطأ في جلب المحادثات: ${e.toString()}',
      };
    }
  }

  // جلب الرسائل
  // ✅ تم التعديل: تغيير الرابط والطريقة لتتوافق مع Postman
  static Future<Map<String, dynamic>> getMessages(
    int conversationId,
    int page,
  ) async {
    try {
      final token = await getToken();
      // ✅ تم التعديل: تغيير الرابط إلى /api/get/messages?conversation_id=X
      // ✅ تم التعديل: Postman لا يحتوي على page و limit في الرابط، لذا تم حذفهما
      final response = await http
          .get(
            Uri.parse(
              '$baseUrl/api/get/messages?conversation_id=$conversationId',
            ),
            headers: getHeaders(token),
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response, 'get_messages');
    } catch (e) {
      return {
        'success': false,
        'message': 'خطأ في جلب الرسائل: ${e.toString()}',
      };
    }
  }

  // إرسال رسالة
  // ✅ تم التعديل: تغيير الرابط والطريقة لتتوافق مع Postman
  static Future<Map<String, dynamic>> sendMessage(
    int receiverId,
    String content,
  ) async {
    try {
      final token = await getToken();
      // ✅ تم التعديل: تغيير الرابط إلى /api/send/messages
      // ✅ تم التعديل: إرسال البيانات كـ form-data
      final response = await http.post(
        Uri.parse('$baseUrl/api/send/messages'),
        headers: {
          ...getHeaders(token),
        },
        body: {
          'receiver_id': receiverId.toString(),
          'content': content,
        },
      ).timeout(const Duration(seconds: 30));

      return _handleResponse(response, 'send_message');
    } catch (e) {
      return {
        'success': false,
        'message': 'خطأ في إرسال الرسالة: ${e.toString()}',
      };
    }
  }

  // ======== دوال الإشعارات ========

  // جلب الإشعارات
  // ✅ تم التعديل: افتراض رابط GET /api/notifications
  static Future<Map<String, dynamic>> getNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'المستخدم غير مسجل الدخول'};
      }

      // ✅ تم التعديل: افتراض رابط جلب الإشعارات
      final response = await http
          .get(
            Uri.parse(
              '$baseUrl/api/notifications?page=$page&limit=$limit',
            ),
            headers: getHeaders(token),
          )
          .timeout(const Duration(seconds: 30));

      // معالجة خاصة للإشعارات مع دعم Firebase
      final result = _handleResponse(response, 'getNotifications');

      // إذا كان هناك خطأ 404، قم بإرجاع بيانات فارغة بدلاً من الخطأ
      if (response.statusCode == 404) {
        return {
          'success': true,
          'data': {
            'notifications': [],
            'unread_count': 0,
            'total': 0,
            'current_page': page,
          },
          'message': 'لا توجد إشعارات متاحة حالياً'
        };
      }

      return result;
    } catch (e) {
      // في حالة عدم توفر endpoint الإشعارات، أرجع بيانات فارغة
      if (e.toString().contains('404') || e.toString().contains('Not Found')) {
        return {
          'success': true,
          'data': {
            'notifications': [],
            'unread_count': 0,
            'total': 0,
            'current_page': page,
          },
          'message': 'نظام الإشعارات غير مفعل حالياً'
        };
      }

      return {
        'success': false,
        'message': 'خطأ في جلب الإشعارات: ${e.toString()}',
        'status_code': 500,
      };
    }
  }

  // تعليم الإشعارات كمقروءة
  // ✅ تم التعديل: افتراض رابط POST /api/notifications/mark-as-read
  static Future<Map<String, dynamic>> markNotificationsAsRead({
    List<int>? notificationIds,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'المستخدم غير مسجل الدخول'};
      }

      final requestData = <String, dynamic>{};
      if (notificationIds != null) {
        requestData['notification_ids'] = notificationIds;
      }

      // ✅ تم التعديل: افتراض رابط تعليم كمقروء
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/notifications/mark-as-read'),
            headers: getHeaders(token),
            body: json.encode(requestData),
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response, 'markNotificationsAsRead');
    } catch (e) {
      return {
        'success': false,
        'message': 'خطأ في تحديث الإشعارات: ${e.toString()}',
      };
    }
  }

  // ======== دوال التقارير/الإبلاغات ========

  // الإبلاغ عن منشور
  // ✅ تم التعديل: تغيير الرابط والطريقة لتتوافق مع Postman
  static Future<Map<String, dynamic>> reportPost({
    required int postId,
    required String reason,
    String? description,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'المستخدم غير مسجل الدخول'};
      }

      // ✅ تم التعديل: إرسال البيانات كـ form-data
      final Map<String, String> requestData = {
        'post_id': postId.toString(),
        'reason': reason,
        'description': description ?? '',
      };

      // ✅ تم التعديل: تغيير الرابط إلى /api/posts/report
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/posts/report'),
            headers: {
              ...getHeaders(token),
            },
            body: requestData,
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response, 'reportPost');
    } catch (e) {
      return {
        'success': false,
        'message': 'خطأ في إرسال الإبلاغ: ${e.toString()}',
      };
    }
  }

  // جلب تقارير المنشورات (للأدمن)
  // ✅ تم التعديل: تغيير الرابط والطريقة لتتوافق مع Postman
  static Future<Map<String, dynamic>> getPostReports() async {
    if (!checkAdminPermissions()) {
      return {'success': false, 'message': 'ليس لديك صلاحيات إدارية'};
    }
    try {
      final token = await getToken();
      // ✅ تم التعديل: تغيير الرابط إلى /api/show/reports/posts
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/show/reports/posts'),
            headers: getHeaders(token),
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response, 'getPostReports');
    } catch (e) {
      return {
        'success': false,
        'message': 'خطأ في جلب التقارير: ${e.toString()}',
      };
    }
  }

  // تحديث حالة التقرير
  // ✅ تم التعديل: تغيير الرابط والطريقة لتتوافق مع Postman
  static Future<Map<String, dynamic>> updateReportStatus({
    required int reportId,
    required String status,
    String? adminResponse,
  }) async {
    if (!checkAdminPermissions()) {
      return {'success': false, 'message': 'ليس لديك صلاحيات إدارية'};
    }
    try {
      final token = await getToken();
      // ✅ تم التعديل: إرسال البيانات كـ form-data
      final Map<String, String> requestData = {
        'report_id': reportId.toString(),
        'status': status,
        'admin_response': adminResponse ?? '',
      };

      // ✅ تم التعديل: تغيير الرابط إلى /api/reports/update-status
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/reports/update-status'),
            headers: {
              ...getHeaders(token),
            },
            body: requestData,
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response, 'updateReportStatus');
    } catch (e) {
      return {
        'success': false,
        'message': 'خطأ في تحديث التقرير: ${e.toString()}',
      };
    }
  }

  // الإبلاغ عن تعليق (افترضنا الرابط بناءً على منطق المنشور)
  // ✅ تم التعديل: افتراض رابط POST /api/comments/report
  static Future<Map<String, dynamic>> reportComment({
    required int commentId,
    required String reason,
    String? description,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'المستخدم غير مسجل الدخول'};
      }

      final requestData = {
        'comment_id': commentId,
        'reason': reason,
        'description': description ?? '',
      };

      // ✅ تم التعديل: افتراض رابط الإبلاغ عن تعليق
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/comments/report'),
            headers: getHeaders(token),
            body: json.encode(requestData),
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response, 'reportComment');
    } catch (e) {
      return {
        'success': false,
        'message': 'خطأ في إرسال الإبلاغ: ${e.toString()}',
      };
    }
  }

  // جلب المنشورات حسب الفئة
  static Future<Map<String, dynamic>> getPostsByCategory(String categoryName,
      {int page = 1}) async {
    try {
      final token = await getToken();

      // 🔍 البحث عن الـ ID المناسب للاسم
      int? categoryId = _findCategoryIdByName(categoryName);

      if (categoryId == null) {
        return {'success': false, 'message': 'القسم غير موجود: $categoryName'};
      }

      final uri = Uri.parse('$baseUrl/api/posts').replace(queryParameters: {
        'category_id': categoryId.toString(), // ✅ استخدام category_id
        'page': page.toString(),
      });

      final response = await http.get(uri, headers: getHeaders(token));
      return _handleResponse(response, 'get_posts_by_category');
    } catch (e) {
      return {'success': false, 'message': 'خطأ في جلب المنشورات: $e'};
    }
  }

// دالة مساعدة للعثور على ID القسم حسب الاسم
  static int? _findCategoryIdByName(String categoryName) {
    final categoryMap = {
      'التوظيف': 13,
      'المناقصات': 14,
      'الموردين': 15,
      'العروض العامة': 16,
      'السيارات': 1, // ✅ تصحيح: كان 5 في التطبيق، 1 في DB
      'الدراجات النارية': 2, // ✅ تصحيح
      'تجارة العقارات': 3, // ✅ تصحيح
      'المستلزمات العسكرية': 4, // ✅ تصحيح
      'الهواتف والالكترونيات': 5, // ✅ تصحيح
      'الأدوات الكهربائية': 6, // ✅ تصحيح
      'ايجار العقارات': 7, // ✅ تصحيح
      'الثمار والحبوب': 8, // ✅ تصحيح
      'المواد الغذائية': 9, // ✅ تصحيح
      'المطاعم': 10, // ✅ تصحيح
      'مواد التدفئة': 11, // ✅ تصحيح
      'المكياج و الاكسسوار': 12, // ✅ تصحيح
      'المواشي والحيوانات': 17, // ✅ تصحيح
      'الكتب و القرطاسية': 18, // ✅ تصحيح
      'الأدوات المنزلية': 19, // ✅ تصحيح
      'الملابس والأحذية': 20, // ✅ تصحيح
      'أثاث المنزل': 21, // ✅ تصحيح
      'تجار الجملة': 22, // ✅ تصحيح
      'الموزعين': 23, // ✅ تصحيح
      'أسواق أخرى': 24, // ✅ تصحيح
    };

    return categoryMap[categoryName];
  }

  static Future<Map<String, dynamic>> togglePostLike(int postId) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'المستخدم غير مسجل الدخول'};
      }

      print('📤 تبديل الإعجاب للمنشور ID: $postId');

      // إرسال طلب تبديل الإعجاب
      final uri = Uri.parse('$baseUrl/api/toggleLike?post_id=$postId');
      final response = await http
          .get(
            uri,
            headers: getHeaders(token),
          )
          .timeout(const Duration(seconds: 30));

      final result = _handleResponse(response, 'toggle_post_like');

      // ✅ إضافة طباعة للتحقق من البيانات المُستلمة
      print('📥 استجابة تبديل الإعجاب: ${result}');

      if (result['success'] == true) {
        // ✅ إرجاع البيانات المحدثة من الخادم
        return {
          'success': true,
          'message': result['message'] ?? 'تم تحديث الإعجاب بنجاح',
          'isLiked': result['isLiked'] ?? false, // الحالة الجديدة للإعجاب
          'likesCount': result['likesCount'] ??
              result['likes_count'] ??
              0, // العدد المحدث
          'data': result['data'], // بيانات إضافية إن وجدت
        };
      }

      return result;
    } catch (e) {
      print('❌ خطأ في تحديث الإعجاب: $e');
      return {
        'success': false,
        'message': 'خطأ في تحديث الإعجاب: ${e.toString()}',
      };
    }
  }

  // ======== دالة جديدة لجلب إحصائيات المنشور فقط (للتحديث الدوري) ========
  static Future<Map<String, dynamic>> getPostStats(int postId) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'المستخدم غير مسجل الدخول'};
      }

      print('📊 جلب إحصائيات المنشور ID: $postId');

      // يمكنك استخدام endpoint محدد للإحصائيات أو جلب المنشور كاملاً
      // هنا نستخدم endpoint بسيط يجلب فقط الإحصائيات
      final uri = Uri.parse('$baseUrl/api/posts/$postId/stats');
      final response = await http
          .get(
            uri,
            headers: getHeaders(token),
          )
          .timeout(const Duration(seconds: 15));

      final result = _handleResponse(response, 'get_post_stats');

      if (result['success'] == true) {
        return {
          'success': true,
          'likes_count':
              result['likes_count'] ?? result['data']?['likes_count'] ?? 0,
          'comments_count': result['comments_count'] ??
              result['data']?['comments_count'] ??
              0,
        };
      }

      return result;
    } catch (e) {
      print('❌ خطأ في جلب إحصائيات المنشور: $e');
      return {
        'success': false,
        'message': 'خطأ في جلب الإحصائيات: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> addComment({
    required int postId,
    required String content,
    int? parentCommentId, // معرف التعليق الأصلي للرد عليه
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'المستخدم غير مسجل الدخول'};
      }

      print('📤 إضافة تعليق للمنشور ID: $postId');

      // إعداد البيانات كـ form-data
      final Map<String, String> requestData = {
        'post_id': postId.toString(),
        'content': content,
      };

      // إضافة parent_comment_id فقط إذا تم توفيره (للردود)
      if (parentCommentId != null) {
        requestData['parent_comment_id'] = parentCommentId.toString();
      }

      // إرسال الطلب
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/comments/add'),
            headers: {
              ...getHeaders(token),
            },
            body: requestData,
          )
          .timeout(const Duration(seconds: 30));

      final result = _handleResponse(response, 'add_comment');

      // ✅ إضافة طباعة للتحقق من البيانات
      print('📥 استجابة إضافة التعليق: ${result}');

      if (result['success'] == true) {
        return {
          'success': true,
          'message': result['message'] ?? 'تم إضافة التعليق بنجاح',
          'comment': result['comment'] ?? result['data'], // التعليق الجديد
          'comments_count': result['comments_count'] ??
              result['total_comments'], // العدد المحدث
        };
      }

      return result;
    } catch (e) {
      print('❌ خطأ في إضافة التعليق: $e');
      return {
        'success': false,
        'message': 'خطأ في إضافة التعليق: ${e.toString()}',
      };
    }
  }

  // ======== دالة جلب تعليقات منشور ========
  static Future<Map<String, dynamic>> getComments(int postId) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'المستخدم غير مسجل الدخول'};
      }

      print('📤 جلب التعليقات للمنشور ID: $postId');

      final response = await http
          .get(
            Uri.parse('$baseUrl/api/comments?post_id=$postId'),
            headers: getHeaders(token),
          )
          .timeout(const Duration(seconds: 30));

      final result = _handleResponse(response, 'get_comments');

      // ✅ إضافة طباعة للتحقق من البيانات
      print('📥 استجابة جلب التعليقات: ${result}');

      if (result['success'] == true) {
        // ✅ التأكد من وجود مفتاح التعليقات في الاستجابة
        final comments = result['comments'] ?? result['data'] ?? [];

        return {
          'success': true,
          'message': result['message'] ?? 'تم جلب التعليقات بنجاح',
          'comments': List<Map<String, dynamic>>.from(comments),
          'total_comments': result['total_comments'] ??
              result['comments_count'] ??
              comments.length,
        };
      }

      return result;
    } catch (e) {
      print('❌ خطأ في جلب التعليقات: $e');
      return {
        'success': false,
        'message': 'خطأ في جلب التعليقات: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> toggleCommentLike(int commentId) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'المستخدم غير مسجل الدخول'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/comments/toggle-like'),
        headers: {
          ...getHeaders(token),
        },
        body: {
          'comment_id': commentId.toString(), // ✅ إرسال كـ form-data في body
        },
      ).timeout(const Duration(seconds: 30));

      return _handleResponse(response, 'toggle_comment_like');
    } catch (e) {
      return {
        'success': false,
        'message': 'خطأ في تحديث إعجاب التعليق: ${e.toString()}',
      };
    }
  }

  static Future<String?> _getToken() async {
    // يمكنك هنا استخدام أي طريقة تخزين تستعملها (مثل SharedPreferences)
    // سنفترض مؤقتًا أنه يتم تخزينه في متغير ثابت
    return _userToken;
  }

  static Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    if (token != null && token.isNotEmpty) {
      return {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };
    } else {
      return {
        'Accept': 'application/json',
      };
    }
  }

  // دالة جديدة لجلب المنشورات حسب category_id
  static Future<Map<String, dynamic>> getPostsByCategoryId(
    int categoryId, {
    int page = 1,
  }) async {
    try {
      final token = await getToken();

      print('📤 جلب المنشورات للقسم ID: $categoryId, الصفحة: $page');

      // ✅ استخدام الرابط الجديد مع category_id
      final uri = Uri.parse('$baseUrl/api/categories/$categoryId?page=$page');

      final response = await http
          .get(
            uri,
            headers: getHeaders(token),
          )
          .timeout(const Duration(seconds: 30));

      print('📥 استجابة جلب المنشورات: Status ${response.statusCode}');

      return _handleResponse(response, 'get_posts_by_category_id');
    } catch (e) {
      print('❌ خطأ في جلب المنشورات حسب الـ ID: $e');
      return {
        'success': false,
        'message': 'خطأ في جلب المنشورات: ${e.toString()}',
      };
    }
  }
}
