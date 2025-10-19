import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'user_profile_page.dart';
import 'post_card_widget.dart';
import 'post_helpers.dart'; // <-- ✨ استيراد الدوال المساعدة المركزية

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _userResults = [];
  List<Map<String, dynamic>> _postResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  // ✅ تم نقل هذه الدالة إلى PostHelpers.convertCategoryToArabic

  // ✅ تم نقل هذه الدالة إلى PostHelpers.parseToInt

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      if (!mounted) return;
      setState(() {
        _userResults = [];
        _postResults = [];
        _hasSearched = false;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await AuthService.search(query);

      if (!mounted) return;

      if (result['success'] == true && result['data'] != null) {
        // ✅ استخدام الدالة المركزية من PostHelpers
        List<Map<String, dynamic>> rawPosts =
            List<Map<String, dynamic>>.from(result['data']['posts'] ?? []);

        final processedPosts = PostHelpers.processPostsList(rawPosts);

        setState(() {
          _userResults =
              List<Map<String, dynamic>>.from(result['data']['users'] ?? []);
          _postResults = processedPosts;
          _hasSearched = true;
        });
      } else {
        setState(() {
          _userResults = [];
          _postResults = [];
          _hasSearched = true;
        });
        if (mounted && result['message'] != null) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(result['message'])));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('خطأ في البحث: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    // ... (هذا الجزء يبقى كما هو بدون تغيير)
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserProfilePage(
                    userId: user['id'], userName: user['full_name']),
              ));
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                // يمكنك تحسين الصورة الرمزية هنا إذا أردت
                backgroundColor: Colors.grey.shade300,
                child: Text(
                  user['full_name']?.substring(0, 1) ?? 'U',
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user['full_name'] ?? 'مستخدم',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(
                        user['email'] ??
                            user['phone'] ??
                            'لا يوجد معلومات اتصال',
                        style:
                            const TextStyle(fontSize: 14, color: Colors.grey)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('البحث'),
        backgroundColor: (AuthService.currentUser?['gender'] ?? 'ذكر') == 'ذكر'
            ? Colors.blue
            : Colors.pink,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Theme.of(context).appBarTheme.backgroundColor,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ابحث عن منشورات أو مستخدمين...',
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                hintStyle: TextStyle(color: Colors.white70),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white70),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.black.withOpacity(0.2),
              ),
              style: TextStyle(color: Colors.white),
              onSubmitted: (query) => _performSearch(query),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : !_hasSearched
                    ? Center(child: Text('اكتب في الحقل أعلاه لبدء البحث'))
                    : (_userResults.isEmpty && _postResults.isEmpty)
                        ? Center(
                            child: Text(
                                'لا توجد نتائج لـ "${_searchController.text}"'))
                        : ListView(
                            padding: const EdgeInsets.all(16.0),
                            children: [
                              if (_userResults.isNotEmpty) ...[
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Text(
                                      'المستخدمون (${_userResults.length})',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge),
                                ),
                                ..._userResults.map(_buildUserCard),
                                const SizedBox(height: 24),
                              ],
                              if (_postResults.isNotEmpty) ...[
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Text(
                                      'المنشورات (${_postResults.length})',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge),
                                ),
                                ..._postResults
                                    .map((post) => PostCardWidget(
                                          post: post,
                                          onDelete: () {
                                            setState(() {
                                              _postResults.removeWhere(
                                                  (p) => p['id'] == post['id']);
                                            });
                                          },
                                        ))
                                    .toList(),
                              ],
                            ],
                          ),
          ),
        ],
      ),
    );
  }
}
