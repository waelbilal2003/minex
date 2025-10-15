import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:intl/intl.dart';
import 'auth_service.dart';
import 'dart:convert';

class VipAdDetailsPage extends StatefulWidget {
  final Map<String, dynamic> adData;

  const VipAdDetailsPage({Key? key, required this.adData}) : super(key: key);

  @override
  _VipAdDetailsPageState createState() => _VipAdDetailsPageState();
}

class _VipAdDetailsPageState extends State<VipAdDetailsPage> {
  late final List<String> _allMedia;
  int _currentMediaIndex = 0;
  PageController? _mediaController;
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();

    // ✅ طباعة البيانات الكاملة للتحقق منها
    print('📊 بيانات الإعلان الكاملة:');
    print(json.encode(widget.adData));

    _allMedia = _getAllMedia();

    print('📸 الوسائط المستخرجة: $_allMedia');

    if (_allMedia.isNotEmpty) {
      _mediaController = PageController();
      if (_isVideoFile(_allMedia.first)) {
        _initializeVideoController(_allMedia.first);
      }
    }
  }

  @override
  void dispose() {
    _mediaController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  List<String> _getAllMedia() {
    final adData = widget.adData;
    final mediaSet = <String>{};

    void addPath(dynamic path) {
      if (path is String && path.isNotEmpty && path != 'null') {
        final fullUrl = _getFullUrl(path);
        print('➕ إضافة وسائط: $fullUrl');
        mediaSet.add(fullUrl);
      }
    }

    // ✅ إضافة صورة الغلاف
    addPath(adData['cover_image_url']);
    addPath(adData['image']);
    addPath(adData['cover_image']);

    void processMediaList(dynamic mediaData, String fieldName) {
      print('🔍 معالجة حقل: $fieldName');
      print('   النوع: ${mediaData.runtimeType}');
      print('   القيمة الخام: $mediaData');

      if (mediaData == null) {
        print('   ⚠️ الحقل null');
        return;
      }

      List<dynamic> parsedList = [];

      if (mediaData is List) {
        parsedList = mediaData;
      } else if (mediaData is String) {
        final trimmed = mediaData.trim();

        if (trimmed.isEmpty || trimmed == '[]' || trimmed == 'null') {
          print('   ⚠️ الحقل فارغ أو null');
          return;
        }

        // محاولة فك JSON
        if (trimmed.startsWith('[') || trimmed.startsWith('{')) {
          try {
            final decoded = json.decode(trimmed);
            if (decoded is List) {
              parsedList = decoded;
            } else if (decoded is Map && decoded.containsKey('media_files')) {
              // إذا كان JSON يحتوي على media_files
              parsedList = decoded['media_files'] ?? [];
            }
          } catch (e) {
            print('   ❌ فشل فك JSON: $e');
            // محاولة معاملة كمسار مفرد
            if (!trimmed.contains(',') && !trimmed.contains('[')) {
              addPath(trimmed);
            }
            return;
          }
        } else {
          // مسار مباشر أو قائمة مفصولة بفواصل
          if (trimmed.contains(',')) {
            parsedList = trimmed
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList();
          } else {
            addPath(trimmed);
            return;
          }
        }
      }

      print('   ✅ تم استخراج ${parsedList.length} عنصر');
      for (var i = 0; i < parsedList.length; i++) {
        print('   [$i]: ${parsedList[i]}');
        if (parsedList[i] is Map) {
          // إذا كان العنصر Map، ابحث عن المسار
          final item = parsedList[i] as Map;
          addPath(item['url'] ??
              item['path'] ??
              item['file_path'] ??
              item.toString());
        } else {
          addPath(parsedList[i]);
        }
      }
    }

    // ✅ معالجة جميع الحقول الممكنة
    processMediaList(adData['media_files'], 'media_files');
    processMediaList(adData['images'], 'images');
    processMediaList(adData['media'], 'media');

    // معالجة حقول إضافية محتملة
    processMediaList(adData['attachments'], 'attachments');
    processMediaList(adData['files'], 'files');

    print('📋 إجمالي الوسائط: ${mediaSet.length}');
    return mediaSet.toList();
  }

  String _getFullUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path.replaceAll(r'\/', '/');
    }

    // إزالة أي شرطات مائلة زائدة
    String cleanPath = path;
    if (cleanPath.startsWith('/')) {
      cleanPath = cleanPath.substring(1);
    }

    final fullUrl = '${AuthService.baseUrl}/$cleanPath';
    print('🔗 تحويل المسار: $path -> $fullUrl');
    return fullUrl;
  }

  bool _isVideoFile(String url) {
    final extension = url.split('?').first.split('.').last.toLowerCase();
    return ['mp4', 'mov', 'avi', 'mkv', '3gp', 'webm'].contains(extension);
  }

  void _initializeVideoController(String videoUrl) {
    _videoController?.dispose();
    _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {});
          _videoController?.play();
          _videoController?.setLooping(true);
        }
      }).catchError((error) {
        print('❌ خطأ في تحميل الفيديو: $error');
      });
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

  // ✅ دالة للحصول على قيمة الحقل بطرق متعددة
  dynamic _getFieldValue(String fieldName, [List<String>? alternatives]) {
    final adData = widget.adData;

    // البحث بالاسم الأساسي
    if (adData.containsKey(fieldName) && adData[fieldName] != null) {
      return adData[fieldName];
    }

    // البحث في البدائل
    if (alternatives != null) {
      for (var alt in alternatives) {
        if (adData.containsKey(alt) && adData[alt] != null) {
          return adData[alt];
        }
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final adData = widget.adData;

    // ✅ استخراج البيانات بطريقة آمنة
    final contactPhone =
        _getFieldValue('contact_phone', ['phone', 'contact_number']);
    final contactWhatsapp =
        _getFieldValue('contact_whatsapp', ['whatsapp', 'whatsapp_number']);
    final pricePaid = _getFieldValue('price_paid', ['price', 'amount']);
    final currency = _getFieldValue('currency');

    print('📞 معلومات الاتصال:');
    print('   الهاتف: $contactPhone');
    print('   واتساب: $contactWhatsapp');
    print('   السعر: $pricePaid $currency');

    return Scaffold(
      appBar: AppBar(
        title: Text(adData['title'] ?? 'تفاصيل الإعلان'),
        backgroundColor: Colors.amber[600],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMediaViewer(),
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    adData['title'] ?? 'لا يوجد عنوان',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),

                  if (adData['description'] != null &&
                      adData['description'].toString().isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'الوصف:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          adData['description'].toString(),
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 16),
                      ],
                    ),

                  // ✅ عرض السعر فقط إذا كان موجوداً
                  if (pricePaid != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: [
                          Icon(Icons.attach_money, color: Colors.green),
                          SizedBox(width: 4),
                          Text(
                            'السعر المدفوع: ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '$pricePaid $currency',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // ✅ عرض معلومات الاتصال فقط إذا كانت موجودة
            if (contactPhone != null || contactWhatsapp != null)
              _buildContactInfo(contactPhone, contactWhatsapp),

            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaViewer() {
    if (_allMedia.isEmpty) {
      return Container(
        height: 300,
        color: Colors.grey[200],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_not_supported,
                  size: 60, color: Colors.grey[400]),
              SizedBox(height: 8),
              Text(
                'لا توجد وسائط',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 300,
      color: Colors.black,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PageView.builder(
            controller: _mediaController,
            itemCount: _allMedia.length,
            onPageChanged: (index) {
              setState(() => _currentMediaIndex = index);
              final newMediaUrl = _allMedia[index];
              if (_isVideoFile(newMediaUrl)) {
                _initializeVideoController(newMediaUrl);
              } else {
                _videoController?.pause();
              }
            },
            itemBuilder: (context, index) {
              final mediaUrl = _allMedia[index];
              Widget mediaContent;

              if (index == _currentMediaIndex &&
                  _isVideoFile(mediaUrl) &&
                  _videoController?.value.isInitialized == true) {
                mediaContent = Center(
                  child: AspectRatio(
                    aspectRatio: _videoController!.value.aspectRatio,
                    child: VideoPlayer(_videoController!),
                  ),
                );
              } else {
                mediaContent = CachedNetworkImage(
                  imageUrl: mediaUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) =>
                      const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) {
                    print('❌ خطأ في تحميل الصورة: $url');
                    print('   الخطأ: $error');
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 40),
                        SizedBox(height: 8),
                        Text(
                          'فشل تحميل الصورة',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    );
                  },
                );
              }

              return GestureDetector(
                onTap: () {
                  _videoController?.pause();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => _FullScreenMediaViewer(
                        mediaFiles: _allMedia,
                        initialIndex: index,
                      ),
                    ),
                  );
                },
                child: mediaContent,
              );
            },
          ),
          if (_videoController?.value.isInitialized == true &&
              !_videoController!.value.isPlaying)
            Center(
              child: Icon(Icons.play_circle_outline,
                  color: Colors.white70, size: 60),
            ),
          _buildMediaIndicator(_allMedia.length, _currentMediaIndex),
        ],
      ),
    );
  }

  Widget _buildContactInfo(dynamic contactPhone, dynamic contactWhatsapp) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'معلومات التواصل',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800]),
            ),
            const SizedBox(height: 12),
            if (contactPhone != null && contactPhone.toString().isNotEmpty)
              ListTile(
                leading: const Icon(Icons.phone, color: Colors.green),
                title: const Text('هاتف التواصل'),
                subtitle: Text(contactPhone.toString()),
              ),
            if (contactWhatsapp != null &&
                contactWhatsapp.toString().isNotEmpty)
              ListTile(
                leading: const Icon(Icons.message, color: Colors.green),
                title: const Text('واتساب'),
                subtitle: Text(contactWhatsapp.toString()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaIndicator(int length, int currentIndex) {
    if (length <= 1) return const SizedBox.shrink();
    return Positioned(
      bottom: 10,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(length, (index) {
          return Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: currentIndex == index ? Colors.white : Colors.white54,
            ),
          );
        }),
      ),
    );
  }
}

