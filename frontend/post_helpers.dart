/// ملف مساعد مركزي يحتوي على دوال مشتركة لمعالجة المنشورات والصور
/// يستخدم في جميع الصفحات: home_page, user_profile_page, search_page, posts_page

class PostHelpers {
  /// دالة لتحويل القيم إلى أرقام بشكل آمن
  static int parseToInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  /// دالة لتحويل اسم القسم من الإنجليزية إلى العربية
  static String convertCategoryToArabic(String category) {
    const Map<String, String> categoryMap = {
      'job': 'التوظيف',
      'tenders': 'المناقصات',
      'suppliers': 'الموردين',
      'general_offers': 'العروض العامة',
      'cars': 'السيارات',
      'motorcycles': 'الدراجات النارية',
      'real_estate': 'تجارة العقارات',
      'weapons': 'المستلزمات العسكرية',
      'electronics': 'الهواتف والالكترونيات',
      'electrical': 'الأدوات الكهربائية',
      'house_rent': 'ايجار العقارات',
      'agriculture': 'الثمار والحبوب',
      'food': 'المواد الغذائية',
      'restaurants': 'المطاعم',
      'heating': 'مواد التدفئة',
      'accessories': 'المكياج والاكسسوار',
      'animals': 'المواشي والحيوانات',
      'books': 'الكتب والقرطاسية',
      'home_health': 'الأدوات المنزلية',
      'clothing_shoes': 'الملابس والأحذية',
      'furniture': 'أثاث المنزل',
      'wholesalers': 'تجار الجملة',
      'distributors': 'الموزعين',
      'others': 'أسواق أخرى',
      'suggestions': 'اقتراحات وشكاوي',
      'ad_contact': 'تواصل للإعلانات',
    };

    return categoryMap[category] ?? category;
  }

  /// دالة موحدة لمعالجة بيانات المنشور من API
  /// تحول البيانات الخام إلى صيغة موحدة يمكن استخدامها في جميع الصفحات
  static Map<String, dynamic> processPostData(
    Map<String, dynamic> post, {
    Map<String, dynamic>? fallbackUserData,
  }) {
    // الحصول على بيانات المستخدم من المنشور أو من البيانات الاحتياطية
    final userForPost =
        post['user'] as Map<String, dynamic>? ?? fallbackUserData ?? {};

    // ✅ معالجة الصور: التعامل مع قائمة النصوص مباشرة
    List<String> images = (post['images'] as List<dynamic>?)
            ?.map((imageUrl) => imageUrl.toString())
            .toList() ??
        [];

    // ✅ معالجة الفيديو: استخدام المفتاح الصحيح
    String? videoUrl;
    if (post['video'] != null) {
      if (post['video'] is String) {
        // إذا كان الفيديو نص مباشر
        videoUrl = post['video'];
      } else if (post['video'] is Map && post['video']['video_path'] != null) {
        // إذا كان الفيديو كائن يحتوي على video_path
        videoUrl = post['video']['video_path'];
      }
    }

    // معلومات المستخدم
    String userName = userForPost['full_name'] ?? 'مستخدم';
    int userId = parseToInt(userForPost['id'], defaultValue: -1);

    // إنشاء صورة رمزية افتراضية
    String userAvatar =
        'https://via.placeholder.com/50x50/cccccc/ffffff?text=${userName.isNotEmpty ? userName.substring(0, 1) : 'U'}';

    return {
      'id': parseToInt(post['id']),
      'user_id': userId,
      'user_name': userName,
      'user_avatar': userAvatar,
      'content': post['content'] ?? '',
      'title': post['title'] ?? '',
      'category': convertCategoryToArabic(post['category'] ?? ''),
      'price': post['price']?.toString(),
      'location': post['location'],
      'images': images,
      'video_url': videoUrl,
      'likes_count': parseToInt(post['likes_count'], defaultValue: 0),
      'comments_count': parseToInt(post['comments_count'], defaultValue: 0),
      'created_at': post['created_at'],
      'isLiked': post['is_liked_by_user'] ?? false,
      'gender': userForPost['gender'],
      'user_type': userForPost['user_type'] ?? 'person',
    };
  }

  /// دالة لمعالجة قائمة من المنشورات
  static List<Map<String, dynamic>> processPostsList(
    List<dynamic> rawPosts, {
    Map<String, dynamic>? fallbackUserData,
  }) {
    return rawPosts.map((post) {
      return processPostData(
        post as Map<String, dynamic>,
        fallbackUserData: fallbackUserData,
      );
    }).toList();
  }

  /// دالة لتحويل مسار الصورة إلى رابط كامل
  static String getFullImageUrl(String imagePath, String baseUrl) {
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }

    // تنظيف baseUrl من /api.php أو /new_api.php إذا كان موجودًا
    String cleanBaseUrl = baseUrl;
    if (cleanBaseUrl.contains('api.php')) {
      cleanBaseUrl = cleanBaseUrl.substring(0, cleanBaseUrl.lastIndexOf('/'));
    }

    // إزالة الشرطة المائلة في البداية من imagePath إذا كانت موجودة
    String cleanImagePath =
        imagePath.startsWith('/') ? imagePath.substring(1) : imagePath;

    return '$cleanBaseUrl/$cleanImagePath';
  }

  /// دالة آمنة لبناء الروابط باستخدام Uri.resolve
  static String getFullUrl(String path, String baseUrl) {
    // إذا كان المسار يحتوي بالفعل على "http"، فهذا يعني أنه رابط كامل
    if (path.startsWith('http')) {
      // فقط قم بإصلاح أي شرطات مائلة عكسية قد تأتي من الـ JSON
      return path.replaceAll(r'\/', '/');
    }

    // الطريقة الصحيحة والآمنة لدمج الروابط
    return Uri.parse(baseUrl).resolve(path).toString();
  }

  /// دالة موحدة لمعالجة بيانات المستخدم من API
  static Map<String, dynamic> processUserData(Map<String, dynamic> user) {
    final String fullName = user['full_name'] ?? 'مستخدم';
    final String genderRaw = (user['gender'] ?? '').toString().toLowerCase();
    final String userType = user['user_type'] ?? 'person';

    String getGenderText() {
      if (genderRaw == 'ذكر' || genderRaw == 'male' || genderRaw == 'm')
        return 'ذكر';
      if (genderRaw == 'أنثى' || genderRaw == 'female' || genderRaw == 'f')
        return 'أنثى';
      return 'غير محدد';
    }

    bool isStore = userType == 'store';

    return {
      'id': parseToInt(user['id']),
      'full_name': fullName,
      'display_name': fullName,
      'gender': getGenderText(),
      'is_store': isStore,
      'user_type': userType,
      'email': user['email'],
      'phone': user['phone'],
      'created_at': user['created_at'],
      'avatar_initial': fullName.isNotEmpty ? fullName.substring(0, 1) : 'U',
    };
  }
}
