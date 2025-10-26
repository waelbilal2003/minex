import 'package:flutter/material.dart';
import 'signup_page.dart';
import 'auth_service.dart';
import 'home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailOrPhoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  // final TextEditingController _apiUrlController = TextEditingController(); // 1. تم تعليق وحدة التحكم

  @override
  void initState() {
    super.initState();
    // _loadSavedApiUrl(); // 2. تم تعليق استدعاء دالة التحميل
  }

  /* // 3. تم تعليق دالة تحميل عنوان API المحفوظ بالكامل
  void _loadSavedApiUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString('api_url');
    if (savedUrl != null && savedUrl.isNotEmpty) {
      setState(() {
        _apiUrlController.text = savedUrl;
        AuthService.baseUrl = savedUrl;
      });
    } else {
      _apiUrlController.text = AuthService.baseUrl;
    }
  }
  */

  @override
  void dispose() {
    _emailOrPhoneController.dispose();
    _passwordController.dispose();
    // _apiUrlController.dispose(); // تم تعليق هذا أيضاً لتجنب الأخطاء
    super.dispose();
  }

  /* // 4. تم تعليق دالة عرض مربع حوار تغيير عنوان API بالكامل
  void _showApiUrlDialog() async {
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    _apiUrlController.text = AuthService.baseUrl;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('تغيير عنوان API'),
          content: TextFormField(
            controller: _apiUrlController,
            decoration: const InputDecoration(
              labelText: 'عنوان الخادم الرئيسي',
              hintText: 'https://example.ngrok-free.app',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.url,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newUrl = _apiUrlController.text.trim();

                if (newUrl.isNotEmpty &&
                    (newUrl.startsWith('http://') ||
                        newUrl.startsWith('https://'))) {
                  final formattedUrl = newUrl.endsWith('/')
                      ? newUrl.substring(0, newUrl.length - 1)
                      : newUrl;

                  setState(() {
                    AuthService.baseUrl = formattedUrl;
                  });
                  await prefs.setString('api_url', formattedUrl);

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ تم تحديث عنوان API بنجاح'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    Navigator.pop(dialogContext);
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            '❌ خطأ: يجب أن يبدأ الرابط بـ http:// أو https://'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );
  }
  */

  void _navigateToSignup() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SignupPage()),
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final result = await AuthService.login(
          emailOrPhone: _emailOrPhoneController.text.trim(),
          password: _passwordController.text,
        );

        if (!mounted) return;

        if (result['success'] == true) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomePage()),
            (Route<dynamic> route) => false,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(' فشل تسجيل الدخول بالرجاء المحاولة لاحقاً'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('حدث خطأ في الخادم'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _forgotPassword() async {
    if (_emailOrPhoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء إدخال البريد الإلكتروني أو رقم الهاتف أولاً'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await AuthService.forgotPassword(
        emailOrPhone: _emailOrPhoneController.text.trim(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(' '),
          backgroundColor: result['success'] ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ في الخادم'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل الدخول'),
        centerTitle: true,
        actions: [
          /* // 5. تم تعليق زر الإعدادات
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showApiUrlDialog,
            tooltip: 'تغيير عنوان API',
          ),
          */
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 20),
                const Text(
                  'Minex',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'بيع وشراء بكل سهولة',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),
                TextFormField(
                  controller: _emailOrPhoneController,
                  decoration: const InputDecoration(
                    labelText: 'البريد الإلكتروني أو رقم الهاتف',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال البريد الإلكتروني أو رقم الهاتف';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'كلمة المرور',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال كلمة المرور';
                    }
                    if (value.length < 6) {
                      return 'كلمة المرور يجب أن تكون على الأقل 6 أحرف';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: _isLoading ? null : _forgotPassword,
                    child: const Text('هل نسيت كلمة المرور؟'),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('تسجيل الدخول'),
                  ),
                ),
                const Text('أو', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const HomePage()),
                            );
                          },
                    child: const Text(
                      'الدخول كزائر',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _navigateToSignup,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text('إنشاء حساب جديد'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
