import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auth_service.dart';
import 'user_profile_page.dart';

class CommentsPage extends StatefulWidget {
  final int postId;
  final String postTitle;

  const CommentsPage({
    Key? key,
    required this.postId,
    required this.postTitle,
  }) : super(key: key);

  @override
  _CommentsPageState createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
  List<Map<String, dynamic>> _comments = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;
  int? _replyingToCommentId;
  String? _replyingToUserName;
  bool _hasAddedComment = false; // ✅ متغير لتتبع إضافة التعليقات

  @override
  void initState() {
    super.initState();
    _loadComments();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (!_isLoadingMore) {
        _loadMoreComments();
      }
    }
  }

  Future<void> _loadComments({bool refresh = false}) async {
    if (refresh) {
      if (!mounted) return;
      setState(() {
        _currentPage = 1;
        _comments.clear();
        _isLoading = true;
      });
    }

    try {
      // 1. استخدام الرابط الصحيح من Postman
      // ❗️ ملاحظة: Postman لا يدعم الترقيم (pagination)، لذا تم حذف page و limit
      // يجب على مطورة الـ Backend إضافتها لاحقاً إذا أردتم تحميل المزيد من التعليقات.
      final token = await AuthService.getToken();
      final response = await http.get(
        Uri.parse(
            '${AuthService.baseUrl}/api/comments?post_id=${widget.postId}'),
        headers: AuthService.getHeaders(token),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true && data['comments'] is List) {
          final commentsData =
              List<Map<String, dynamic>>.from(data['comments']);
          setState(() {
            if (refresh || _currentPage == 1) {
              _comments = commentsData;
            } else {
              _comments.addAll(commentsData);
            }
          });
        } else {
          _showErrorMessage(data['message'] ?? 'فشل تحميل التعليقات');
        }
      } else {
        _showErrorMessage('خطأ في الاتصال بالخادم: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading comments: $e');
      _showErrorMessage('حدث خطأ غير متوقع: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _loadMoreComments() async {
    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });
    await _loadComments();
  }

  Future<void> _addComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      final result = await AuthService.addComment(
        postId: widget.postId,
        content: content,
        parentCommentId: _replyingToCommentId,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        // تنظيف النموذج
        _commentController.clear();
        _cancelReply();

        // ✅ تحديد أنه تم إضافة تعليق
        _hasAddedComment = true;

        // إعادة تحميل التعليقات
        await _loadComments(refresh: true);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إضافة التعليق بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _showErrorMessage(result['message'] ?? 'فشل إضافة التعليق');
      }
    } catch (e) {
      _showErrorMessage('حدث خطأ غير متوقع: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _toggleCommentLike(int commentIndex, {int? replyIndex}) async {
    // ❗️ ملاحظة: الردود غير مدعومة في الـ API، هذا الجزء سيعمل فقط على التعليقات الرئيسية.
    final comment = _comments[commentIndex];
    final commentId = comment['id'];
    final bool currentLikedStatus = comment['user_liked'] ?? false;
    final int currentLikesCount = comment['likes_count'] ?? 0;

    // 1. تحديث الواجهة فورًا لتحسين تجربة المستخدم
    setState(() {
      _comments[commentIndex]['user_liked'] = !currentLikedStatus;
      _comments[commentIndex]['likes_count'] =
          currentLikedStatus ? currentLikesCount - 1 : currentLikesCount + 1;
    });

    try {
      final token = await AuthService.getToken();
      // 2. استخدام الرابط الصحيح وإرسال البيانات كـ form-data
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/api/comments/toggle-like'),
        headers: AuthService.getHeaders(token),
        body: {'comment_id': commentId.toString()}, // إرسال كـ form-data
      );

      final data = json.decode(response.body);

      // 3. إذا فشل الطلب، يتم التراجع عن التغيير في الواجهة
      if (response.statusCode != 200 || data['success'] != true) {
        _showErrorMessage(data['message'] ?? 'فشل تحديث الإعجاب');
        setState(() {
          _comments[commentIndex]['user_liked'] = currentLikedStatus;
          _comments[commentIndex]['likes_count'] = currentLikesCount;
        });
      }
      // إذا نجح، لا نفعل شيئًا لأن الواجهة محدثة بالفعل
    } catch (e) {
      print('Error toggling like: $e');
      _showErrorMessage('حدث خطأ غير متوقع: $e');
      // التراجع عن التغيير في حال حدوث خطأ
      setState(() {
        _comments[commentIndex]['user_liked'] = currentLikedStatus;
        _comments[commentIndex]['likes_count'] = currentLikesCount;
      });
    }
  }

  void _replyToComment(int commentId, String userName) {
    setState(() {
      _replyingToCommentId = commentId;
      _replyingToUserName = userName;
    });
    // التركيز على حقل النص
    FocusScope.of(context).requestFocus(FocusNode());
  }

  void _cancelReply() {
    setState(() {
      _replyingToCommentId = null;
      _replyingToUserName = null;
    });
  }

  void _showErrorMessage(String message) {
    if (mounted) {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Widget _buildCommentCard(Map<String, dynamic> comment, int index,
      {bool isReply = false}) {
    // التأكد من أن البيانات ليست null مع قيم افتراضية
    final userName = comment['user_name'] ?? 'مستخدم';
    final content = comment['content'] ?? '';
    final createdAt = comment['created_at'] ?? '';
    final likesCount = comment['likes_count'] ?? 0;
    final repliesCount = comment['replies_count'] ?? 0;
    final userLiked = comment['user_liked'] ?? false;

    // --- ✨ بداية التعديل ---
    // استخراج آمن لمعرف المستخدم
    final userId = comment['user_id'] is int
        ? comment['user_id']
        : int.tryParse(comment['user_id'].toString()) ?? -1;

    final userGenderValue =
        (comment['user_gender'] ?? '').toString().toLowerCase();
    final bool isMale = userGenderValue == 'ذكر' ||
        userGenderValue == 'male' ||
        userGenderValue == 'm';
    // --- نهاية التعديل ---

    return Container(
      margin: EdgeInsets.only(
        right: isReply ? 40 : 16,
        left: 16,
        top: 8,
        bottom: 8,
      ),
      child: Card(
        elevation: isReply ? 1 : 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // معلومات المستخدم
              Row(
                children: [
                  // --- ✨ تعديل: إضافة GestureDetector للصورة ---
                  GestureDetector(
                    onTap: () => _navigateToUserProfile(userId, userName),
                    child: CircleAvatar(
                      radius: isReply ? 16 : 20,
                      backgroundColor: isMale ? Colors.blue : Colors.pink,
                      child: Icon(
                        isMale ? Icons.man : Icons.woman,
                        color: Colors.white,
                        size: isReply ? 16 : 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- ✨ تعديل: إضافة GestureDetector للاسم ---
                        GestureDetector(
                          onTap: () => _navigateToUserProfile(userId, userName),
                          child: Text(
                            userName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isReply ? 14 : 16,
                            ),
                          ),
                        ),
                        Text(
                          _formatDate(createdAt),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: isReply ? 10 : 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'report') {
                        // --- ✨ تعديل: تفعيل دالة الإبلاغ ---
                        _showReportDialog(comment);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'report',
                        child: Row(
                          children: [
                            Icon(Icons.report, color: Colors.red, size: 16),
                            SizedBox(width: 8),
                            Text('إبلاغ'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // محتوى التعليق
              Text(
                content,
                style: TextStyle(
                  fontSize: isReply ? 13 : 14,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 8),

              // أزرار الإعجاب والرد
              Row(
                children: [
                  // زر الإعجاب
                  InkWell(
                    onTap: () => _toggleCommentLike(index,
                        replyIndex: isReply
                            ? null
                            : null), // Note: replyIndex logic might need adjustment if you want to like replies specifically
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color:
                            userLiked ? Colors.red.shade50 : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            userLiked ? Icons.favorite : Icons.favorite_border,
                            color: userLiked ? Colors.red : Colors.grey[600],
                            size: isReply ? 14 : 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$likesCount',
                            style: TextStyle(
                              color: userLiked ? Colors.red : Colors.grey[600],
                              fontSize: isReply ? 11 : 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // زر الرد (فقط للتعليقات الرئيسية)
                  if (!isReply)
                    InkWell(
                      onTap: () =>
                          _replyToComment(comment['id'] ?? 0, userName),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.reply, color: Colors.blue, size: 16),
                            SizedBox(width: 4),
                            Text(
                              'رد',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const Spacer(),

                  // عدد الردود (للتعليقات الرئيسية)
                  if (!isReply && repliesCount > 0)
                    Text(
                      '$repliesCount رد',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRepliesList(dynamic replies, int commentIndex) {
    // التأكد من أن الردود ليست null وأنها قائمة
    if (replies == null || replies is! List || replies.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: replies.asMap().entries.map((entry) {
        Map<String, dynamic> reply = entry.value;
        return _buildCommentCard(reply, commentIndex, isReply: true);
      }).toList(),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '';

    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) {
        return 'الآن';
      } else if (difference.inMinutes < 60) {
        return 'منذ ${difference.inMinutes} دقيقة';
      } else if (difference.inHours < 24) {
        return 'منذ ${difference.inHours} ساعة';
      } else if (difference.inDays < 7) {
        return 'منذ ${difference.inDays} يوم';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return dateString;
    }
  }

  void _showReportDialog(Map<String, dynamic> comment) {
    String selectedReason = '';
    String description = '';
    final reasons = [
      'محتوى غير لائق',
      'رسائل مسيئة أو تحرش',
      'معلومات مضللة',
      'محتوى غير مرغوب فيه (سبام)',
      'أخرى',
    ];
    final int commentId = comment['id'];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('إبلاغ عن تعليق'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('لماذا تريد الإبلاغ عن هذا التعليق؟'),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'سبب الإبلاغ',
                        border: OutlineInputBorder(),
                      ),
                      items: reasons
                          .map(
                              (r) => DropdownMenuItem(value: r, child: Text(r)))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => selectedReason = value ?? ''),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'تفاصيل إضافية (اختياري)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      onChanged: (value) => description = value,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: selectedReason.isEmpty
                      ? null
                      : () async {
                          Navigator.pop(context);
                          final result = await AuthService.reportComment(
                            commentId: commentId,
                            reason: selectedReason,
                            description:
                                description.isEmpty ? null : description,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                result['message'] ??
                                    (result['success']
                                        ? 'تم إرسال الإبلاغ بنجاح'
                                        : 'خطأ في الإرسال'),
                              ),
                              backgroundColor:
                                  result['success'] ? Colors.green : Colors.red,
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('إرسال الإبلاغ'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // ✅ إرجاع النتيجة عند العودة من الصفحة
      onWillPop: () async {
        Navigator.of(context).pop(_hasAddedComment);
        return false;
      },
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('التعليقات'),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            // ✅ تحديث زر الرجوع ليرجع النتيجة
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(_hasAddedComment),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => _loadComments(refresh: true),
              ),
            ],
          ),
          body: Column(
            children: [
              // معلومات المنشور
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'المنشور:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.postTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // قائمة التعليقات
              Expanded(
                child: _isLoading && _comments.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('جاري تحميل التعليقات...'),
                          ],
                        ),
                      )
                    : _comments.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.comment_outlined,
                                    size: 80, color: Colors.grey),
                                const SizedBox(height: 16),
                                const Text(
                                  'لا توجد تعليقات بعد',
                                  style: TextStyle(
                                      fontSize: 18, color: Colors.grey),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'كن أول من يعلق!',
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.grey),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () => _loadComments(refresh: true),
                                  child: const Text('تحديث'),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => _loadComments(refresh: true),
                            child: ListView.builder(
                              controller: _scrollController,
                              itemCount:
                                  _comments.length + (_isLoadingMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _comments.length) {
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16),
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }

                                final comment = _comments[index];
                                return Column(
                                  children: [
                                    _buildCommentCard(comment, index),
                                    if (comment['replies'] != null &&
                                        comment['replies'].isNotEmpty)
                                      _buildRepliesList(
                                          comment['replies'], index),
                                  ],
                                );
                              },
                            ),
                          ),
              ),

              // شريط إضافة التعليق
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Colors.grey[300]!)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // شريط الرد (إذا كان المستخدم يرد على تعليق)
                    if (_replyingToCommentId != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.reply,
                                color: Colors.blue, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'الرد على $_replyingToUserName',
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: _cancelReply,
                              child: const Icon(Icons.close,
                                  color: Colors.blue, size: 16),
                            ),
                          ],
                        ),
                      ),

                    // حقل إدخال التعليق
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            decoration: InputDecoration(
                              hintText: _replyingToCommentId != null
                                  ? 'اكتب ردك...'
                                  : 'اكتب تعليقك...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              filled: true,
                              fillColor: Colors.grey[100],
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                            ),
                            maxLines: null,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _addComment(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: _isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : const Icon(Icons.send, color: Colors.white),
                            onPressed: _isSubmitting ? null : _addComment,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToUserProfile(int userId, String userName) {
    if (userId == -1) return; // لا تنتقل إذا كان المعرف غير صالح
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
}
