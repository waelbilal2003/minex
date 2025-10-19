import 'package:flutter/material.dart';
import 'posts_page.dart';
import 'auth_service.dart';
import 'vip_ads_widget.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({Key? key}) : super(key: key);

  @override
  _CategoriesPageState createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final PageController _vipAdsController = PageController();
  String _userGender = 'ذكر'; // افتراضي

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
    {'id': 1, 'name': 'التوظيف', 'image': 'assets/images/job.png'},
    {'id': 2, 'name': 'المناقصات', 'image': 'assets/images/tenders.png'},
    {'id': 3, 'name': 'الموردين', 'image': 'assets/images/suppliers.png'},
    {
      'id': 4,
      'name': 'العروض العامة',
      'image': 'assets/images/general_offers.png'
    },
  ];

  final List<Map<String, dynamic>> _markets = [
    {'id': 5, 'name': 'السيارات', 'image': 'assets/images/cars.png'},
    {
      'id': 6,
      'name': 'الدراجات النارية',
      'image': 'assets/images/motorcycles.png'
    },
    {
      'id': 7,
      'name': 'تجارة العقارات',
      'image': 'assets/images/real_estate.png'
    },
    {
      'id': 8,
      'name': 'المستلزمات العسكرية',
      'image': 'assets/images/weapons.png'
    },
    {
      'id': 9,
      'name': 'الهواتف والالكترونيات',
      'image': 'assets/images/electronics.png'
    },
    {
      'id': 10,
      'name': 'الأدوات الكهربائية',
      'image': 'assets/images/electrical.png'
    },
    {
      'id': 11,
      'name': 'ايجار العقارات',
      'image': 'assets/images/house_rent.png'
    },
    {
      'id': 12,
      'name': 'الثمار والحبوب',
      'image': 'assets/images/agriculture.png'
    },
    {'id': 13, 'name': 'المواد الغذائية', 'image': 'assets/images/food.webp'},
    {'id': 14, 'name': 'المطاعم', 'image': 'assets/images/restaurants.webp'},
    {'id': 15, 'name': 'مواد التدفئة', 'image': 'assets/images/heating.png'},
    {
      'id': 16,
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
          // ✨ --- بداية التعديل --- ✨
          // تأكد من أن الأقسام العلوية لها وظيفة محددة أو صفحة خاصة بها
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostsPage(
                categoryId: category['id'], // ✅ الرقم التعريفي
                categoryName: category['name'],
              ),
            ),
          );
          // ✨ --- نهاية التعديل --- ✨
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
          // --- ✨ بداية التعديل هنا ✨ ---
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostsPage(
                // تم إرسال الرقم التعريفي الصحيح
                categoryId: category['id'],
                // تم إرسال الاسم لعرضه في شريط العنوان
                categoryName: category['name'],
              ),
            ),
          );
          // --- نهاية التعديل هنا ---
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
          // --- ✨ بداية التعديل هنا ✨ ---
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostsPage(
                // تم إرسال الرقم التعريفي الصحيح
                categoryId: market['id'],
                // تم إرسال الاسم لعرضه في شريط العنوان
                categoryName: market['name'],
              ),
            ),
          );
          // --- نهاية التعديل هنا ---
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
}
