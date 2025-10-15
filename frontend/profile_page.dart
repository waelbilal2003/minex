import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'login_page.dart';
import 'user_profile_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // --- ✨ بداية التعديل 1: توحيد عملية تحميل البيانات ---
    _initializeProfile();
    // --- ✨ نهاية التعديل 1 ---
  }

  Future<void> _loadProfile() async {
    await AuthService.loadUserData();
    final result = await AuthService.getProfile();
    if (result['success'] == true) {
      setState(() {
        _currentUser = result['data'];
        _isLoading = false;
      });
    } else {
      // fall back to local data if server not available
      setState(() {
        _currentUser = AuthService.currentUser;
        _isLoading = false;
      });
    }
  }

  void _loadUserData() {
    // بدلاً من إعادة التحميل من الذاكرة، نأخذ البيانات مباشرة من الحالة الحالية للتطبيق
    // هذا يضمن أن البيانات التي تم حفظها بعد التسجيل مباشرةً هي التي يتم عرضها
    final user = AuthService.currentUser;

    // التحقق من أن المستخدم مسجل دخوله بالفعل قبل تحديث الواجهة
    if (user != null) {
      if (mounted) {
        setState(() {
          _currentUser = user;
          _isLoading = false;
        });
      }
    } else {
      // في حالة عدم وجود مستخدم (نادر، لكنه آمن)، نتوقف عن التحميل
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Color _getGenderColor() {
    final _g = (_currentUser?['gender'] ?? '').toString().toLowerCase();
    if (_g == 'ذكر' || _g == 'male' || _g == 'm') {
      return Colors.blue;
    } else if (_g == 'أنثى' || _g == 'female' || _g == 'f') {
      return Colors.pink;
    }
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'الملف الشخصي',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _getGenderColor(),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildProfileInfo(),
            const SizedBox(height: 20),
            _buildSettingsItem(
              icon: Icons.edit,
              title: 'تعديل الملف الشخصي',
              onTap: () => _editProfile(),
            ),
            _buildSettingsItem(
              icon: Icons.lock,
              title: 'تغيير كلمة المرور',
              onTap: () => _changePassword(),
            ),
            _buildSettingsItem(
              icon: Icons.help,
              title: 'المساعدة والدعم',
              onTap: () => _helpAndSupport(),
            ),
            _buildSettingsItem(
              icon: Icons.info,
              title: 'حول التطبيق',
              onTap: () => _aboutApp(),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: const Text(
                  'تسجيل الخروج',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfo() {
    String displayContact = '';
    if (_currentUser?['phone'] != null && _currentUser!['phone'].isNotEmpty) {
      displayContact = AuthService.formatPhoneNumber(_currentUser!['phone']);
    } else if (_currentUser?['email'] != null &&
        _currentUser!['email'].isNotEmpty) {
      displayContact = _currentUser!['email'];
    } else {
      displayContact = 'غير محدد';
    }

    final bool isStore = _currentUser?['user_type'] == 'store';

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // --- ✨ بداية التعديل 1: تفعيل النقر على الصورة ---
            GestureDetector(
              onTap: _navigateToPublicProfile,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: _getGenderColor(),
                child: Icon(
                  isStore ? Icons.storefront : Icons.person,
                  color: Colors.white,
                  size: 60,
                ),
              ),
            ),
            // --- ✨ نهاية التعديل 1 ---
            const SizedBox(height: 16),
            // --- ✨ بداية التعديل 2: تفعيل النقر على الاسم ---
            GestureDetector(
              onTap: _navigateToPublicProfile,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _currentUser?['full_name'] ?? 'غير محدد',
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  if (isStore) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle,
                              color: Colors.amber, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'متجر',
                            style: TextStyle(
                              color: Colors.amber,
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
            ),
            // --- ✨ نهاية التعديل 2 ---
            const SizedBox(height: 8),
            Text(
              displayContact,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            if (!isStore)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getGenderColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _getGenderColor()),
                ),
                child: Text(
                  _currentUser?['gender'] ?? 'غير محدد',
                  style: TextStyle(
                    color: _getGenderColor(),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: _getGenderColor()),
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        trailing:
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
        onTap: onTap,
      ),
    );
  }

  void _editProfile() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController nameController = TextEditingController(
          text: _currentUser?['full_name'] ?? '',
        );

        String? selectedGender = _currentUser?['gender'];

        return AlertDialog(
          title: const Text('تعديل الملف الشخصي'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'الاسم الكامل',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // 👇 هنا القائمة المنسدلة لاختيار الجنس
              DropdownButtonFormField<String>(
                value: selectedGender,
                items: const [
                  DropdownMenuItem(value: 'ذكر', child: Text('ذكر')),
                  DropdownMenuItem(value: 'أنثى', child: Text('أنثى')),
                ],
                onChanged: (value) {
                  selectedGender = value;
                },
                decoration: const InputDecoration(labelText: "الجنس"),
              ),

              const SizedBox(height: 16),
              const Text(
                'لتغيير رقم الهاتف أو البريد الإلكتروني، يرجى التواصل مع الدعم الفني.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                final result = await AuthService.updateProfile(
                  fullName: nameController.text,
                  gender: selectedGender, // 👈 إرسال الجنس مع الطلب
                );

                Navigator.of(context).pop();

                if (result['success']) {
                  _loadUserData(); // إعادة تحميل البيانات
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('تم تحديث الملف الشخصي بنجاح')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(result['message'])),
                  );
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );
  }

  // باقي الدوال كما هي (تغيير كلمة المرور - الإشعارات - الخصوصية - الدعم - حول - تسجيل الخروج)
  void _changePassword() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController currentPasswordController =
            TextEditingController();
        final TextEditingController newPasswordController =
            TextEditingController();
        final TextEditingController confirmPasswordController =
            TextEditingController();

        return AlertDialog(
          title: const Text('تغيير كلمة المرور'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'كلمة المرور الحالية',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'كلمة المرور الجديدة',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'تأكيد كلمة المرور الجديدة',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (newPasswordController.text !=
                    confirmPasswordController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('كلمات المرور غير متطابقة')),
                  );
                  return;
                }

                final result = await AuthService.changePassword(
                  currentPassword: currentPasswordController.text,
                  newPassword: newPasswordController.text,
                );

                Navigator.of(context).pop();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(result['message'])),
                );
              },
              child: const Text('تغيير'),
            ),
          ],
        );
      },
    );
  }

  void _helpAndSupport() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('المساعدة والدعم'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('للحصول على المساعدة، يمكنك التواصل معنا عبر:'),
              SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.email, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('support@minex.com'),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.phone, color: Colors.green),
                  SizedBox(width: 8),
                  Text('+963 11 123 4567'),
                ],
              ),
            ],
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

  void _aboutApp() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('حول التطبيق'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Minex',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('الإصدار: 1.0.0'),
              SizedBox(height: 8),
              Text('السوق المفتوح الأول في سوريا'),
              SizedBox(height: 16),
              Text(
                'تطبيق Minex يوفر منصة آمنة وسهلة للبيع والشراء في سوريا.',
                style: TextStyle(fontSize: 14),
              ),
            ],
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

  void _logout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('تسجيل الخروج'),
          content: const Text('هل أنت متأكد من أنك تريد تسجيل الخروج؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await AuthService.logout();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('تسجيل الخروج'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToPublicProfile() {
    // جلب البيانات اللازمة من المستخدم الحالي
    final userId = _currentUser?['user_id'];
    final userName = _currentUser?['full_name'];

    // التأكد من أن البيانات موجودة قبل الانتقال
    if (userId == null || userName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يمكن تحميل الملف الشخصي الآن')),
      );
      return;
    }

    // الانتقال إلى صفحة الملف الشخصي العامة
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfilePage(
          userId: userId,
          userName: userName,
        ),
      ),
    );
  }

  Future<void> _initializeProfile() async {
    // أولاً: عرض البيانات المتاحة فوراً من الذاكرة لتجربة مستخدم سريعة
    final cachedUser = AuthService.currentUser;
    if (cachedUser != null) {
      if (mounted) {
        setState(() {
          _currentUser = cachedUser;
          _isLoading = false; // إيقاف التحميل لأن لدينا بيانات أولية
        });
      }
    }

    // ثانياً: محاولة جلب أحدث البيانات من الخادم في الخلفية
    final result = await AuthService.getProfile();

    // ثالثاً: تحديث الواجهة فقط إذا نجح الطلب وكانت هناك بيانات جديدة
    if (mounted && result['success'] == true && result['data'] != null) {
      setState(() {
        _currentUser = result['data'];
      });
    } else if (cachedUser == null) {
      // حالة نادرة: إذا لم تكن هناك بيانات مخزنة وفشل طلب الخادم
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(result['message'] ?? 'فشل تحميل الملف الشخصي')),
        );
      }
    }
  }
// --- ✨ نهاية التعديل 2 ---
}
