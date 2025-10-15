import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'login_page.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:photo_view/photo_view.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({Key? key}) : super(key: key);

  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> with TickerProviderStateMixin {
  bool _isLoading = true;
  Map<String, dynamic> _statistics = {};

  // القوائم الأصلية
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _posts = [];
  List<Map<String, dynamic>> _vipAds = [];
  List<Map<String, dynamic>> _reportedPosts = [];
  // قوائم للفلترة
  List<Map<String, dynamic>> _filteredUsers = [];
  List<Map<String, dynamic>> _filteredPosts = [];

  final PageController _vipAdsController = PageController();
  int _currentVipAdIndex = 0;
  Timer? _vipAdsTimer;

  // متحكمات البحث
  final TextEditingController _userSearchController = TextEditingController();
  final TextEditingController _postSearchController = TextEditingController();

  TabController? _tabController;

  // Controllers for VIP Ad creation
  final TextEditingController _vipTitleController = TextEditingController();
  final TextEditingController _vipDescController = TextEditingController();

  // Controllers for notification sending
  final TextEditingController _notificationTitleController =
      TextEditingController();
  final TextEditingController _notificationMessageController =
      TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  final TextEditingController _vipPriceController = TextEditingController();
  final TextEditingController _vipLocationController = TextEditingController();
  final TextEditingController _vipPhoneController = TextEditingController();
  // VIP Ad variables
  File? _selectedCoverImage;
  List<File> _selectedMediaFiles = [];
  final ImagePicker _imagePicker = ImagePicker();
  bool _isUploadingMedia = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _checkAdminPermissions();

    // ربط متحكمات البحث بوظائف الفلترة
    _userSearchController.addListener(() {
      _filterUsers(_userSearchController.text);
    });
    _postSearchController.addListener(() {
      _filterPosts(_postSearchController.text);
    });
  }

  // التحقق من صلاحيات الإدارة
  Future<void> _checkAdminPermissions() async {
    if (!AuthService.checkAdminPermissions()) {
      _showErrorDialog('ليس لديك صلاحيات إدارية للوصول إلى هذه الصفحة');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
      return;
    }

    await _loadAllData();
    _startVipAdsAutoScroll();
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('خطأ'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('موافق'),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Enhanced Media Selection Functions
  Future<void> _selectCoverImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        await _cropCoverImage(File(pickedFile.path));
      }
    } catch (e) {
      _showErrorSnackBar('خطأ في اختيار الصورة: $e');
    }
  }

  Future<void> _cropCoverImage(File imageFile) async {
    try {
      // بدلاً من استخدام ImageCropper، نعرض الصورة للتحقق فقط
      await showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'معاينة صورة الغلاف',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: PhotoView(
                      imageProvider: FileImage(imageFile),
                      minScale: PhotoViewComputedScale.contained,
                      maxScale: PhotoViewComputedScale.covered * 2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _showErrorSnackBar('تم إلغاء الاختيار');
                        },
                        child: const Text('إلغاء'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedCoverImage = imageFile;
                          });
                          Navigator.pop(context);
                          _showSuccessSnackBar('تم اختيار صورة الغلاف');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: const Text('موافقة'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('خطأ في معاينة الصورة: $e');
    }
  }

  Future<void> _selectMediaFiles() async {
    try {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('اختر نوع الوسائط'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text('صور'),
                onTap: () async {
                  Navigator.pop(context);
                  await _selectImages();
                },
              ),
              ListTile(
                leading: const Icon(Icons.video_library),
                title: const Text('فيديو'),
                onTap: () async {
                  Navigator.pop(context);
                  await _selectVideo();
                },
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      _showErrorSnackBar('خطأ في اختيار الوسائط: $e');
    }
  }

  Future<void> _selectImages() async {
    try {
      final List<XFile> pickedFiles = await _imagePicker.pickMultiImage(
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFiles.isNotEmpty) {
        for (XFile file in pickedFiles) {
          if (_selectedMediaFiles.length < 10) {
            _selectedMediaFiles.add(File(file.path));
          }
        }
        setState(() {});
        _showSuccessSnackBar('تم إضافة ${pickedFiles.length} صورة');
      }
    } catch (e) {
      _showErrorSnackBar('خطأ في اختيار الصور: $e');
    }
  }

  Future<void> _selectVideo() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
      );

      if (pickedFile != null) {
        // Check video size (max 50MB)
        final File videoFile = File(pickedFile.path);

        if (_selectedMediaFiles.length < 10) {
          _selectedMediaFiles.add(videoFile);
          setState(() {});
          _showSuccessSnackBar('تم إضافة الفيديو');
        } else {
          _showErrorSnackBar('لا يمكن إضافة أكثر من 10 وسائط');
        }
      }
    } catch (e) {
      _showErrorSnackBar('خطأ في اختيار الفيديو: $e');
    }
  }

  void _removeMediaFile(int index) {
    setState(() {
      _selectedMediaFiles.removeAt(index);
    });
  }

  bool _isVideoFile(File file) {
    String extension = file.path.split('.').last.toLowerCase();
    List<String> videoExtensions = [
      'mp4',
      'mov',
      'avi',
      'mkv',
      '3gp',
      'webm',
      'm4v'
    ];
    return videoExtensions.contains(extension);
  }

  // Upload functions
  Future<String?> _uploadCoverImage(File imageFile) async {
    try {
      setState(() => _isUploadingMedia = true);

      // --- ✅ الإصلاح: لا يوجد تحويل إلى Base64 ---
      String fileName =
          'vip_cover_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // استدعاء الدالة الجديدة وتمرير مسار الملف
      final result = await AuthService.uploadVipCoverImage(
        imagePath: imageFile.path,
        fileName: fileName,
      );

      if (result['success'] == true) {
        return result['data']['image_url'];
      } else {
        _showErrorSnackBar(result['message'] ?? 'فشل في رفع صورة الغلاف');
        return null;
      }
    } catch (e) {
      _showErrorSnackBar('خطأ في رفع صورة الغلاف: $e');
      return null;
    } finally {
      if (mounted) setState(() => _isUploadingMedia = false);
    }
  }

  Future<List<String>> _uploadMediaFiles(List<File> mediaFiles) async {
    List<String> uploadedUrls = [];
    // (منطق الـ Dialog يبقى كما هو...)

    for (int i = 0; i < mediaFiles.length; i++) {
      try {
        File file = mediaFiles[i];
        // (منطق التحقق من الحجم يبقى كما هو...)

        String fileName;
        String fileType;

        if (_isVideoFile(file)) {
          // ... (منطق تحديد اسم ونوع الفيديو)
          String extension = file.path.split('.').last.toLowerCase();
          fileName =
              'vip_video_${DateTime.now().millisecondsSinceEpoch}_$i.$extension';
          fileType = 'video';
        } else {
          // ... (منطق تحديد اسم ونوع الصورة)
          String extension = file.path.split('.').last.toLowerCase();
          if (!['jpg', 'jpeg', 'png', 'gif'].contains(extension))
            extension = 'jpg';
          fileName =
              'vip_image_${DateTime.now().millisecondsSinceEpoch}_$i.$extension';
          fileType = 'image';
        }

        // --- ✅ الإصلاح: استدعاء الدالة الجديدة وتمرير المسار ---
        final result = await AuthService.uploadVipMediaFile(
          filePath: file.path,
          fileName: fileName,
          fileType: fileType,
        );

        if (result['success'] == true && result['data'] != null) {
          String fileUrl = result['data']['file_url'];
          // (منطق إضافة http إذا لم يكن موجودًا...)
          uploadedUrls.add(fileUrl);
          // ... (تحديث الـ Dialog)
        } else {
          _showErrorSnackBar('فشل رفع الملف ${i + 1}: ${result['message']}');
        }
      } catch (e) {
        _showErrorSnackBar('خطأ في رفع الملف ${i + 1}: $e');
      }
    }

    // (باقي منطق إغلاق الـ Dialog...)
    return uploadedUrls;
  }

  // تحميل جميع البيانات
  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _loadStatistics(),
      _loadUsers(),
      _loadPosts(),
      _loadVipAds(),
      _loadReportedPosts(),
    ]);
    setState(() => _isLoading = false);
  }

  Future<void> _loadStatistics() async {
    try {
      final result = await AuthService.getAppStatistics();
      if (mounted && result['success'] == true) {
        setState(() {
          _statistics = result['data']['statistics'] ?? {};
        });
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> _loadUsers() async {
    try {
      final result = await AuthService.getAllUsers();
      if (mounted && result['success'] == true) {
        setState(() {
          _users =
              List<Map<String, dynamic>>.from(result['data']['users'] ?? []);
          _filteredUsers = List.from(_users); // تحديث قائمة الفلترة
        });
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> _loadPosts() async {
    try {
      final result = await AuthService.getAllPosts();
      if (mounted && result['success'] == true) {
        setState(() {
          _posts =
              List<Map<String, dynamic>>.from(result['data']['posts'] ?? []);
          _filteredPosts = List.from(_posts); // تحديث قائمة الفلترة
        });
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> _loadVipAds() async {
    try {
      final result = await AuthService.getVipAds();
      if (result['success'] == true && result['data'] != null) {
        setState(() {
          _vipAds = List<Map<String, dynamic>>.from(
            result['data']['vip_ads'] ?? [],
          );
        });
      } else {
        _showErrorSnackBar(result['message'] ?? 'خطأ في جلب الإعلانات المميزة');
      }
    } catch (e) {
      print('Error loading VIP ads: $e');
      _showErrorSnackBar('خطأ في جلب الإعلانات المميزة: $e');
    }
  }

  Future<void> _loadReportedPosts() async {
    try {
      final result = await AuthService.getReportedPosts();
      if (result['success'] == true && result['data'] != null) {
        setState(() {
          _reportedPosts = List<Map<String, dynamic>>.from(
            result['data']['reported_posts'] ?? [],
          );
        });
      } else {
        _showErrorSnackBar(result['message'] ?? 'خطأ في جلب التقارير');
      }
    } catch (e) {
      print('Error loading reported posts: $e');
      _showErrorSnackBar('خطأ في جلب التقارير: $e');
    }
  }

  Future<void> _sendNotification() async {
    if (_notificationTitleController.text.isEmpty ||
        _notificationMessageController.text.isEmpty) {
      _showErrorSnackBar('الرجاء إدخال عنوان ونص الإشعار');
      return;
    }

    try {
      final result = await AuthService.sendNotification(
        title: _notificationTitleController.text,
        message: _notificationMessageController.text,
        phone: _phoneController.text.isEmpty ? null : _phoneController.text,
      );

      if (result['success'] == true) {
        _showSuccessSnackBar(result['message'] ?? 'تم إرسال الإشعار بنجاح');
        _clearNotificationForm();
      } else {
        _showErrorSnackBar(result['message'] ?? 'فشل في إرسال الإشعار');
      }
    } catch (e) {
      print('Error sending notification: $e');
      _showErrorSnackBar('خطأ في إرسال الإشعار: $e');
    }
  }

  void _clearNotificationForm() {
    _notificationTitleController.clear();
    _notificationMessageController.clear();
    _phoneController.clear();
  }

  Future<void> _deleteUserPermanently(int userId) async {
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: const Text(
            'هل أنت متأكد من حذف هذا المستخدم وجميع بياناته نهائياً؟ هذا الإجراء لا يمكن التراجع عنه.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('حذف', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final result = await AuthService.deleteUserPermanently(userId);
      if (result['success'] == true) {
        _showSuccessSnackBar('تم حذف المستخدم وجميع بياناته نهائياً');
        await _loadUsers();
        await _loadPosts();
      } else {
        _showErrorSnackBar(result['message'] ?? 'فشل في حذف المستخدم');
      }
    } catch (e) {
      print('Error deleting user permanently: $e');
      _showErrorSnackBar('خطأ في حذف المستخدم: $e');
    }
  }

  Future<void> _toggleUserStatus(int userId, bool isActive) async {
    try {
      final result = await AuthService.toggleUserStatus(userId, isActive);
      if (result['success'] == true) {
        _showSuccessSnackBar(
          isActive ? 'تم تفعيل المستخدم' : 'تم حظر المستخدم',
        );
        await _loadUsers();
      } else {
        _showErrorSnackBar(result['message'] ?? 'فشل في تغيير حالة المستخدم');
      }
    } catch (e) {
      print('Error toggling user status: $e');
      _showErrorSnackBar('خطأ في تغيير حالة المستخدم: $e');
    }
  }

  Future<void> _deletePost(int postId) async {
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: const Text(
            'هل أنت متأكد من حذف هذا المنشور؟ هذا الإجراء لا يمكن التراجع عنه.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('حذف', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final result = await AuthService.deletePost(postId);
      if (result['success'] == true) {
        _showSuccessSnackBar('تم حذف المنشور بنجاح');
        await _loadPosts();
        await _loadReportedPosts();
      } else {
        _showErrorSnackBar(result['message'] ?? 'فشل في حذف المنشور');
      }
    } catch (e) {
      print('Error deleting post: $e');
      _showErrorSnackBar('خطأ في حذف المنشور: $e');
    }
  }

  Future<void> _deleteVipAd(int adId) async {
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: const Text('هل أنت متأكد من حذف هذا الإعلان المميز؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('حذف', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final result = await AuthService.deleteVipAd(adId);
      if (result['success'] == true) {
        _showSuccessSnackBar('تم حذف الإعلان المميز بنجاح');
        await _loadVipAds();
      } else {
        _showErrorSnackBar(result['message'] ?? 'فشل في حذف الإعلان المميز');
      }
    } catch (e) {
      print('Error deleting VIP ad: $e');
      _showErrorSnackBar('خطأ في حذف الإعلان المميز: $e');
    }
  }

  Future<void> _blockUser(int userId) async {
    try {
      final result = await AuthService.blockUser(userId);
      if (result['success'] == true) {
        _showSuccessSnackBar('تم حظر المستخدم بنجاح');
        await _loadUsers();
        await _loadPosts();
      } else {
        _showErrorSnackBar(result['message'] ?? 'فشل في حظر المستخدم');
      }
    } catch (e) {
      print('Error blocking user: $e');
      _showErrorSnackBar('خطأ في حظر المستخدم: $e');
    }
  }

  void _startVipAdsAutoScroll() {
    if (_vipAds.isNotEmpty) {
      _vipAdsTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
        if (_vipAdsController.hasClients && _vipAds.isNotEmpty) {
          _currentVipAdIndex = (_currentVipAdIndex + 1) % _vipAds.length;
          _vipAdsController.animateToPage(
            _currentVipAdIndex,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _vipAdsTimer?.cancel();
    _tabController?.dispose();
    _userSearchController.dispose();
    _postSearchController.dispose();
    _vipAdsController.dispose();
    _vipTitleController.dispose();
    _vipDescController.dispose();
    _vipPriceController.dispose();
    _vipLocationController.dispose();
    _vipPhoneController.dispose();
    _notificationTitleController.dispose();
    _notificationMessageController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة تحكم الإدارة'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllData,
            tooltip: 'تحديث البيانات',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService.logout();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
            tooltip: 'تسجيل الخروج',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'الإحصائيات'),
            Tab(icon: Icon(Icons.people), text: 'المستخدمين'),
            Tab(icon: Icon(Icons.post_add), text: 'المنشورات'),
            Tab(icon: Icon(Icons.star), text: 'الإعلانات المميزة'),
            Tab(icon: Icon(Icons.report), text: 'الإبلاغات'),
            Tab(icon: Icon(Icons.notifications), text: 'الإشعارات'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildStatisticsTab(),
                _buildUsersTab(),
                _buildPostsTab(),
                _buildVipAdsTab(),
                _buildReportsTab(),
                _buildNotificationsTab(),
              ],
            ),
    );
  }

  Widget _buildStatisticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'إحصائيات التطبيق',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildStatisticsCards(),
          const SizedBox(height: 20),
          if (_statistics.containsKey('top_categories'))
            _buildTopCategoriesChart(),
          const SizedBox(height: 20),
          if (_statistics.containsKey('daily_posts')) _buildDailyPostsChart(),
        ],
      ),
    );
  }

  Widget _buildStatisticsCards() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 0.9,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildStatCard(
          'إجمالي المستخدمين',
          _statistics['total_users']?.toString() ?? '0',
          Icons.people,
          Colors.blue,
        ),
        _buildStatCard(
          'المستخدمون المتصلون',
          _statistics['online_users']?.toString() ?? '0',
          Icons.wifi,
          Colors.lightGreen,
        ),
        _buildStatCard(
          'إجمالي المنشورات',
          _statistics['total_posts']?.toString() ?? '0',
          Icons.post_add,
          Colors.orange,
        ),
        _buildStatCard(
          'التقارير المعلقة',
          _statistics['pending_reports']?.toString() ?? '0',
          Icons.report_problem,
          Colors.red,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopCategoriesChart() {
    if (!_statistics.containsKey('top_categories') ||
        _statistics['top_categories'] == null ||
        (_statistics['top_categories'] as List).isEmpty) {
      return const SizedBox.shrink();
    }

    List<dynamic> topCategories = _statistics['top_categories'];

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'أكثر الفئات استخداماً',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: topCategories.isNotEmpty
                      ? (topCategories[0]['count'] as num).toDouble() * 1.2
                      : 10,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          int index = value.toInt();
                          if (index >= 0 && index < topCategories.length) {
                            String category =
                                topCategories[index]['category'] ?? '';
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                category.length > 8
                                    ? '${category.substring(0, 8)}...'
                                    : category,
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: topCategories.asMap().entries.map((entry) {
                    int index = entry.key;
                    Map<String, dynamic> category = entry.value;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: (category['count'] as num).toDouble(),
                          color: Colors.blue[300],
                          width: 20,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyPostsChart() {
    if (!_statistics.containsKey('daily_posts') ||
        _statistics['daily_posts'] == null ||
        (_statistics['daily_posts'] as List).isEmpty) {
      return const SizedBox.shrink();
    }

    List<dynamic> dailyPosts = _statistics['daily_posts'];

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'المنشورات اليومية (آخر 30 يوم)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 5,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          int index = value.toInt();
                          if (index >= 0 && index < dailyPosts.length) {
                            String date = dailyPosts[index]['date'] ?? '';
                            return Text(
                              date.split('-').last,
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: dailyPosts.asMap().entries.map((entry) {
                        int index = entry.key;
                        Map<String, dynamic> day = entry.value;
                        return FlSpot(
                          index.toDouble(),
                          (day['posts_count'] as num).toDouble(),
                        );
                      }).toList(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withAlpha(77),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _userSearchController,
            decoration: InputDecoration(
              labelText: 'بحث عن مستخدم (بالاسم, البريد, أو الهاتف)',
              prefixIcon: Icon(Icons.search),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              suffixIcon: _userSearchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () => _userSearchController.clear(),
                    )
                  : null,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _filteredUsers.length,
            itemBuilder: (context, index) {
              final user = _filteredUsers[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        user['is_admin'] == 1 ? Colors.red : Colors.blue,
                    child: Icon(
                      user['is_admin'] == 1
                          ? Icons.admin_panel_settings
                          : Icons.person,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(user['full_name'] ?? 'مستخدم'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (user['email'] != null)
                        Text('البريد: ${user['email']}'),
                      if (user['phone'] != null)
                        Text('الهاتف: ${user['phone']}'),
                      Text('تاريخ التسجيل: ${_formatDate(user['created_at'])}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        user['is_active'] == 1
                            ? Icons.check_circle
                            : Icons.block,
                        color:
                            user['is_active'] == 1 ? Colors.green : Colors.red,
                      ),
                      PopupMenuButton<String>(
                        onSelected: (String action) {
                          switch (action) {
                            case 'toggle_status':
                              _toggleUserStatus(
                                user['id'],
                                user['is_active'] != 1,
                              );
                              break;
                            case 'delete':
                              _deleteUserPermanently(user['id']);
                              break;
                            case 'block':
                              _blockUser(user['id']);
                              break;
                          }
                        },
                        itemBuilder: (BuildContext context) => [
                          PopupMenuItem<String>(
                            value: 'toggle_status',
                            child: Text(
                              user['is_active'] == 1
                                  ? 'حظر المستخدم'
                                  : 'تفعيل المستخدم',
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'block',
                            child: Text('حظر سريع'),
                          ),
                          const PopupMenuItem<String>(
                            value: 'delete',
                            child: Text(
                              'حذف نهائي',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPostsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _postSearchController,
            decoration: InputDecoration(
              labelText: 'بحث في المنشورات (بالعنوان, المحتوى, المستخدم)',
              prefixIcon: Icon(Icons.search),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              suffixIcon: _postSearchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () => _postSearchController.clear(),
                    )
                  : null,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _filteredPosts.length,
            itemBuilder: (context, index) {
              final post = _filteredPosts[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(post['user_avatar'] ?? ''),
                    onBackgroundImageError: (exception, stackTrace) {},
                    child: post['user_avatar'] == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(post['title'] ?? 'منشور'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('بواسطة: ${post['user_name'] ?? 'مستخدم'}'),
                      Text('الفئة: ${post['category'] ?? 'غير محدد'}'),
                      if (post['price'] != null)
                        Text('السعر: ${post['price']} ل.س'),
                      if (post['location'] != null)
                        Text('الموقع: ${post['location']}'),
                      Text('تاريخ النشر: ${_formatDate(post['created_at'])}'),
                      Text(
                        'الإعجابات: ${post['likes_count'] ?? 0} | التعليقات: ${post['comments_count'] ?? 0}',
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        post['is_active'] == 1
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color:
                            post['is_active'] == 1 ? Colors.green : Colors.red,
                      ),
                      PopupMenuButton<String>(
                        onSelected: (String action) {
                          switch (action) {
                            case 'delete':
                              _deletePost(post['id']);
                              break;
                            case 'block_user':
                              _blockUser(post['id']);
                              break;
                          }
                        },
                        itemBuilder: (BuildContext context) => [
                          const PopupMenuItem<String>(
                            value: 'delete',
                            child: Text(
                              'حذف المنشور',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'block_user',
                            child: Text('حظر صاحب المنشور'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  isThreeLine: true,
                  onTap: () {
                    _showPostDetails(post);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVipAdsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadVipAds,
                tooltip: 'تحديث الإعلانات المميزة',
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _openCreateVipAdDialog,
                icon: const Icon(Icons.add),
                label: const Text('إنشاء إعلان VIP'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber[600],
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _vipAds.length,
            itemBuilder: (context, index) {
              final ad = _vipAds[index];
              final title = ad['title'] as String? ?? 'إعلان بدون عنوان';
              final userName = ad['user_name'] as String? ?? 'مستخدم غير معروف';
              final status = _getAdStatusText(ad['status'] as String?);
              final expiryDate = _formatDate(ad['expires_at'] as String?);
              final mediaCount = (ad['media_files'] is List)
                  ? (ad['media_files'] as List).length
                  : 0;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 25,
                    backgroundImage: (ad['cover_image_url'] is String)
                        ? NetworkImage(ad['cover_image_url'])
                        : null,
                    backgroundColor: Colors.amber,
                  ),
                  title: Text(title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('بواسطة: $userName'),
                      Text('الحالة: $status'),
                      Text('تاريخ الانتهاء: $expiryDate'),
                      Text('عدد الوسائط الإضافية: $mediaCount'),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (String action) {
                      if (action == 'view') {
                        _showVipAdDetails(ad);
                      } else if (action == 'delete') {
                        final adId = int.tryParse(ad['id']?.toString() ?? '');
                        if (adId != null) {
                          _deleteVipAd(adId);
                        }
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem<String>(
                        value: 'view',
                        child: Text('عرض التفاصيل'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Text('حذف', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReportsTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.blue.shade50,
          child: Row(
            children: [
              const Icon(Icons.report_problem, color: Colors.red),
              const SizedBox(width: 8),
              const Text(
                'الإبلاغات المرسلة من المستخدمين',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _loadReports,
                child: const Text('تحديث'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _reportedPosts.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, size: 80, color: Colors.green),
                      SizedBox(height: 16),
                      Text(
                        'لا توجد إبلاغات جديدة',
                        style: TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _reportedPosts.length,
                  itemBuilder: (context, index) {
                    final report = _reportedPosts[index];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ExpansionTile(
                        title: Text(
                          'إبلاغ عن: ${report['post_title'] ?? 'منشور'}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                'المبلغ: ${report['reporter_name'] ?? 'مجهول'}'),
                            Text('السبب: ${report['reason'] ?? 'غير محدد'}'),
                            Text(
                                'التاريخ: ${_formatDate(report['created_at'])}'),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(report['status']),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _getStatusText(report['status']),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (report['description'] != null &&
                                    report['description'].isNotEmpty) ...[
                                  const Text(
                                    'تفاصيل الإبلاغ:',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(report['description']),
                                  const SizedBox(height: 16),
                                ],
                                const Text(
                                  'محتوى المنشور:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    report['post_content'] ?? 'لا يوجد محتوى',
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () =>
                                            _viewPost(report['post_id']),
                                        icon: const Icon(Icons.visibility),
                                        label: const Text('عرض المنشور'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () =>
                                            _deletePost(report['post_id']),
                                        icon: const Icon(Icons.delete),
                                        label: const Text('حذف المنشور'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton.icon(
                                  onPressed: () => _respondToReport(report),
                                  icon: const Icon(Icons.reply),
                                  label: const Text('الرد على الإبلاغ'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _loadReports() async {
    try {
      final result = await AuthService.getPostReports();
      if (result['success'] == true) {
        setState(() {
          _reportedPosts =
              List<Map<String, dynamic>>.from(result['data']['reports'] ?? []);
        });
      } else {
        _showErrorSnackBar(result['message'] ?? 'خطأ في جلب التقارير');
      }
    } catch (e) {
      _showErrorSnackBar('خطأ في جلب التقارير: $e');
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'reviewed':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'dismissed':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'pending':
        return 'قيد المراجعة';
      case 'reviewed':
        return 'تمت المراجعة';
      case 'resolved':
        return 'تم الحل';
      case 'dismissed':
        return 'مرفوض';
      default:
        return 'قيد المراجعة';
    }
  }

  void _viewPost(int postId) {
    _showSuccessSnackBar('سيتم الانتقال إلى المنشور رقم $postId');
  }

  void _respondToReport(Map<String, dynamic> report) {
    showDialog(
      context: context,
      builder: (context) {
        String selectedStatus = report['status'] ?? 'pending';
        String adminResponse = report['admin_response'] ?? '';

        return AlertDialog(
          title: const Text('الرد على الإبلاغ'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedStatus,
                decoration: const InputDecoration(labelText: 'حالة الإبلاغ'),
                items: const [
                  DropdownMenuItem(
                      value: 'pending', child: Text('قيد المراجعة')),
                  DropdownMenuItem(
                      value: 'reviewed', child: Text('تمت المراجعة')),
                  DropdownMenuItem(value: 'resolved', child: Text('تم الحل')),
                  DropdownMenuItem(value: 'dismissed', child: Text('مرفوض')),
                ],
                onChanged: (value) => selectedStatus = value ?? 'pending',
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'رد الإدارة (اختياري)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                onChanged: (value) => adminResponse = value,
                controller: TextEditingController(text: adminResponse),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                final result = await AuthService.updateReportStatus(
                  reportId: report['id'],
                  status: selectedStatus,
                  adminResponse: adminResponse.isEmpty ? null : adminResponse,
                );

                if (result['success'] == true) {
                  _showSuccessSnackBar('تم تحديث حالة الإبلاغ');
                  _loadReports();
                } else {
                  _showErrorSnackBar(result['message'] ?? 'خطأ في التحديث');
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNotificationsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'إرسال إشعار',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _notificationTitleController,
                    decoration: const InputDecoration(
                      labelText: 'عنوان الإشعار',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _notificationMessageController,
                    decoration: const InputDecoration(
                      labelText: 'نص الإشعار',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText:
                          'رقم الهاتف (اختياري - اتركه فارغاً للإرسال للجميع)',
                      border: OutlineInputBorder(),
                      helperText:
                          'إذا تركت هذا الحقل فارغاً، سيتم إرسال الإشعار لجميع المستخدمين',
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _sendNotification,
                      icon: const Icon(Icons.send, color: Colors.white),
                      label: Text(
                        _phoneController.text.isEmpty
                            ? 'إرسال لجميع المستخدمين'
                            : 'إرسال لمستخدم واحد',
                        style: const TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPostDetails(Map<String, dynamic> post) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(post['title'] ?? 'تفاصيل المنشور'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('المحتوى: ${post['content'] ?? 'لا يوجد محتوى'}'),
                const SizedBox(height: 8),
                Text('الفئة: ${post['category'] ?? 'غير محدد'}'),
                if (post['price'] != null) ...[
                  const SizedBox(height: 8),
                  Text('السعر: ${post['price']} ل.س'),
                ],
                if (post['location'] != null) ...[
                  const SizedBox(height: 8),
                  Text('الموقع: ${post['location']}'),
                ],
                const SizedBox(height: 8),
                Text('بواسطة: ${post['user_name'] ?? 'مستخدم'}'),
                const SizedBox(height: 8),
                Text('تاريخ النشر: ${_formatDate(post['created_at'])}'),
                const SizedBox(height: 8),
                Text('الإعجابات: ${post['likes_count'] ?? 0}'),
                const SizedBox(height: 8),
                Text('التعليقات: ${post['comments_count'] ?? 0}'),
                if (post['images'] != null &&
                    (post['images'] as List).isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('عدد الصور: ${(post['images'] as List).length}'),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إغلاق'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deletePost(post['id']);
              },
              child: const Text(
                'حذف المنشور',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showVipAdDetails(Map<String, dynamic> ad) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(ad['title'] ?? 'تفاصيل الإعلان المميز'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // عرض صورة الغلاف
                if (ad['cover_image_url'] != null)
                  Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: NetworkImage(ad['cover_image_url']),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Text('الوصف: ${ad['description'] ?? 'لا يوجد وصف'}'),
                const SizedBox(height: 8),
                Text(
                  'السعر المدفوع: \$${ad['price_paid']?.toString() ?? '0.00'}',
                ),
                const SizedBox(height: 8),
                Text('الحالة: ${_getAdStatusText(ad['status'])}'),
                const SizedBox(height: 8),
                Text('تاريخ الإنشاء: ${_formatDate(ad['created_at'])}'),
                if (ad['expires_at'] != null) ...[
                  const SizedBox(height: 8),
                  Text('تاريخ الانتهاء: ${_formatDate(ad['expires_at'])}'),
                ],
                if (ad['media_files'] != null &&
                    (ad['media_files'] as List).isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'عدد الوسائط الإضافية: ${(ad['media_files'] as List).length}',
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إغلاق'),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'غير محدد';
    try {
      DateTime date = DateTime.parse(dateString);
      return DateFormat('yyyy-MM-dd HH:mm').format(date);
    } catch (e) {
      return dateString;
    }
  }

  String _getAdStatusText(String? status) {
    switch (status) {
      case 'active':
        return 'نشط';
      case 'pending':
        return 'في الانتظار';
      case 'expired':
        return 'منتهي الصلاحية';
      case 'rejected':
        return 'مرفوض';
      default:
        return 'غير محدد';
    }
  }

  // Enhanced VIP Ad Creation Dialog
  void _openCreateVipAdDialog() {
    // Reset form data
    _selectedCoverImage = null;
    _selectedMediaFiles.clear();
    _vipTitleController.clear();
    _vipDescController.clear();
    _vipPriceController.clear();
    _vipLocationController.clear();
    _vipPhoneController.clear();

    showDialog(
      context: context,
      builder: (context) {
        String _currency = 'USD';
        String _status = 'active';
        int _durationHours = 48;
        final TextEditingController _vipWhatsappController =
            TextEditingController();
        final TextEditingController _vipCurrencyController =
            TextEditingController(text: _currency);
        final TextEditingController _vipDurationController =
            TextEditingController(text: _durationHours.toString());

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('إنشاء إعلان VIP محسن'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.9,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // صورة الغلاف
                      Card(
                        color: Colors.amber[50],
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.image, color: Colors.amber[800]),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'صورة الغلاف (مطلوبة)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (_selectedCoverImage != null)
                                Container(
                                  height: 120,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    image: DecorationImage(
                                      image: FileImage(_selectedCoverImage!),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  height: 80,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey[400]!,
                                    ),
                                  ),
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.image,
                                        size: 30,
                                        color: Colors.grey,
                                      ),
                                      Text(
                                        'لم يتم اختيار صورة غلاف',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _selectCoverImage,
                                  icon: const Icon(Icons.image),
                                  label: Text(
                                    _selectedCoverImage != null
                                        ? 'تغيير صورة الغلاف'
                                        : 'اختيار صورة الغلاف',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber[600],
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'سيتم قص الصورة تلقائياً بنسبة 16:9 لتناسب عرض الإعلانات',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // الوسائط الإضافية
                      Card(
                        color: Colors.blue[50],
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.collections,
                                    color: Colors.blue[800],
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'الوسائط الإضافية (اختيارية)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (_selectedMediaFiles.isNotEmpty) ...[
                                SizedBox(
                                  height: 80,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _selectedMediaFiles.length,
                                    itemBuilder: (context, index) {
                                      File file = _selectedMediaFiles[index];
                                      bool isVideo = _isVideoFile(file);

                                      return Container(
                                        margin: const EdgeInsets.only(right: 8),
                                        width: 80,
                                        height: 80,
                                        child: Stack(
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                color: Colors.grey[300],
                                              ),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: isVideo
                                                    ? Container(
                                                        width: double.infinity,
                                                        height: double.infinity,
                                                        color: Colors.black87,
                                                        child: const Icon(
                                                          Icons
                                                              .play_circle_filled,
                                                          color: Colors.white,
                                                          size: 30,
                                                        ),
                                                      )
                                                    : Image.file(
                                                        file,
                                                        width: double.infinity,
                                                        height: double.infinity,
                                                        fit: BoxFit.cover,
                                                      ),
                                              ),
                                            ),
                                            Positioned(
                                              top: 2,
                                              right: 2,
                                              child: GestureDetector(
                                                onTap: () {
                                                  setStateDialog(() {
                                                    _removeMediaFile(index);
                                                  });
                                                },
                                                child: Container(
                                                  padding: const EdgeInsets.all(
                                                    2,
                                                  ),
                                                  decoration:
                                                      const BoxDecoration(
                                                    color: Colors.red,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.close,
                                                    color: Colors.white,
                                                    size: 12,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _selectedMediaFiles.length < 10
                                      ? _selectMediaFiles
                                      : null,
                                  icon: const Icon(Icons.add_photo_alternate),
                                  label: Text(
                                    'إضافة صور/فيديو (${_selectedMediaFiles.length}/10)',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue[600],
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'يمكن إضافة حتى 10 صور أو فيديوهات إضافية. حجم الفيديو الأقصى 50 ميجابايت.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // المعلومات الأساسية
                      TextField(
                        controller: _vipTitleController,
                        decoration: const InputDecoration(
                          labelText: 'العنوان *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.title),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _vipDescController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'الوصف',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _vipPhoneController,
                        decoration: const InputDecoration(
                          labelText: 'هاتف التواصل',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _vipWhatsappController,
                        decoration: const InputDecoration(
                          labelText: 'واتساب',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.message),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // إعدادات الإعلان
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _vipPriceController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'سعر مدفوع',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.attach_money),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _vipCurrencyController,
                              decoration: const InputDecoration(
                                labelText: 'العملة',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (v) {
                                _currency = v;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _vipDurationController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'المدة بالساعات',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.timer),
                              ),
                              onChanged: (v) {
                                final n = int.tryParse(v) ?? 48;
                                _durationHours = n;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _status,
                              items: const [
                                DropdownMenuItem(
                                  value: 'active',
                                  child: Text('نشط'),
                                ),
                                DropdownMenuItem(
                                  value: 'pending',
                                  child: Text('بانتظار الموافقة'),
                                ),
                                DropdownMenuItem(
                                  value: 'expired',
                                  child: Text('منتهي'),
                                ),
                                DropdownMenuItem(
                                  value: 'rejected',
                                  child: Text('مرفوض'),
                                ),
                              ],
                              onChanged: (v) {
                                if (v != null)
                                  setStateDialog(() => _status = v);
                              },
                              decoration: const InputDecoration(
                                labelText: 'الحالة',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.flag),
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (_isUploadingMedia) ...[
                        const SizedBox(height: 16),
                        const Card(
                          color: Colors.orange,
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: Row(
                              children: [
                                CircularProgressIndicator(color: Colors.white),
                                SizedBox(width: 12),
                                Text(
                                  'جاري رفع الملفات...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _isUploadingMedia
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: _isUploadingMedia
                      ? null
                      : () async {
                          await _submitEnhancedVipAd(
                            title: _vipTitleController.text.trim(),
                            description: _vipDescController.text.trim(),
                            contactPhone:
                                _vipPhoneController.text.trim().isEmpty
                                    ? null
                                    : _vipPhoneController.text.trim(),
                            contactWhatsapp:
                                _vipWhatsappController.text.trim().isEmpty
                                    ? null
                                    : _vipWhatsappController.text.trim(),
                            pricePaid: double.tryParse(
                              _vipPriceController.text.trim(),
                            ),
                            currency: _currency,
                            durationHours: _durationHours,
                            status: _status,
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    _isUploadingMedia ? 'جاري الرفع...' : 'إنشاء الإعلان',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submitEnhancedVipAd({
    required String title,
    String? description,
    String? contactWhatsapp,
    String? contactPhone,
    double? pricePaid,
    String? currency,
    int? durationHours,
    String status = 'active',
  }) async {
    if (title.isEmpty) {
      _showErrorSnackBar('الرجاء إدخال العنوان');
      return;
    }

    if (_selectedCoverImage == null) {
      _showErrorSnackBar('الرجاء اختيار صورة الغلاف');
      return;
    }

    try {
      // رفع صورة الغلاف
      String? coverImageUrl = await _uploadCoverImage(_selectedCoverImage!);
      if (coverImageUrl == null) {
        _showErrorSnackBar('فشل في رفع صورة الغلاف');
        return;
      }

      // رفع الوسائط الإضافية
      List<String> mediaUrls = [];
      if (_selectedMediaFiles.isNotEmpty) {
        mediaUrls = await _uploadMediaFiles(_selectedMediaFiles);
        if (mediaUrls.length != _selectedMediaFiles.length) {
          _showErrorSnackBar(
            'تم رفع ${mediaUrls.length} من ${_selectedMediaFiles.length} ملف فقط',
          );
        }
      }

      // إنشاء الإعلان
      final result = await AuthService.createEnhancedVipAd(
        title: title,
        description: description,
        coverImageUrl: coverImageUrl,
        mediaUrls: mediaUrls,
        contactWhatsapp: contactWhatsapp,
        contactPhone: contactPhone,
        pricePaid: pricePaid,
        currency: currency,
        durationHours: durationHours,
        status: status,
      );

      if (result['success'] == true) {
        Navigator.of(context).pop();
        _showSuccessSnackBar('تم إنشاء إعلان VIP بنجاح');
        await _loadVipAds();

        // تنظيف النموذج
        _selectedCoverImage = null;
        _selectedMediaFiles.clear();
        _vipTitleController.clear();
        _vipDescController.clear();
        _vipPriceController.clear();
        _vipPhoneController.clear();
      } else {
        _showErrorSnackBar(result['message'] ?? 'فشل في إنشاء الإعلان');
      }
    } catch (e) {
      _showErrorSnackBar('خطأ: ${e.toString()}');
    }
  }

  // وظائف الفلترة
  void _filterUsers(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredUsers = List.from(_users);
      });
      return;
    }
    final lowerCaseQuery = query.toLowerCase();
    final filtered = _users.where((user) {
      final name = user['full_name']?.toString().toLowerCase() ?? '';
      final email = user['email']?.toString().toLowerCase() ?? '';
      final phone = user['phone']?.toString().toLowerCase() ?? '';
      return name.contains(lowerCaseQuery) ||
          email.contains(lowerCaseQuery) ||
          phone.contains(lowerCaseQuery);
    }).toList();
    setState(() {
      _filteredUsers = filtered;
    });
  }

  void _filterPosts(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredPosts = List.from(_posts);
      });
      return;
    }
    final lowerCaseQuery = query.toLowerCase();
    final filtered = _posts.where((post) {
      final title = post['title']?.toString().toLowerCase() ?? '';
      final content = post['content']?.toString().toLowerCase() ?? '';
      final userName = post['user_name']?.toString().toLowerCase() ?? '';
      final category = post['category']?.toString().toLowerCase() ?? '';
      return title.contains(lowerCaseQuery) ||
          content.contains(lowerCaseQuery) ||
          userName.contains(lowerCaseQuery) ||
          category.contains(lowerCaseQuery);
    }).toList();
    setState(() {
      _filteredPosts = filtered;
    });
  }
}
