import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'comments_page.dart';
import 'messages_page.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  final int _notificationsPerPage = 20;
  final ScrollController _scrollController = ScrollController();
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (!_isLoadingMore) {
        _loadMoreNotifications();
      }
    }
  }

  Future<void> _loadNotifications({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _notifications.clear();
        _isLoading = true;
      });
    }

    try {
      final result = await AuthService.getNotifications(
        page: _currentPage,
        limit: _notificationsPerPage,
      );

      if (result['success'] == true) {
        // معالجة مختلفة لهيكل البيانات
        List<Map<String, dynamic>> notifications = [];
        dynamic data = result['data'];

        if (data is List) {
          // إذا كانت البيانات قائمة مباشرة
          notifications = List<Map<String, dynamic>>.from(data);
        } else if (data is Map) {
          // إذا كانت البيانات كائن يحتوي على notifications
          notifications = List<Map<String, dynamic>>.from(
              data['notifications'] ?? data['data'] ?? []);
        }

        setState(() {
          if (refresh || _currentPage == 1) {
            _notifications = notifications;
          } else {
            _notifications.addAll(notifications);
          }

          // حساب عدد الإشعارات غير المقروءة
          if (data is Map) {
            _unreadCount = data['unread_count'] ??
                notifications.where((n) => n['is_read'] != 1).length;
          } else {
            _unreadCount = notifications.where((n) => n['is_read'] != 1).length;
          }

          _isLoading = false;
          _isLoadingMore = false;
        });
      } else {
        // التعامل مع الأخطاء المختلفة
        String errorMessage = result['message'] ?? 'خطأ في تحميل الإشعارات';

        // التحقق من كود الخطأ 404
        if (result['status_code'] == 404 || errorMessage.contains('404')) {
          errorMessage =
              'لم يتم العثور على إشعارات. قد تحتاج إلى إعداد نظام الإشعارات في الخادم.';
        }

        _showErrorMessage(errorMessage);
      }
    } catch (e) {
      String errorMsg = 'خطأ في تحميل الإشعارات: $e';

      // التعامل مع أخطاء الشبكة الشائعة
      if (e.toString().contains('404')) {
        errorMsg = 'نقطة نهاية الإشعارات غير متوفرة في الخادم (404)';
      } else if (e.toString().contains('Connection')) {
        errorMsg = 'خطأ في الاتصال بالخادم';
      }

      _showErrorMessage(errorMsg);
    }
  }

  Future<void> _loadMoreNotifications() async {
    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });
    await _loadNotifications();
  }

  Future<void> _markAllAsRead() async {
    try {
      final result = await AuthService.markNotificationsAsRead();

      if (result['success'] == true) {
        setState(() {
          for (var notification in _notifications) {
            notification['is_read'] = 1;
          }
          _unreadCount = 0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديد جميع الإشعارات كمقروءة')),
        );
      } else {
        _showErrorMessage(result['message'] ?? 'خطأ في تحديث الإشعارات');
      }
    } catch (e) {
      _showErrorMessage('خطأ في تحديث الإشعارات: $e');
    }
  }

  Future<void> _markAsRead(int notificationIndex) async {
    final notification = _notifications[notificationIndex];
    if (notification['is_read'] == 1) return;

    try {
      final result = await AuthService.markNotificationsAsRead(
          notificationIds: [notification['id']]);

      if (result['success'] == true) {
        setState(() {
          _notifications[notificationIndex]['is_read'] = 1;
          if (_unreadCount > 0) _unreadCount--;
        });
      }
    } catch (e) {
      // تجاهل الأخطاء في تحديث حالة القراءة
    }
  }

  void _handleNotificationTap(Map<String, dynamic> notification, int index) {
    _markAsRead(index);

    final type = notification['type'];
    final relatedId = notification['related_id'];
    final relatedType = notification['related_type'];

    switch (type) {
      case 'like_post':
      case 'comment_post':
        if (relatedType == 'post' && relatedId != null) {
          // الانتقال إلى صفحة التعليقات للمنشور
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CommentsPage(
                postId: relatedId,
                postTitle: 'منشور',
              ),
            ),
          );
        }
        break;
      case 'like_comment':
      case 'reply_comment':
        if (relatedType == 'comment' && relatedId != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('الانتقال إلى التعليق')),
          );
        }
        break;
      case 'new_message':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MessagesPage()),
        );
        break;
      case 'system':
      case 'report_response':
      default:
        // إشعار نظام - لا حاجة لإجراء خاص
        break;
    }
  }

  void _showErrorMessage(String message) {
    if (mounted) {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification, int index) {
    final bool isUnread = notification['is_read'] != 1;
    final String type = notification['type'] ?? '';

    IconData icon;
    Color iconColor;

    switch (type) {
      case 'like_post':
      case 'like_comment':
        icon = Icons.favorite;
        iconColor = Colors.red;
        break;
      case 'comment_post':
      case 'reply_comment':
        icon = Icons.comment;
        iconColor = Colors.blue;
        break;
      case 'new_message':
        icon = Icons.message;
        iconColor = Colors.green;
        break;
      case 'report_response':
        icon = Icons.admin_panel_settings;
        iconColor = Colors.purple;
        break;
      case 'system':
      default:
        icon = Icons.info;
        iconColor = Colors.orange;
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: isUnread ? 3 : 1,
      color: isUnread ? Colors.blue.shade50 : Colors.white,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          notification['title'] ?? '',
          style: TextStyle(
            fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification['content'] ?? '',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatDate(notification['created_at']),
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        trailing: isUnread
            ? Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              )
            : null,
        onTap: () => _handleNotificationTap(notification, index),
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';

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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              const Text('الإشعارات'),
              if (_unreadCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$_unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          actions: [
            if (_unreadCount > 0)
              IconButton(
                icon: const Icon(Icons.done_all),
                onPressed: _markAllAsRead,
                tooltip: 'تحديد الكل كمقروء',
              ),
          ],
        ),
        body: _isLoading && _notifications.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('جاري تحميل الإشعارات...'),
                  ],
                ),
              )
            : _notifications.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_none,
                            size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'لا توجد إشعارات',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'ستظهر إشعاراتك هنا عند وصولها',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => _loadNotifications(refresh: true),
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount:
                          _notifications.length + (_isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _notifications.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        return _buildNotificationCard(
                            _notifications[index], index);
                      },
                    ),
                  ),
      ),
    );
  }
}
