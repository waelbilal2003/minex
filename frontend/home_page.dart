import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'profile_page.dart';
import 'messages_page.dart';
import 'notifications_page.dart';
import 'admin_page.dart';
import 'categories_page_new.dart';
import 'create_post_page.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import 'vip_ad_details_page.dart';
import 'search_page.dart';
import 'post_card_widget.dart';
import 'login_page.dart';
import 'vip_ads_widget.dart'; // <-- ✨ أضف هذا الاستيراد
import 'post_helpers.dart'; // <-- ✨ استيراد الدوال المساعدة المركزية

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  bool _isDarkMode = false;
  PageController _vipAdsController = PageController();
  int _currentVipAdIndex = 0;
  bool _isLoading = true;
  String _userGender = 'ذكر';
  List<Map<String, dynamic>> _vipAds = [];
  List<Map<String, dynamic>> _postsFromServer = [];
  bool _isPostsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchVipAds();
    _startVipAdsAutoScroll();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchPosts(); // تحميل البيانات بعد بناء الواجهة
    });
  }

  Future<void> _fetchVipAds() async {
    try {
      print('📤 جلب إعلانات VIP...');

      final result = await AuthService.getVipAdsForDisplay();

      print('📥 نتيجة جلب إعلانات VIP: $result');

      if (mounted) {
        if (result['success'] == true) {
          final adsData = result['data'] ?? [];

          setState(() {
            _vipAds = List<Map<String, dynamic>>.from(adsData);
          });

          print('✅ تم تحميل ${_vipAds.length} إعلان VIP بنجاح');

          // ✅ إعادة تشغيل التمرير التلقائي إذا كانت هناك إعلانات
          if (_vipAds.isNotEmpty) {
            _startVipAdsAutoScroll();
          }
        } else {
          print('❌ فشل جلب إعلانات VIP: ${result['message']}');
          setState(() {
            _vipAds = [];
          });
        }
      }
    } catch (e) {
      print('❌ خطأ في جلب إعلانات VIP: $e');
      if (mounted) {
        setState(() {
          _vipAds = [];
        });
      }
    }
  }

  void _loadUserData() async {
    try {
      await AuthService.loadUserData();
      if (mounted) {
        setState(() {
          _userGender = AuthService.currentUser?['gender'] ?? 'ذكر';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      print('خطأ في تحميل بيانات المستخدم: $e');
    }
  }

  Color get _primaryColor => !AuthService.isLoggedIn
      ? Colors.blue
      : (_userGender == 'ذكر' ? Colors.blue : Colors.pink);

  void _startVipAdsAutoScroll() {
    Future.delayed(const Duration(seconds: 3), () {
      if (_vipAdsController.hasClients && mounted && _vipAds.isNotEmpty) {
        _currentVipAdIndex = (_currentVipAdIndex + 1) % _vipAds.length;
        _vipAdsController.animateToPage(
          _currentVipAdIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        _startVipAdsAutoScroll();
      }
    });
  }

  void _showLoginRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('مطلوب تسجيل الدخول'),
        content: const Text('يجب عليك تسجيل الدخول أولاً لاستخدام هذه الميزة.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              // مسح كل الصفحات السابقة والانتقال إلى صفحة تسجيل الدخول
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (Route<dynamic> route) => false,
              );
            },
            child: const Text('تسجيل الدخول'),
          ),
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    final protectedIndices = {2, 4, 5};

    if (!AuthService.isLoggedIn && protectedIndices.contains(index)) {
      _showLoginRequiredDialog(context);
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  void _toggleDarkMode() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  // ✅ تم نقل هذه الدالة إلى PostHelpers.parseToInt

  Future<void> _fetchPosts() async {
    if (!mounted) return;
    setState(() => _isPostsLoading = true);

    try {
      final result = await AuthService.getPosts();

      if (!mounted) return;

      if (result['success'] == true && result['data'] != null) {
        final postsData = List<Map<String, dynamic>>.from(result['data']);

        setState(() {
          // ✅ استخدام الدالة المركزية من PostHelpers
          _postsFromServer = PostHelpers.processPostsList(postsData);
          _isPostsLoading = false;
        });
      } else {
        if (mounted) {
          setState(() => _isPostsLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'فشل تحميل المنشورات')),
          );
        }
      }
    } catch (e) {
      print("Error in _fetchPosts: $e");
      if (mounted) {
        setState(() => _isPostsLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء الاتصال بالخادم: $e')),
        );
      }
    }
  }

  // ✅ تم نقل هذه الدالة إلى PostHelpers.convertCategoryToArabic

  // ✅ استخدام الدالة المركزية من PostHelpers
  String _getImageUrl(String imagePath) {
    return PostHelpers.getFullImageUrl(imagePath, AuthService.baseUrl);
  }

  // ✅ تحسين عرض الصور مع تخطيط ذكي حسب عدد الصور
  Widget _buildImagesWidget(List<dynamic> images) {
    if (images.isEmpty) return SizedBox.shrink();

    return Container(
      margin: EdgeInsets.only(top: 8),
      child: _buildImageLayout(images),
    );
  }

  Widget _buildImageLayout(List<dynamic> images) {
    switch (images.length) {
      case 1:
        return _buildSingleImage(images[0]);
      case 2:
        return _buildTwoImages(images);
      case 3:
        return _buildThreeImages(images);
      case 4:
        return _buildFourImages(images);
      default:
        return _buildMultipleImages(images);
    }
  }

  Widget _buildSingleImage(String imageUrl) {
    return Container(
      height: 300,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.grey[300],
            child: Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[300],
            child: Icon(Icons.error, color: Colors.red),
          ),
        ),
      ),
    );
  }

  Widget _buildTwoImages(List<dynamic> images) {
    return Container(
      height: 200,
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                bottomLeft: Radius.circular(8),
              ),
              child: CachedNetworkImage(
                imageUrl: images[0],
                fit: BoxFit.cover,
                height: double.infinity,
                placeholder: (context, url) => Container(
                  color: Colors.grey[300],
                  child: Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[300],
                  child: Icon(Icons.error, color: Colors.red),
                ),
              ),
            ),
          ),
          SizedBox(width: 2),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
              child: CachedNetworkImage(
                imageUrl: images[1],
                fit: BoxFit.cover,
                height: double.infinity,
                placeholder: (context, url) => Container(
                  color: Colors.grey[300],
                  child: Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[300],
                  child: Icon(Icons.error, color: Colors.red),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThreeImages(List<dynamic> images) {
    return Container(
      height: 200,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                bottomLeft: Radius.circular(8),
              ),
              child: CachedNetworkImage(
                imageUrl: images[0],
                fit: BoxFit.cover,
                height: double.infinity,
                placeholder: (context, url) => Container(
                  color: Colors.grey[300],
                  child: Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[300],
                  child: Icon(Icons.error, color: Colors.red),
                ),
              ),
            ),
          ),
          SizedBox(width: 2),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(8),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: images[1],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[300],
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[300],
                        child: Icon(Icons.error, color: Colors.red),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 2),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      bottomRight: Radius.circular(8),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: images[2],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[300],
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[300],
                        child: Icon(Icons.error, color: Colors.red),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFourImages(List<dynamic> images) {
    return Container(
      height: 200,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(8),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: images[0],
                      fit: BoxFit.cover,
                      height: double.infinity,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[300],
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[300],
                        child: Icon(Icons.error, color: Colors.red),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 2),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(8),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: images[1],
                      fit: BoxFit.cover,
                      height: double.infinity,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[300],
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[300],
                        child: Icon(Icons.error, color: Colors.red),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 2),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: images[2],
                      fit: BoxFit.cover,
                      height: double.infinity,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[300],
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[300],
                        child: Icon(Icons.error, color: Colors.red),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 2),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      bottomRight: Radius.circular(8),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: images[3],
                      fit: BoxFit.cover,
                      height: double.infinity,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[300],
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[300],
                        child: Icon(Icons.error, color: Colors.red),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultipleImages(List<dynamic> images) {
    return Container(
      height: 200,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(8),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: images[0],
                      fit: BoxFit.cover,
                      height: double.infinity,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[300],
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[300],
                        child: Icon(Icons.error, color: Colors.red),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 2),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(8),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: images[1],
                      fit: BoxFit.cover,
                      height: double.infinity,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[300],
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[300],
                        child: Icon(Icons.error, color: Colors.red),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 2),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: images[2],
                      fit: BoxFit.cover,
                      height: double.infinity,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[300],
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[300],
                        child: Icon(Icons.error, color: Colors.red),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 2),
                Expanded(
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.only(
                          bottomRight: Radius.circular(8),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: images[3],
                          fit: BoxFit.cover,
                          height: double.infinity,
                          width: double.infinity,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[300],
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[300],
                            child: Icon(Icons.error, color: Colors.red),
                          ),
                        ),
                      ),
                      if (images.length > 4)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.only(
                                bottomRight: Radius.circular(8),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '+${images.length - 4}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ مشغل فيديو محسن مع عناصر تحكم
  // ✅ مشغل فيديو محسن يشبه فيسبوك
  Widget _buildVideoPlayer(String videoUrl) {
    return Container(
      margin: EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: VideoPlayerWidget(videoUrl: videoUrl),
      ),
    );
  }

  Widget _buildHomeTab() {
    return RefreshIndicator(
      onRefresh: _fetchPosts,
      child: CustomScrollView(
        slivers: [
          // SliverToBoxAdapter يسمح لنا بوضع أي ويدجت عادية داخل CustomScrollView
          SliverToBoxAdapter(
            child: Column(
              children: [
                // 1. رسالة الترحيب
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  color: _primaryColor.withOpacity(0.1),
                  child: Text(
                    'أهلاً وسهلاً بكم في السوق الشامل الأول في سوريا',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _primaryColor.withOpacity(0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                // --- ✨✨ بداية التعديل: استدعاء الويدجت الموروث ✨✨ ---
                // تم استبدال الكود الطويل بهذا السطر البسيط
                VipAdsWidget(primaryColor: _primaryColor),
                // --- ✨✨ نهاية التعديل ✨✨ ---
                if (AuthService.isLoggedIn)
                  // 3. شريط "بم تفكر..."
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: InkWell(
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => CreatePostPage()),
                        );
                        if (result == true) {
                          // يتم تحديث المنشورات فقط عند النجاح
                          _fetchPosts();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[800]!
                              : Colors.grey[200]!,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.grey[600]!
                                  : Colors.grey[300]!,
                              width: 1),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundImage: NetworkImage(
                                  AuthService.currentUser?['user_avatar'] ??
                                      'https://via.placeholder.com/50'),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Text('بم تفكر...',
                                    style: TextStyle(
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.grey[400]!
                                            : Colors.grey[600]!,
                                        fontSize: 16))),
                            Icon(Icons.image, color: _primaryColor),
                            const SizedBox(width: 8),
                            Icon(Icons.video_call, color: _primaryColor),
                          ],
                        ),
                      ),
                    ),
                  ),

                // 4. عنوان "المنشورات العامة"
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'المنشورات العامة',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _isDarkMode ? Colors.white : Colors.black),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- 5. قائمة المنشورات الفعلية (هذا هو التعديل الأساسي) ---
          // نستخدم SliverList لعرض المنشورات بكفاءة وحل مشكلة النقر
          _isPostsLoading
              ? const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()))
              : _postsFromServer.isEmpty
                  ? SliverFillRemaining(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'لا توجد منشورات لعرضها حالياً. كن أول من ينشر!',
                            style: const TextStyle(fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return PostCardWidget(
                            key: ValueKey(_postsFromServer[index]['id']),
                            post: _postsFromServer[index],
                            onDelete: () {
                              setState(() {
                                _postsFromServer.removeAt(index);
                              });
                            },
                          );
                        },
                        childCount: _postsFromServer.length,
                      ),
                    ),
        ],
      ),
    );
  }

  // ✅ تحديث دالة _buildVipAdCard لمعالجة البيانات بشكل أفضل
  Widget _buildVipAdCard(Map<String, dynamic> ad) {
    // ✅ معالجة آمنة للصور والفيديوهات
    final String? imageUrl =
        ad['cover_image_url'] ?? ad['image'] ?? ad['cover_image'];
    final String? videoUrl = ad['video_url'] ?? ad['video'] ?? ad['video_path'];
    final String? title = ad['title']?.toString();
    final String? description = ad['description']?.toString();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _primaryColor, width: 2),
      ),
      child: InkWell(
        onTap: () {
          // ✅ التنقل لصفحة تفاصيل الإعلان
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VipAdDetailsPage(adData: ad),
            ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            children: [
              // ✅ عرض الصورة أو الفيديو
              Container(
                width: double.infinity,
                height: double.infinity,
                child: _buildVipAdMedia(imageUrl, videoUrl),
              ),

              // ✅ عرض العنوان والوصف (مع التحقق من null)
              if ((title != null && title.isNotEmpty) ||
                  (description != null && description.isNotEmpty))
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (title != null && title.isNotEmpty)
                          Text(
                            title, // الآن هي آمنة للاستخدام
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (description != null && description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            description, // الآن هي آمنة للاستخدام
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ دالة مساعدة لعرض وسائط الإعلان
  // ✅ دالة مساعدة لعرض وسائط الإعلان (مع التصحيحات)
  Widget _buildVipAdMedia(String? imageUrl, String? videoUrl) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      // --- ✅ بداية الإصلاح ---
      // تم استبدال 'baseUrl' غير المعرف بـ 'AuthService.baseUrl'
      final fullImageUrl = imageUrl.startsWith('http')
          ? imageUrl
          : '${AuthService.baseUrl}/$imageUrl';
      // --- نهاية الإصلاح ---

      return CachedNetworkImage(
        imageUrl: fullImageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        placeholder: (c, u) => Container(
          color: Colors.grey[200],
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (c, u, e) => Container(
          color: Colors.grey[200],
          child: const Center(child: Icon(Icons.broken_image, size: 48)),
        ),
      );
    } else if (videoUrl != null && videoUrl.isNotEmpty) {
      return Stack(
        alignment: Alignment.center,
        children: [
          Container(
            color: Colors.black12,
            child: const Center(
                child: Icon(Icons.videocam, size: 48, color: Colors.grey)),
          ),
          const CircleAvatar(
            backgroundColor: Colors.black45,
            child: Icon(Icons.play_arrow, size: 30, color: Colors.white),
          ),
        ],
      );
    } else {
      return Container(
        color: Colors.grey[200],
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text('لا توجد صورة', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
  }

  Widget _buildCategoriesTab() => CategoriesPage();
  Widget _buildSearchTab() => SearchPage();

  Widget _buildFavoritesTab() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite, size: 80, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'المفضلة',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'المنتجات المفضلة لديك',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
  Widget _buildProfileTab() => ProfilePage();
  Widget _buildMessagesTab() => MessagesPage();

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Theme(
        data: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
        child: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('جاري تحميل البيانات...'),
              ],
            ),
          ),
        ),
      );
    }
    if (AuthService.isAdmin) {
      return AdminPage();
    }
    final List<Widget> _pages = [
      _buildHomeTab(),
      _buildCategoriesTab(),
      _buildMessagesTab(),
      _buildSearchTab(),
      _buildFavoritesTab(),
      _buildProfileTab(),
    ];
    return Theme(
      data: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              if (AuthService.isLoggedIn)
                IconButton(
                  icon: const Icon(Icons.account_circle), // أيقونة الملف الشخصي
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ProfilePage()),
                    );
                  },
                ),
              IconButton(
                icon: const Icon(Icons.search), // أيقونة البحث
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SearchPage()),
                  );
                },
              ),
              Expanded(
                child: Text(
                  'MINEX',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
                onPressed: _toggleDarkMode,
              ),
              IconButton(
                icon: Icon(Icons.notifications),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NotificationsPage(),
                    ),
                  );
                },
              ),
            ],
          ),
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
        ),
        body: _pages[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'الرئيسية'),
            BottomNavigationBarItem(
              icon: Icon(Icons.category),
              label: 'الفئات',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.message),
              label: 'الرسائل',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: 'البحث'),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite),
              label: 'المفضلة',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'الملف الشخصي',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: _primaryColor,
          unselectedItemColor: Colors.grey,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
        ),
      ),
    );
  }
}

