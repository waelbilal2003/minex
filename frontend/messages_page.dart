import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'package:intl/intl.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({Key? key}) : super(key: key);

  @override
  _MessagesPageState createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final result = await AuthService.getConversations();
      if (mounted) {
        if (result['success'] == true) {
          setState(() {
            _conversations =
                List<Map<String, dynamic>>.from(result['data'] ?? []);
          });
        } else {
          setState(() {
            _error = result['message'] ?? 'فشل تحميل المحادثات';
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'حدث خطأ ما: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openChatPage(Map<String, dynamic> conversation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          conversationId: conversation['conversation_id'],
          otherUserId: conversation['other_user_id'],
          otherUserName: conversation['other_user_name'],
          otherUserGender: conversation['other_user_gender'],
        ),
      ),
    ).then((_) {
      _loadConversations(); // تحديث القائمة عند العودة
    });
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      if (now.difference(date).inDays == 0) return DateFormat.Hm().format(date);
      if (now.difference(date).inDays == 1) return 'الأمس';
      return DateFormat('d/M/yy').format(date);
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الرسائل'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error.isNotEmpty) return Center(child: Text(_error));
    if (_conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.message_outlined, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('لا توجد محادثات بعد',
                style: TextStyle(fontSize: 18, color: Colors.grey[700])),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadConversations,
      child: ListView.builder(
        itemCount: _conversations.length,
        itemBuilder: (context, index) {
          final convo = _conversations[index];
          final bool isUnread = (convo['unread_count'] ?? 0) > 0;
          return Column(
            children: [
              ListTile(
                leading: CircleAvatar(
                  radius: 25,
                  backgroundColor: convo['other_user_gender'] == 'male'
                      ? Colors.blue.shade100
                      : Colors.pink.shade100,
                  child: Text(
                    convo['other_user_name']?.substring(0, 1) ?? 'U',
                    style: TextStyle(
                        color: convo['other_user_gender'] == 'male'
                            ? Colors.blue
                            : Colors.pink,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(convo['other_user_name'] ?? 'مستخدم',
                    style: TextStyle(
                        fontWeight:
                            isUnread ? FontWeight.bold : FontWeight.normal)),
                subtitle: Text(
                  convo['last_message_content'] ?? '...',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: isUnread
                          ? Theme.of(context).textTheme.bodyLarge?.color
                          : Colors.grey),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(_formatDate(convo['last_message_at']),
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                    if (isUnread) ...[
                      SizedBox(height: 4),
                      Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                            color: Colors.blue, shape: BoxShape.circle),
                        child: Text(convo['unread_count'].toString(),
                            style:
                                TextStyle(color: Colors.white, fontSize: 10)),
                      )
                    ]
                  ],
                ),
                onTap: () => _openChatPage(convo),
              ),
              Divider(height: 1, indent: 80),
            ],
          );
        },
      ),
    );
  }
}

// ... ChatPage remains largely the same, but we will refactor its service calls.

class ChatPage extends StatefulWidget {
  final int conversationId;
  final int otherUserId;
  final String otherUserName;
  final String otherUserGender;

  const ChatPage({
    Key? key,
    required this.conversationId,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserGender,
  }) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    final result = await AuthService.getMessages(widget.conversationId, 1);
    if (mounted) {
      if (result['success']) {
        setState(() {
          _messages = List<Map<String, dynamic>>.from(result['data']);
        });
        // Scroll to bottom after messages are loaded
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController
                .jumpTo(_scrollController.position.maxScrollExtent);
          }
        });
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _messageController.clear();

    final result = await AuthService.sendMessage(widget.otherUserId, content);

    if (result['success'] && result['data'] != null) {
      setState(() {
        _messages.add(Map<String, dynamic>.from(result['data']['message']));
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('فشل إرسال الرسالة')));
    }
    setState(() => _isSending = false);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherUserName),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(8.0),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final bool isMe = message['sender_id'] ==
                          AuthService.currentUser?['user_id'];
                      return _buildMessageBubble(message, isMe);
                    },
                  ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isMe) {
    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Container(
          constraints:
              BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          margin: EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: isMe ? Colors.blue : Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            message['content'],
            style: TextStyle(color: isMe ? Colors.white : Colors.black),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(blurRadius: 4, color: Colors.black12, offset: Offset(0, -2))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'اكتب رسالة...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          IconButton(
            icon: _isSending
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(Icons.send, color: Colors.blue),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}
