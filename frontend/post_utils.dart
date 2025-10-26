// post_utils.dart
class PostUtils {
  static List<Map<String, dynamic>> standardizePostsResponse(dynamic response) {
    if (response == null) return [];

    List<Map<String, dynamic>> posts = [];

    try {
      // الحالة 1: response.data.posts
      if (response is Map &&
          response['data'] is Map &&
          response['data']['posts'] is List) {
        posts = List<Map<String, dynamic>>.from(response['data']['posts']);
      }
      // الحالة 2: response.data (قائمة مباشرة)
      else if (response is Map && response['data'] is List) {
        posts = List<Map<String, dynamic>>.from(response['data']);
      }
      // الحالة 3: response نفسها قائمة (نادرة لكن ممكنة)
      else if (response is List) {
        posts = List<Map<String, dynamic>>.from(response);
      }
      // الحالة 4: response.data.posts من نتائج البحث (مثل response.data.posts موجود)
      else if (response is Map &&
          response['data'] is Map &&
          response['data']['posts'] is List) {
        posts = List<Map<String, dynamic>>.from(response['data']['posts']);
      }

      return posts.map((p) => _standardizeSinglePost(p)).toList();
    } catch (e) {
      print('❌ خطأ في standardizePostsResponse: $e');
      return [];
    }
  }

  static Map<String, dynamic> _standardizeSinglePost(
      Map<String, dynamic> rawPost) {
    final userMap = rawPost['user'] ?? {};

    String userName = rawPost['user_name'] ??
        userMap['full_name'] ??
        userMap['name'] ??
        'مستخدم';

    String userType = userMap['user_type'] ?? 'person';

    String gender = (userMap['gender'] ?? rawPost['gender'] ?? 'ذكر')
        .toString()
        .toLowerCase();

    // معالجة الصور: تدعم String و Map
    List<String> imageUrls = [];
    final imagesData = rawPost['images'] ?? [];
    if (imagesData is List) {
      for (var img in imagesData) {
        if (img is String) {
          imageUrls.add(img);
        } else if (img is Map) {
          String? path = img['image_path'] ?? img['url'] ?? img['image'];
          if (path != null) imageUrls.add(path);
        }
      }
    }

    bool isLiked = rawPost['isLiked'] ?? rawPost['is_liked_by_user'] ?? false;

    // الفيديو
    String videoUrl = rawPost['video_url'] ?? rawPost['video'] ?? '';

    return {
      ...rawPost,
      'id': rawPost['id'] ?? 0,
      'user_id': rawPost['user_id'] ?? userMap['id'] ?? 0,
      'user_name': userName,
      'user_type': userType,
      'gender': gender,
      'images': imageUrls,
      'isLiked': isLiked,
      'likes_count': rawPost['likes_count'] ?? 0,
      'comments_count': rawPost['comments_count'] ?? 0,
      'content': rawPost['content'] ?? rawPost['title'] ?? '',
      'price': rawPost['price'],
      'location': rawPost['location'],
      'category': rawPost['category'],
      'created_at': rawPost['created_at'],
      'video_url': videoUrl,
    };
  }

  static String getFullImageUrl(String path, String baseUrl) {
    if (path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    String cleanBase = baseUrl.replaceAll(RegExp(r'\/$'), '');
    String cleanPath = path.startsWith('/') ? path : '/$path';
    return '$cleanBase$cleanPath';
  }
}
