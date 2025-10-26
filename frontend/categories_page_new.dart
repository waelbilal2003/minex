import 'package:flutter/material.dart';
import 'posts_page.dart';
import 'auth_service.dart';
import 'vip_ads_widget.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({Key? key}) : super(key: key);

  @override
  _CategoriesPageState createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final PageController _vipAdsController = PageController();
  int _currentVipAdIndex = 0;
  String _userGender = 'ذكر'; // افتراضي

  // قائمة الإعلانات المميزة VIP
  List<Map<String, dynamic>> _vipAds = [];

  // الأقسام العلوية الجديدة
  // ✨ تم إضافة ID لكل قسم هنا ✨
  final List<Map<String, dynamic>> _topCategories = [
    {
      'id': 25, // ✨
      'name': 'اقتراحات وشكاوي',
      'icon': Icons.feedback,
      'color': Colors.red,
      'category_slug': 'suggestions',
    },
    {
      'id': 26, // ✨
      'name': 'تواصل للإعلانات',
      'icon': Icons.contact_phone,
      'color': Colors.teal,
      'category_slug': 'ad_contact',
    },
  ];

  final List<Map<String, dynamic>> _mainCategories = [
    {'id': 13, 'name': 'التوظيف', 'image': 'assets/images/job.png'},
    {'id': 14, 'name': 'المناقصات', 'image': 'assets/images/tenders.png'},
    {'id': 15, 'name': 'الموردين', 'image': 'assets/images/suppliers.png'},
    {
      'id': 16,
      'name': 'العروض العامة',
      'image': 'assets/images/general_offers.png'
    },
  ];

  final List<Map<String, dynamic>> _markets = [
    {'id': 1, 'name': 'السيارات', 'image': 'assets/images/cars.png'},
    {
      'id': 2,
      'name': 'الدراجات النارية',
      'image': 'assets/images/motorcycles.png'
    },
    {
      'id': 3,
      'name': 'تجارة العقارات',
      'image': 'assets/images/real_estate.png'
    },
    {
      'id': 4,
      'name': 'المستلزمات العسكرية',
      'image': 'assets/images/weapons.png'
    },
    {
      'id': 5,
      'name': 'الهواتف والالكترونيات',
      'image': 'assets/images/electronics.png'
    },
    {
      'id': 6,
      'name': 'الأدوات الكهربائية',
      'image': 'assets/images/electrical.png'
    },
    {
      'id': 7,
      'name': 'ايجار العقارات',
      'image': 'assets/images/house_rent.png'
    },
    {
      'id': 8,
      'name': 'الثمار والحبوب',
      'image': 'assets/images/agriculture.png'
    },
    {'id': 9, 'name': 'المواد الغذائية', 'image': 'assets/images/food.webp'},
    {'id': 10, 'name': 'المطاعم', 'image': 'assets/images/restaurants.webp'},
    {'id': 11, 'name': 'مواد التدفئة', 'image': 'assets/images/heating.png'},
    {
      'id': 12,
      'name': 'المكياج و الاكسسوار',
      'image': 'assets/images/accessories.webp'
    },
    {
      'id': 17,
      'name': 'المواشي والحيوانات',
      'image': 'assets/images/animals.png'
    },
    {
      'id': 18,
      'name': 'الكتب و القرطاسية',
      'image': 'assets/images/books.webp'
    },
    {
      'id': 19,
      'name': 'الأدوات المنزلية',
      'image': 'assets/images/home_health.png'
    },
    {
      'id': 20,
      'name': 'الملابس والأحذية',
      'image': 'assets/images/clothing_shoes.webp'
    },
    {'id': 21, 'name': 'أثاث المنزل', 'image': 'assets/images/furniture.png'},
    {'id': 22, 'name': 'تجار الجملة', 'image': 'assets/images/wholesalers.png'},
    {'id': 23, 'name': 'الموزعين', 'image': 'assets/images/distributors.png'},
    {'id': 24, 'name': 'أسواق أخرى', 'image': 'assets/images/others.png'},
  ];

  // ✨ --- نهاية التعديل --- ✨

  @override
  void initState() {
    super.initState();
    _loadUserData();
    // ✨ تم حذف _fetchVipAds() و _startVipAdsAutoScroll() من هنا لأن الويدجت يعتني بنفسه
  }

  // ✨ تم حذف _fetchVipAds, _startVipAdsAutoScroll, _vipAdsController, _currentVipAdIndex, _vipAds

  void _loadUserData() async {
    try {
      await AuthService.loadUserData();
      if (mounted) {
        setState(() {
          _userGender = AuthService.currentUser?['user_gender'] ?? 'ذكر';
        });
      }
    } catch (e) {
      print('خطأ في تحميل بيانات المستخدم: $e');
    }
  }

  Color get _primaryColor => _userGender == 'ذكر' ? Colors.blue : Colors.pink;

  Widget _buildTopCategoryCard(
    Map<String, dynamic> category,
    BuildContext context,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: category['color'], width: 2),
        boxShadow: [
          BoxShadow(
            color: isDarkMode ? Colors.black : Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          if (category['id'] == 25 || category['id'] == 26) {
            _showContactDialog(context);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PostsPage(
                  categoryId: category['id'],
                  categoryName: category['name'],
                ),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(category['icon'], size: 30, color: category['color']),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                category['name'],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : category['color'],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainCategoryCard(
    Map<String, dynamic> category,
    BuildContext context,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _primaryColor.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: isDarkMode ? Colors.black : Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostsPage(
                categoryId: category['id'], // ✅ إرسال الـ ID بدلاً من الاسم
                categoryName: category['name'],
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                flex: 7,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      category['image'],
                      width: double.infinity,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: Icon(
                            Icons.image_not_supported,
                            color: Colors.grey[600],
                            size: 100,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  child: Text(
                    category['name'],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : Colors.black,
                      height: 1.1,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMarketCard(Map<String, dynamic> market, BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _primaryColor.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: isDarkMode ? Colors.black : Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostsPage(
                categoryId: market['id'], // ✅ إرسال الـ ID بدلاً من الاسم
                categoryName: market['name'],
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                flex: 7,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      market['image'],
                      width: double.infinity,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: Icon(
                            Icons.image_not_supported,
                            color: Colors.grey[600],
                            size: 100,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Text(
                    market['name'],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : Colors.black,
                      height: 1.1,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showVipAdDetails(Map<String, dynamic> ad, BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
          title: Text(
            ad['title'],
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
              fontSize: 16,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 200,
                  child: PageView.builder(
                    itemCount: ad['images'].length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: NetworkImage(ad['images'][index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'الوصف:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontSize: 14,
                  ),
                ),
                Text(
                  ad['description'],
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'السعر: ${ad['price']} دولار',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'الموقع: ${ad['location']}',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('فتح واتساب: ${ad['phone']}')),
                        );
                      },
                      icon: const Icon(
                        Icons.message,
                        color: Colors.white,
                        size: 16,
                      ),
                      label: const Text(
                        'واتساب',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('فتح الدردشة الداخلية')),
                        );
                      },
                      icon: const Icon(
                        Icons.chat,
                        color: Colors.white,
                        size: 16,
                      ),
                      label: const Text(
                        'دردشة',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'إغلاق',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- ✨✨ 2. استدعاء الويدجت الموروث هنا ✨✨ ---
            VipAdsWidget(primaryColor: _primaryColor),

            // الأقسام العلوية الجديدة (اقتراحات وشكاوي - تواصل للإعلانات)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SizedBox(
                height: 100,
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTopCategoryCard(_topCategories[1], context),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildTopCategoryCard(_topCategories[0], context),
                    ),
                  ],
                ),
              ),
            ),

            // الأقسام الأربعة الرئيسية
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: Column(
                children: [
                  Text(
                    'الأقسام الرئيسية',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : _primaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 2,
                      mainAxisSpacing: 2,
                      childAspectRatio: 0.7,
                    ),
                    itemCount: _mainCategories.length,
                    itemBuilder: (context, index) {
                      return _buildMainCategoryCard(
                        _mainCategories[index],
                        context,
                      );
                    },
                  ),
                ],
              ),
            ),

            // قسم الأسواق
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: Column(
                children: [
                  Text(
                    'الأسواق',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : _primaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 2,
                      mainAxisSpacing: 2,
                      childAspectRatio: 0.7,
                    ),
                    itemCount: _markets.length,
                    itemBuilder: (context, index) {
                      return _buildMarketCard(_markets[index], context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _vipAdsController.dispose();
    super.dispose();
  }

  void _showContactDialog(BuildContext context) {
    const phoneNumber = '+44 7950 227398';
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  FontAwesomeIcons.whatsapp,
                  color: Colors.green,
                  size: 60,
                ),
                const SizedBox(height: 12),
                Text(
                  'تواصل عبر واتساب',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'للاقتراحات أو التواصل الإعلاني\nاستخدم الرقم التالي:',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SelectableText(
                        phoneNumber,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, color: Colors.blue),
                        onPressed: () {
                          Clipboard.setData(
                              const ClipboardData(text: phoneNumber));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تم نسخ الرقم'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    final url = Uri.parse(
                        'https://wa.me/${phoneNumber.replaceAll(' ', '').replaceAll('+', '')}');
                    launchUrl(url, mode: LaunchMode.externalApplication);
                  },
                  icon: const Icon(Icons.chat, color: Colors.white),
                  label: const Text('فتح واتساب',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'إغلاق',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
