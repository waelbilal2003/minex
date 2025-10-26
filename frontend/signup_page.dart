import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'login_page.dart';
import 'auth_service.dart';
import 'home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({Key? key}) : super(key: key);

  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _passwordsMatch = true;
  bool _isLoading = false;
  String _selectedGender = 'ذكر';
  String _registrationType = 'phone'; // 'phone', 'email', 'both'
  String _selectedUserType = 'person'; // 'person' or 'store'
  // final TextEditingController _apiUrlController = TextEditingController(); // 1. تم تعليق وحدة التحكم

  // قائمة الدول مع الأيموجيز الحقيقية للأعلام
  final List<Map<String, dynamic>> _countries = [
    {'name': 'سوريا', 'code': '+963'},
    {'name': 'لبنان', 'code': '+961'},
    {'name': 'الأردن', 'code': '+962'},
    {'name': 'الإمارات', 'code': '+971'},
    {'name': 'السعودية', 'code': '+966'},
    {'name': 'مصر', 'code': '+20'},
    {'name': 'تركيا', 'code': '+90'},
    {'name': 'فلسطين', 'code': '+972'},
    {'name': 'العراق', 'code': '+964'},
    {'name': 'ليبيا', 'code': '+218'},
    {'name': 'تونس', 'code': '+216'},
    {'name': 'الجزائر', 'code': '+213'},
    {'name': 'السودان', 'code': '+249'},
    {'name': 'الصومال', 'code': '+252'},
    {'name': 'اليمن', 'code': '+967'},
    {'name': 'الكويت', 'code': '+965'},
    {'name': 'قطر', 'code': '+974'},
    {'name': 'البحرين', 'code': '+973'},
    {'name': 'المغرب', 'code': '+212'},
  ];

  late Map<String, dynamic> _selectedCountry;

  /* // 4. تم تعليق دالة تحميل عنوان API بالكامل
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

  /* // 5. تم تعليق دالة عرض مربع حوار تغيير عنوان API بالكامل
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

  @override
  void initState() {
    super.initState();
    _selectedCountry = _countries.firstWhere(
      (country) => country['code'] == '+963',
      orElse: () => _countries[0],
    );
    // _loadSavedApiUrl(); // 2. تم تعليق استدعاء الدالة
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    // _apiUrlController.dispose(); // 3. تم تعليق التخلص من وحدة التحكم
    super.dispose();
  }

  Color get _primaryColor =>
      _selectedGender == 'ذكر' ? Colors.blue : Colors.pink;

  // ... (بقية الدوال تبقى كما هي)
  void _checkPasswordsMatch() {
    setState(() {
      _passwordsMatch =
          _passwordController.text == _confirmPasswordController.text;
    });
  }

  String? _validateEmail(String? value) {
    if (_registrationType == 'email' || _registrationType == 'both') {
      if (value == null || value.isEmpty) {
        return 'الرجاء إدخال البريد الإلكتروني';
      }
      if (!AuthService.isValidEmail(value)) {
        return 'الرجاء إدخال بريد إلكتروني صحيح (مثال: user@example.com)';
      }
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (_registrationType == 'phone' || _registrationType == 'both') {
      if (value == null || value.isEmpty) {
        return 'الرجاء إدخال رقم الهاتف';
      }
      if (value.length != 9) {
        return 'رقم الهاتف يجب أن يتكون من 9 أرقام';
      }
    }
    return null;
  }

  Future<void> _submitForm() async {
    _checkPasswordsMatch();
    if (!_formKey.currentState!.validate() || !_passwordsMatch) return;

    setState(() => _isLoading = true);

    try {
      String emailOrPhone;
      if (_registrationType == 'phone') {
        emailOrPhone = _selectedCountry['code']! + _phoneController.text.trim();
      } else {
        emailOrPhone = _emailController.text.trim();
      }

      final result = await AuthService.register(
        fullName: _nameController.text.trim(),
        emailOrPhone: emailOrPhone,
        password: _passwordController.text,
        gender: _selectedGender,
        userType: _selectedUserType,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        await AuthService.loadUserData();

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (Route<dynamic> route) => false,
        );
      } else {
        // --- بداية التعديلات الجديدة ---
        String errorMessage = 'فشل إنشاء الحساب، حاول مرة أخرى لاحقاً.';

        // تحقق مما إذا كانت الاستجابة تحتوي على أخطاء تحقق (Validation Errors)
        if (result.containsKey('errors') && result['errors'] is Map) {
          final errors = Map<String, dynamic>.from(result['errors']);

          // ابحث عن خطأ متعلق بالإيميل أو رقم الهاتف
          // الخادم قد يستخدم مفتاح 'email_or_phone' أو 'email' أو 'phone'
          if (errors.containsKey('email_or_phone')) {
            errorMessage = 'هذا البريد الإلكتروني أو رقم الهاتف مستخدم بالفعل.';
          } else if (errors.containsKey('email')) {
            errorMessage = 'هذا البريد الإلكتروني مستخدم بالفعل.';
          } else if (errors.containsKey('phone')) {
            errorMessage = 'رقم الهاتف مستخدم بالفعل.';
          } else {
            // إذا كان هناك خطأ آخر، اعرض أول رسالة خطأ تجدها
            if (errors.isNotEmpty) {
              final firstErrorKey = errors.keys.first;
              final firstErrorMessages = errors[firstErrorKey];
              if (firstErrorMessages is List && firstErrorMessages.isNotEmpty) {
                errorMessage = firstErrorMessages.first.toString();
              }
            }
          }
        } else if (result.containsKey('message')) {
          // إذا لم تكن هناك أخطاء تحقق، استخدم الرسالة العامة
          errorMessage = result['message'].toString();
        }
        // --- نهاية التعديلات الجديدة ---

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ غير متوقع.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'إنشاء حساب',
          style: TextStyle(color: _primaryColor),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: _primaryColor,
        actions: [
          /* // 6. تم تعليق زر الإعدادات
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
                Text(
                  'Minex',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'بيع وشراء بكل سهولة',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),
                // اسم المستخدم
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'الاسم الكامل',
                    labelStyle: TextStyle(color: _primaryColor),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: _primaryColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: _primaryColor, width: 2),
                    ),
                    prefixIcon: Icon(Icons.person, color: _primaryColor),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال الاسم الكامل';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // اختيار نوع التسجيل
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: _primaryColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'طريقة التسجيل:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _primaryColor,
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: Text('رقم الهاتف'),
                              value: 'phone',
                              groupValue: _registrationType,
                              activeColor: _primaryColor,
                              onChanged: (String? value) {
                                setState(() {
                                  _registrationType = value!;
                                });
                              },
                              dense: true,
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: Text('بريد إلكتروني'),
                              value: 'email',
                              groupValue: _registrationType,
                              activeColor: _primaryColor,
                              onChanged: (String? value) {
                                setState(() {
                                  _registrationType = value!;
                                });
                              },
                              dense: true,
                            ),
                          ),
                        ],
                      ),
                      RadioListTile<String>(
                        title: Text('كلاهما معاً'),
                        value: 'both',
                        groupValue: _registrationType,
                        activeColor: _primaryColor,
                        onChanged: (String? value) {
                          setState(() {
                            _registrationType = value!;
                          });
                        },
                        dense: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                if (_registrationType == 'phone' ||
                    _registrationType == 'both') ...[
                  Row(
                    children: [
                      // رقم الهاتف
                      Expanded(
                        child: TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(9),
                          ],
                          decoration: InputDecoration(
                            labelText: 'رقم الهاتف',
                            labelStyle: TextStyle(color: _primaryColor),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: _primaryColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: _primaryColor, width: 2),
                            ),
                            prefixIcon: Icon(Icons.phone, color: _primaryColor),
                          ),
                          validator: _validatePhone,
                        ),
                      ),
                      const SizedBox(width: 10),
                      // رمز الدولة
                      Expanded(
                        child: DropdownButtonFormField<Map<String, dynamic>>(
                          value: _selectedCountry,
                          decoration: InputDecoration(
                            labelText: 'رمز الدولة',
                            labelStyle: TextStyle(color: _primaryColor),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: _primaryColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: _primaryColor, width: 2),
                            ),
                          ),
                          items: _countries.map((country) {
                            return DropdownMenuItem(
                              value: country,
                              child: Row(
                                children: [
                                  Text(
                                    country['name'],
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(width: 8),
                                  Text('${country['code']}'),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedCountry = value;
                              });
                            }
                          },
                          validator: (value) {
                            if ((_registrationType == 'phone' ||
                                    _registrationType == 'both') &&
                                value == null) {
                              return 'الرجاء اختيار رمز الدولة';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],

                // حقل البريد الإلكتروني (إذا كان مطلوباً)
                if (_registrationType == 'email' ||
                    _registrationType == 'both') ...[
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: _registrationType == 'both'
                          ? 'البريد الإلكتروني'
                          : 'البريد الإلكتروني',
                      labelStyle: TextStyle(color: _primaryColor),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: _primaryColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: _primaryColor, width: 2),
                      ),
                      prefixIcon: Icon(Icons.email, color: _primaryColor),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: 20),
                ],

                // اختيار الجنس
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: _primaryColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Row(
                        children: [
                          Radio<String>(
                            value: 'ذكر',
                            groupValue: _selectedGender,
                            activeColor: _primaryColor,
                            onChanged: (String? value) {
                              setState(() {
                                _selectedGender = value!;
                              });
                            },
                          ),
                          Text('ذكر', style: TextStyle(color: _primaryColor)),
                        ],
                      ),
                      Row(
                        children: [
                          Radio<String>(
                            value: 'أنثى',
                            groupValue: _selectedGender,
                            activeColor: _primaryColor,
                            onChanged: (String? value) {
                              setState(() {
                                _selectedGender = value!;
                              });
                            },
                          ),
                          Text('أنثى', style: TextStyle(color: _primaryColor)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const SizedBox(height: 20),
                const Text('نوع الحساب',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('شخصي'),
                        value: 'person',
                        groupValue: _selectedUserType,
                        onChanged: (value) {
                          setState(() {
                            _selectedUserType = value!;
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('متجر'),
                        value: 'store',
                        groupValue: _selectedUserType,
                        onChanged: (value) {
                          setState(() {
                            _selectedUserType = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // كلمة المرور
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور',
                    labelStyle: TextStyle(color: _primaryColor),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: _primaryColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: _primaryColor, width: 2),
                    ),
                    prefixIcon: Icon(Icons.lock, color: _primaryColor),
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
                  onChanged: (value) => _checkPasswordsMatch(),
                ),
                const SizedBox(height: 20),
                // تأكيد كلمة المرور
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'تأكيد كلمة المرور',
                    labelStyle: TextStyle(color: _primaryColor),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: _primaryColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: _primaryColor, width: 2),
                    ),
                    prefixIcon: Icon(Icons.lock, color: _primaryColor),
                    errorText:
                        _passwordsMatch ? null : 'كلمات المرور غير متطابقة',
                    errorStyle: const TextStyle(color: Colors.red),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء تأكيد كلمة المرور';
                    }
                    return null;
                  },
                  onChanged: (value) => _checkPasswordsMatch(),
                ),
                const SizedBox(height: 30),
                // زر إنشاء الحساب
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      backgroundColor: _primaryColor,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'إنشاء حساب',
                            style: TextStyle(color: Colors.white),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 10),
                // زر تسجيل الدخول
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => _navigateToLogin(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      side: BorderSide(
                        color: _primaryColor,
                      ),
                    ),
                    child: Text(
                      'لديك حساب بالفعل؟ سجل الدخول',
                      style: TextStyle(
                        color: _primaryColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }
}