// Full screen viewer remains the same
class _FullScreenMediaViewer extends StatefulWidget {
  final List<String> mediaFiles;
  final int initialIndex;

  const _FullScreenMediaViewer({
    required this.mediaFiles,
    required this.initialIndex,
  });

  @override
  _FullScreenMediaViewerState createState() => _FullScreenMediaViewerState();
}

class _FullScreenMediaViewerState extends State<_FullScreenMediaViewer> {
  late final PageController _pageController;
  VideoPlayerController? _videoController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _initializeControllerForPage(_currentIndex);
  }

  void _initializeControllerForPage(int index) {
    _videoController?.dispose();
    _videoController = null;

    final mediaUrl = widget.mediaFiles[index];
    if (_isVideoFile(mediaUrl)) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(mediaUrl))
        ..initialize().then((_) {
          if (mounted) {
            setState(() {});
            _videoController?.play();
            _videoController?.setLooping(true);
          }
        });
    }
  }

  bool _isVideoFile(String url) {
    final extension = url.split('?').first.split('.').last.toLowerCase();
    return ['mp4', 'mov', 'avi', 'mkv', '3gp', 'webm'].contains(extension);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  void _toggleVideoPlay() {
    if (_videoController?.value.isInitialized ?? false) {
      setState(() {
        if (_videoController!.value.isPlaying) {
          _videoController!.pause();
        } else {
          _videoController!.play();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PhotoViewGallery.builder(
            pageController: _pageController,
            itemCount: widget.mediaFiles.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
              _initializeControllerForPage(index);
            },
            builder: (context, index) {
              final mediaUrl = widget.mediaFiles[index];
              if (_isVideoFile(mediaUrl) &&
                  _videoController != null &&
                  _videoController!.value.isInitialized) {
                return PhotoViewGalleryPageOptions.customChild(
                  child: GestureDetector(
                    onTap: _toggleVideoPlay,
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: _videoController!.value.aspectRatio,
                        child: VideoPlayer(_videoController!),
                      ),
                    ),
                  ),
                  heroAttributes:
                      PhotoViewHeroAttributes(tag: mediaUrl + index.toString()),
                );
              } else {
                return PhotoViewGalleryPageOptions(
                  imageProvider: CachedNetworkImageProvider(mediaUrl),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 2.5,
                  heroAttributes:
                      PhotoViewHeroAttributes(tag: mediaUrl + index.toString()),
                );
              }
            },
            loadingBuilder: (context, event) =>
                const Center(child: CircularProgressIndicator()),
            backgroundDecoration: const BoxDecoration(color: Colors.black),
          ),
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          if (widget.mediaFiles.length > 1)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.mediaFiles.length, (index) {
                  return Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentIndex == index
                          ? Colors.white
                          : Colors.white54,
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}