// ✅ مشغل فيديو مخصص مع عناصر تحكم
// ✅ كلاس VideoPlayerWidget المعدل
class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerWidget({Key? key, required this.videoUrl}) : super(key: key);

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _showControls = true;
  Timer? _controlsTimer;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() async {
    try {
      _controller = VideoPlayerController.network(widget.videoUrl)
        ..addListener(() {
          if (mounted) setState(() {});
        });

      await _controller!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }

      // تشغيل الفيديو تلقائياً
      _controller!.play();
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  void _togglePlayPause() {
    if (_controller!.value.isPlaying) {
      _controller!.pause();
    } else {
      _controller!.play();
    }
    _showControlsTemporarily();
  }

  void _showControlsTemporarily() {
    setState(() {
      _showControls = true;
    });

    _controlsTimer?.cancel();
    _controlsTimer = Timer(Duration(seconds: 3), () {
      if (mounted && _controller!.value.isPlaying) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _seekForward() {
    final newPosition = _controller!.value.position + Duration(seconds: 10);
    if (newPosition < _controller!.value.duration) {
      _controller!.seekTo(newPosition);
    }
  }

  void _seekBackward() {
    final newPosition = _controller!.value.position - Duration(seconds: 10);
    if (newPosition > Duration.zero) {
      _controller!.seekTo(newPosition);
    }
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, color: Colors.white, size: 40),
              SizedBox(height: 8),
              Text(
                'خطأ في تحميل الفيديو',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return Container(
        color: Colors.black,
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return GestureDetector(
      onTap: _togglePlayPause,
      onDoubleTap: _seekForward,
      onLongPress: _seekBackward,
      child: Stack(
        children: [
          // الفيديو
          AspectRatio(
            aspectRatio: _controller!.value.aspectRatio,
            child: VideoPlayer(_controller!),
          ),

          // عناصر التحكم
          if (_showControls)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // زر التشغيل/الإيقاف المركزي
                    Icon(
                      _controller!.value.isPlaying
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_filled,
                      color: Colors.white,
                      size: 50,
                    ),

                    SizedBox(height: 20),

                    // أزرار التحكم الإضافية
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // الرجوع 10 ثواني
                        IconButton(
                          icon: Icon(
                            Icons.replay_10,
                            color: Colors.white,
                            size: 30,
                          ),
                          onPressed: _seekBackward,
                        ),

                        // التقدم 10 ثواني
                        IconButton(
                          icon: Icon(
                            Icons.forward_10,
                            color: Colors.white,
                            size: 30,
                          ),
                          onPressed: _seekForward,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // شريط التقدم في الأسفل
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 4,
              color: Colors.black.withOpacity(0.5),
              child: VideoProgressIndicator(
                _controller!,
                allowScrubbing: true,
                colors: VideoProgressColors(
                  playedColor: Colors.red,
                  bufferedColor: Colors.grey[600]!,
                  backgroundColor: Colors.grey[800]!,
                ),
              ),
            ),
          ),

          // الوقت المنقضي والكلي
          if (_showControls)
            Positioned(
              bottom: 8,
              left: 8,
              child: Text(
                '${_formatDuration(_controller!.value.position)} / ${_formatDuration(_controller!.value.duration)}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          // زر كتم الصوت
          if (_showControls)
            Positioned(
              bottom: 8,
              right: 8,
              child: IconButton(
                icon: Icon(
                  _controller!.value.volume == 0
                      ? Icons.volume_off
                      : Icons.volume_up,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () {
                  _controller!.setVolume(
                    _controller!.value.volume == 0 ? 1 : 0,
                  );
                },
              ),
            ),

          // مؤشر التحميل
          if (_controller!.value.isBuffering)
            Positioned.fill(
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
