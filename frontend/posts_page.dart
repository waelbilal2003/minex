import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';
import 'create_post_page.dart';
import 'post_card_widget.dart'; // <-- ✨ إضافة مهمة
import 'dart:convert';

class PostsPage extends StatefulWidget {
  final String category;
  final String categoryName;

  const PostsPage({
    Key? key,
    required this.category, // ✅ تعديل هنا
    required this.categoryName,
  }) : super(key: key);
  @override
  _PostsPageState createState() => _PostsPageState();
}

// أضف هذا المكون هنا (نفس الموجود في الصفحة الرئيسية)
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
    _controlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _controller!.value.isPlaying) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _seekForward() {
    final newPosition =
        _controller!.value.position + const Duration(seconds: 10);
    if (newPosition < _controller!.value.duration) {
      _controller!.seekTo(newPosition);
    }
  }

  void _seekBackward() {
    final newPosition =
        _controller!.value.position - const Duration(seconds: 10);
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
              const Icon(Icons.error, color: Colors.white, size: 40),
              const SizedBox(height: 8),
              const Text(
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
        child:
            const Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return GestureDetector(
      onTap: _togglePlayPause,
      onDoubleTap: _seekForward,
      onLongPress: _seekBackward,
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: _controller!.value.aspectRatio,
            child: VideoPlayer(_controller!),
          ),
          if (_showControls)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _controller!.value.isPlaying
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_filled,
                      color: Colors.white,
                      size: 50,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.replay_10,
                            color: Colors.white,
                            size: 30,
                          ),
                          onPressed: _seekBackward,
                        ),
                        IconButton(
                          icon: const Icon(
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
                colors: const VideoProgressColors(
                  playedColor: Colors.red,
                  bufferedColor: Colors.grey,
                  backgroundColor: Colors.grey,
                ),
              ),
            ),
          ),
          if (_showControls)
            Positioned(
              bottom: 8,
              left: 8,
              child: Text(
                '${_formatDuration(_controller!.value.position)} / ${_formatDuration(_controller!.value.duration)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
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
          if (_controller!.value.isBuffering)
            const Positioned.fill(
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

class _PostsPageState extends State<PostsPage> {
  List<Map<String, dynamic>> _filteredPosts = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchPosts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        _hasMore &&
        !_isLoadingMore) {
      _loadMorePosts();
    }
  }

  Future<void> _fetchPosts({bool refresh = false}) async {
    if (refresh) {
      if (!mounted) return;
      setState(() {
        _currentPage = 1;
        _filteredPosts.clear();
        _isLoading = true;
        _hasMore = true;
      });
    }

    try {
      print('📊 جلب المنشورات للقسم: ${widget.category}');
      // ✅ جلب المنشورات حسب التصنيف
      final result = await AuthService.getPostsByCategory(
        widget.category, // ✅ نمرر اسم الفئة النصي مباشرة
        page: _currentPage,
      );
      if (!mounted) return;

      // --- ✅ معالجة مرنة لصيغة البيانات القادمة من السيرفر ---
      List<dynamic>? postsList;

      if (result['data'] is Map && result['data']['posts'] is List) {
        postsList = result['data']['posts'];
      } else if (result['data'] is List) {
        // إذا كانت الاستجابة نفسها قائمة بدون 'posts'
        postsList = result['data'];
      } else if (result['data'] is String) {
        // إذا أرسل السيرفر نص JSON بدلاً من Map
        try {
          final decoded = json.decode(result['data']);
          if (decoded is List) postsList = decoded;
          if (decoded is Map && decoded['posts'] is List) {
            postsList = decoded['posts'];
          }
        } catch (e) {
          print('❌ فشل تحليل data كنص JSON: $e');
        }
      }

      if (postsList == null) {
        _showErrorMessage(
            result['message'] ?? 'لم يتم العثور على بيانات منشورات');
        return;
      }

      // ✅ الآن نحللها بشكل آمن
      final newPosts = List<Map<String, dynamic>>.from(postsList);

      final processedNewPosts = newPosts.map((post) {
        // 1. إصلاح معالجة الصور: التعامل مع قائمة النصوص مباشرة
        List<String> images = (post['images'] as List<dynamic>?)
                ?.map((imageUrl) => imageUrl.toString())
                .toList() ??
            [];

        // 2. إصلاح معالجة الفيديو
        String? videoUrl =
            post['video'] != null && post['video']['video_path'] != null
                ? post['video']['video_path']
                : null;

        // 3. معلومات المستخدم
        String userName = post['user']?['full_name'] ?? 'مستخدم';
        int userId = post['user']?['id'] ?? -1;

        return {
          'id': post['id'],
          'user_id': userId,
          'user_name': userName,
          'user_avatar':
              'https://via.placeholder.com/50x50/cccccc/ffffff?text=${userName.isNotEmpty ? userName.substring(0, 1) : 'U'}',
          'content': post['content'] ?? '',
          'title': post['title'] ?? '',
          'category': post['category'] ?? '',
          'price': post['price']?.toString(),
          'location': post['location'],
          'images': images,
          'video_url': videoUrl,
          'likes_count': post['likes_count'] ?? 0,
          'comments_count': post['comments_count'] ?? 0,
          'created_at': post['created_at'],
          'isLiked': post['is_liked_by_user'] ?? false,
          'gender': post['user']?['gender'],
          'user_type': post['user']?['user_type'] ?? 'person',
        };
      }).toList();

      if (mounted) {
        setState(() {
          if (refresh || _currentPage == 1) {
            _filteredPosts = processedNewPosts;
          } else {
            _filteredPosts.addAll(processedNewPosts);
          }
          _hasMore = newPosts.isNotEmpty;
        });
      }
    } catch (e) {
      print("Error fetching posts by category: $e");
      _showErrorMessage("حدث خطأ أثناء الاتصال بالخادم: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _loadMorePosts() async {
    if (!_hasMore || _isLoadingMore) return;
    setState(() {
      _isLoadingMore = true;
    });
    _currentPage++;
    await _fetchPosts();
  }

  void _showErrorMessage(String message) {
    if (mounted) {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  // --- ✨ تم حذف دوال: _buildPostCard, _buildMediaWidget, _buildImagesWidget, _deletePost, _showReportDialog, _getImageUrl
  // --- لأن PostCardWidget تقوم بكل هذا الآن.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading && _filteredPosts.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('جاري تحميل المنشورات...'),
                ],
              ),
            )
          : _filteredPosts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.post_add, size: 80, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'لا توجد منشورات في هذا القسم',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => _fetchPosts(refresh: true),
                        child: const Text('إعادة تحميل'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => _fetchPosts(refresh: true),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: InkWell(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => CreatePostPage()),
                            );
                            await _fetchPosts(refresh: true);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.grey[800]!
                                  : Colors.grey[200]!,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.grey[600]!
                                    : Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Colors.grey[300],
                                  child: Text(
                                    (AuthService.currentUser?['full_name'] ??
                                            'مستخدم')
                                        .substring(0, 1),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'بم تفكر...',
                                    style: TextStyle(
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.grey[400]!
                                          : Colors.grey[600]!,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                Icon(Icons.image,
                                    color: Theme.of(context).primaryColor),
                                const SizedBox(width: 8),
                                Icon(Icons.video_call,
                                    color: Theme.of(context).primaryColor),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          controller: _scrollController,
                          // ✨ تم تقليل padding هنا ليتناسب مع الـ margin الخاص بالـ Card
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          itemCount: _filteredPosts.length + (_hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _filteredPosts.length) {
                              return _isLoadingMore
                                  ? const Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    )
                                  : const SizedBox.shrink();
                            }
                            // --- ✨ هنا التغيير الجوهري ---
                            // نستخدم الآن الويدجت الموحدة بدلاً من الكود المكرر
                            return PostCardWidget(
                              post: _filteredPosts[index],
                              onDelete: () {
                                setState(() {
                                  _filteredPosts.removeWhere((p) =>
                                      p['id'] == _filteredPosts[index]['id']);
                                });
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
