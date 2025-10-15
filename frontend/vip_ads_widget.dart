// lib/vip_ads_widget.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import 'auth_service.dart';
import 'vip_ad_details_page.dart';

class VipAdsWidget extends StatefulWidget {
  final Color primaryColor;

  const VipAdsWidget({
    Key? key,
    required this.primaryColor,
  }) : super(key: key);

  @override
  _VipAdsWidgetState createState() => _VipAdsWidgetState();
}

class _VipAdsWidgetState extends State<VipAdsWidget> {
  final PageController _vipAdsController = PageController();
  int _currentVipAdIndex = 0;
  List<Map<String, dynamic>> _vipAds = [];
  bool _isLoading = true;
  Timer? _scrollTimer;

  @override
  void initState() {
    super.initState();
    _fetchVipAds();
  }

  @override
  void dispose() {
    _vipAdsController.dispose();
    _scrollTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchVipAds() async {
    if (!mounted) return;
    try {
      final result = await AuthService.getVipAdsForDisplay();
      if (mounted) {
        if (result['success'] == true) {
          final adsData = List<Map<String, dynamic>>.from(result['data'] ?? []);
          setState(() {
            _vipAds = adsData;
            _isLoading = false;
          });
          if (adsData.isNotEmpty) {
            _startVipAdsAutoScroll();
          }
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        print("Error fetching VIP ads: $e");
      }
    }
  }

  void _startVipAdsAutoScroll() {
    _scrollTimer?.cancel();
    _scrollTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_vipAdsController.hasClients && mounted && _vipAds.isNotEmpty) {
        _currentVipAdIndex = (_currentVipAdIndex + 1) % _vipAds.length;
        _vipAdsController.animateToPage(
          _currentVipAdIndex,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  // --- ✨✨ بداية الإصلاح الشامل ✨✨ ---
  // دالة آمنة ومضمونة لبناء الروابط
  String _getFullImageUrl(String path) {
    // إذا كان الرابط كاملاً بالفعل، قم بإعادته مباشرةً
    if (path.startsWith('http')) {
      return path;
    }
    // استخدم `Uri.resolve` لدمج الروابط بشكل صحيح وآمن
    // هذه الطريقة تعالج تلقائيًا مشكلة الشرطة المائلة المزدوجة أو المفقودة
    return Uri.parse(AuthService.baseUrl).resolve(path).toString();
  }
  // --- ✨✨ نهاية الإصلاح الشامل ✨✨ ---

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _vipAds.isEmpty
              ? Center(
                  child: Text(
                    'لا توجد إعلانات VIP حالياً.',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                )
              : Column(
                  children: [
                    const SizedBox(height: 8),
                    Expanded(
                      child: PageView.builder(
                        controller: _vipAdsController,
                        itemCount: _vipAds.length,
                        onPageChanged: (index) {
                          setState(() {
                            _currentVipAdIndex = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          return _buildVipAdCard(_vipAds[index]);
                        },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _vipAds.asMap().entries.map((entry) {
                        return Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentVipAdIndex == entry.key
                                ? widget.primaryColor
                                : Colors.grey,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
    );
  }

  Widget _buildVipAdCard(Map<String, dynamic> ad) {
    final String? imageUrl =
        ad['cover_image_url'] ?? ad['image'] ?? ad['cover_image'];
    final String? title = ad['title']?.toString();

    // ✨ استخدام الدالة الجديدة الآمنة لبناء الرابط ✨
    final String fullImageUrl =
        imageUrl != null ? _getFullImageUrl(imageUrl) : '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.primaryColor, width: 2),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VipAdDetailsPage(adData: ad),
            ),
          );
        },
        borderRadius: BorderRadius.circular(10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (fullImageUrl.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: fullImageUrl, // ✨ استخدام الرابط الصحيح
                  fit: BoxFit.cover,
                  placeholder: (c, u) => Container(color: Colors.grey[200]),
                  errorWidget: (c, u, e) => const Center(
                      child: Icon(Icons.broken_image,
                          size: 48, color: Colors.grey)),
                )
              else
                Container(
                    color: Colors.grey[200],
                    child: const Center(
                        child: Icon(
                      Icons.image_not_supported,
                      color: Colors.grey,
                    ))),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.8),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Text(
                    title ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      shadows: [Shadow(blurRadius: 2.0, color: Colors.black54)],
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
}
