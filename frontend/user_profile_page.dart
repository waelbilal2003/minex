import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'home_page.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'messages_page.dart';
import 'post_card_widget.dart';

class UserProfilePage extends StatefulWidget {
  final int userId;
  final String? userName;

  const UserProfilePage({Key? key, required this.userId, this.userName})
      : super(key: key);

  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  bool _isLoading = true;
  String _error = '';
  Map<String, dynamic>? _userData;
  List<Map<String, dynamic>> _posts = [];

  // دالة لتحويل اسم القسم إلى العربية
  String _convertCategoryToArabic(String category) {
    Map<String, String> categoryMap = {
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

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // --- ✨ دالة مساعدة لتحويل القيم إلى أرقام بشكل آمن ✨ ---
  int _parseToInt(dynamic value, {int defaultValue = -1}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  // --- ✨✨ بداية الإصلاح الشامل ✨✨ ---
  Future<void> _fetchUserData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final result = await AuthService.getUserProfileAndPosts(widget.userId);

      if (!mounted) return;

      if (result['success'] == true && result['data'] != null) {
        // ---- هذا هو بلوك النجاح ----
        _userData = result['data']['user'];
        List<Map<String, dynamic>> rawPosts =
            List<Map<String, dynamic>>.from(result['data']['posts'] ?? []);

        _posts = rawPosts.map((post) {
          final userForPost = post['user'] ?? _userData!;
          List<String> images = (post['images'] as List<dynamic>?)
                  ?.map((imageUrl) =>
                      imageUrl.toString()) // imageUrl هو النص مباشرة
                  .toList() ??
              [];

          // 2. إصلاح معالجة الفيديو: استخدام المفتاح الصحيح 'video_path'
          // ✅ معالجة الفيديو بشكل مطابق لـ home_page (الفيديو مسار نصي مباشر)
          String? videoUrl = post['video'] is String ? post['video'] : null;
          return {
            'id': _parseToInt(post['id']),
            'user_id': _parseToInt(userForPost['id']),
            'user_name': userForPost['full_name'] ?? 'مستخدم',
            'content': post['content'] ?? '',
            'title': post['title'] ?? '',
            'category': _convertCategoryToArabic(post['category'] ?? ''),
            'price': post['price']?.toString(),
            'location': post['location'],
            'images': images,
            'video_url': videoUrl,
            'likes_count': _parseToInt(post['likes_count'], defaultValue: 0),
            'comments_count':
                _parseToInt(post['comments_count'], defaultValue: 0),
            'created_at': post['created_at'],
            'isLiked': post['is_liked_by_user'] ?? false,
            'gender': userForPost['gender'],
            'user_type': userForPost['user_type'] ?? 'person',
          };
        }).toList();

        // تحديث الواجهة بالبيانات الصحيحة
        setState(() {});
      } else {
        // ---- هذا هو بلوك الفشل (تم نقله إلى هنا) ----
        setState(() {
          _error = result['message'] ?? 'فشل تحميل البيانات';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'حدث خطأ في الاتصال: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  // --- ✨✨ نهاية الإصلاح الشامل ✨✨ ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_userData?['full_name'] ?? widget.userName ?? 'ملف شخصي'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    if (_error.isNotEmpty) {
      return Center(
        child: Text('خطأ: $_error', style: TextStyle(color: Colors.red)),
      );
    }
    if (_userData == null) {
      return Center(child: Text('لم يتم العثور على المستخدم'));
    }

    return RefreshIndicator(
      onRefresh: _fetchUserData,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildProfileHeader()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Text(
                'المنشورات (${_posts.length})',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          if (_posts.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Text(
                  'هذا المستخدم لم يقم بنشر أي شيء بعد.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                return PostCardWidget(
                  post: _posts[index],
                  onDelete: () {
                    setState(() {
                      _posts.removeAt(index);
                    });
                  },
                );
              }, childCount: _posts.length),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    final user = _userData!;
    final joinDate = DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime.parse(user['created_at']));

    // --- ✨ بداية التعديل ---
    final bool isStore = user['user_type'] == 'store';

    String getGenderText(String? genderValue) {
      final g = (genderValue ?? '').toString().toLowerCase();
      if (g == 'ذكر' || g == 'male' || g == 'm') {
        return 'ذكر';
      } else if (g == 'أنثى' || g == 'female' || g == 'f') {
        return 'أنثى';
      }
      return 'غير محدد';
    }

    final gender = getGenderText(user['gender']);
    // --- نهاية التعديل ---

    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          // --- ✨ تعديل: تغيير الأيقونة حسب نوع الحساب ---
          CircleAvatar(
            radius: 40,
            backgroundColor: isStore ? Colors.amber.shade700 : Colors.blue,
            child: Icon(
              isStore ? Icons.storefront : Icons.person,
              size: 45,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 12),
          ElevatedButton.icon(
            icon: Icon(Icons.message_outlined),
            label: Text('مراسلة'),
            onPressed: () async {
              final result = await AuthService.sendMessage(
                widget.userId,
                "👋",
              );
              if (result['success'] == true && result['data'] != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatPage(
                      // ✨✨ هنا الإصلاح ✨✨
                      // نقوم بتحويل النص إلى رقم بشكل آمن قبل التمرير
                      conversationId:
                          _parseToInt(result['data']['conversation_id']),
                      otherUserId: widget.userId,
                      otherUserName: user['full_name'],
                      otherUserGender: user['gender'],
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
            ),
          ),
          SizedBox(height: 8),
          Divider(),
          // --- ✨ تعديل: إضافة شارة "متجر" بجانب الاسم ---
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                user['full_name'],
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              if (isStore) ...[
                SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle,
                          color: Colors.amber.shade800, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'متجر',
                        style: TextStyle(
                          color: Colors.amber.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 8),
          Divider(),
          SizedBox(height: 8),
          // --- ✨ تعديل: إخفاء الجنس إذا كان الحساب متجراً ---
          if (!isStore) _buildInfoRow(Icons.person_outline, 'الجنس', gender),
          if (user['email'] != null)
            _buildInfoRow(Icons.email_outlined, 'البريد', user['email']),
          if (user['phone'] != null)
            _buildInfoRow(Icons.phone_outlined, 'الهاتف', user['phone']),
          _buildInfoRow(
            Icons.calendar_today_outlined,
            'تاريخ الانضمام',
            joinDate,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 20),
          SizedBox(width: 16),
          Text('$label:', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[700], fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  // نسخة من بطاقة المنشور مطابقة لما في صفحة البحث
  Widget _buildImagesWidget(List<dynamic> images) {
    if (images.isEmpty) return SizedBox.shrink();
    return Container(
      height: 250,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: _getImageUrl(images[0]),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildVideoPlayer(String videoUrl) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: VideoPlayerWidget(videoUrl: _getImageUrl(videoUrl)),
      ),
    );
  }

  // --- ✨✨ بداية الإصلاح الشامل: استخدام Uri.resolve لبناء الروابط ✨✨ ---
  String _getFullUrl(String path) {
    // إذا كان المسار يحتوي بالفعل على "http"، فهذا يعني أنه رابط كامل
    if (path.startsWith('http')) {
      // فقط قم بإصلاح أي شرطات مائلة عكسية قد تأتي من الـ JSON
      return path.replaceAll(r'\/', '/');
    }

    // الطريقة الصحيحة والآمنة لدمج الروابط.
    // هي تعالج تلقائيًا ما إذا كان `baseUrl` ينتهي بـ / أو أن `path` يبدأ بـ /
    return Uri.parse(AuthService.baseUrl).resolve(path).toString();
  }
  // --- ✨✨ نهاية الإصلاح الشامل ✨✨ ---

  // ✨ --- بداية الإضافة --- ✨
  String _convertCategoryToLocalName(String? categoryName) {
    // هذه الدالة تعتمد على أن الخادم يرسل الاسم المترجم بالفعل
    // يمكنك تعديلها في المستقبل إذا احتجت للترجمة داخل التطبيق
    return categoryName ?? 'غير مصنف';
  }

  // ✨ --- نهاية الإضافة --- ✨
  String _getImageUrl(String imagePath) {
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }
    String baseUrl = AuthService.baseUrl;
    return '$baseUrl/$imagePath';
  }
}
