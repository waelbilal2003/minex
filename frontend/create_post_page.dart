import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'auth_service.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({Key? key}) : super(key: key);

  @override
  _CreatePostPageState createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedMarket;
  TextEditingController _priceController = TextEditingController();
  TextEditingController _locationController = TextEditingController();
  TextEditingController _notesController = TextEditingController();
  TextEditingController _titleController = TextEditingController();
  // بدلاً من List<File> _images = [];
  List<Map<String, dynamic>> _images =
      []; // { 'file': File, 'bytes': Uint8List }
  File? _video;

  // قائمة الأسواق المحدثة لتتطابق مع صفحة الأقسام الجديدة
  List<Map<String, dynamic>> _markets = [
    {'name': 'السيارات', 'category': 'السيارات'},
    {'name': 'الدراجات النارية', 'category': 'الدراجات النارية'},
    {'name': ' تجارة العقارات', 'category': 'تجارة العقارات'},
    {'name': ' ايجار العقارات', 'category': 'ايجار العقارات'},
    {'name': 'المستلزمات العسكرية', 'category': 'المستلزمات العسكرية'},
    {
      'name': 'الجوالات والقطع الإلكترونية',
      'category': 'الهواتف و الالكترونيات'
    },
    {'name': 'الأدوات الكهربائية', 'category': 'الادوات الكهربائية'},
    {'name': 'المواشي والحيوانات', 'category': 'المواشي والحيوانات'},
    {'name': 'الثمار والحبوب', 'category': 'الثمار والحبوب'},
    {'name': 'المواد الغذائية', 'category': 'المواد الغذائية'},
    {'name': 'المطاعم', 'category': 'المطاعم'},
    {'name': 'مواد التدفئة', 'category': 'مواد التدفئة'},
    {'name': 'المكياج والاكسسوارات ', 'category': 'المكياج والاكسسوارات'},
    {'name': 'الكتب و القرطاسية', 'category': 'الكتب و القرطاسية'},
    {'name': 'الأدوات المنزلية والصحية', 'category': 'لادوات المنزلية'},
    {'name': 'الملابس والأحذية', 'category': 'الملابس والأحذية'},
    {'name': 'أثاث المنزل', 'category': 'اثاث المنزل'},
    // الأقسام الرئيسية المضافة حديثاً
    {'name': 'التوظيف', 'category': 'التوظيف'},
    {'name': 'المناقصات', 'category': 'المناقصات'},
    {'name': 'العروض العامة', 'category': 'العروض العامة'},
    {'name': 'تجار الجملة', 'category': 'تجار الجملة'},
    {'name': 'الموزعين', 'category': 'الموزعين'},
    {'name': 'الموردين', 'category': 'الموردين'},
    {'name': 'أسواق أخرى', 'category': 'اسواق أخرى'},
  ];

  Future<void> _pickImage() async {
    // استخدام pickMultiImage بدلاً من pickImage للسماح باختيار صور متعددة
    final List<XFile>? pickedFiles = await ImagePicker().pickMultiImage(
      imageQuality: 80, // يمكنك ضغط الصور لتقليل حجمها (0-100)
    );

    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      // المرور على كل الصور التي تم اختيارها
      for (var pickedFile in pickedFiles) {
        final file = File(pickedFile.path);
        final bytes = await file.readAsBytes(); // قراءة البيانات كـ Uint8List

        // إضافة كل صورة إلى القائمة
        setState(() {
          _images.add({
            'file': file,
            'bytes': bytes,
          });
        });
      }
    }
  }

  Future<void> _pickVideo() async {
    final pickedFile =
        await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _video = File(pickedFile.path);
      });
    }
  }

  // ❗️❗️ في ملف create_post_page.dart، استبدل الدالة القديمة بهذه ❗️❗️

  Future<void> _submitPost() async {
    // التحقق من أن النموذج صالح وأن القسم تم اختياره
    if (_formKey.currentState!.validate() && _selectedMarket != null) {
      // إظهار مؤشر التحميل
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) =>
            const Center(child: CircularProgressIndicator()),
      );

      try {
        // 1. تحويل قائمة الصور من List<Map> إلى List<String> تحتوي على المسارات فقط
        List<String> imagePaths =
            _images.map((img) => img['file'].path as String).toList();

        // 2. استدعاء الدالة الممركزة والصحيحة من AuthService
        final result = await AuthService.createPost(
          category: _selectedMarket!,
          title: _titleController.text, // استخدام المتحكم الجديد
          content: _notesController.text,
          price: _priceController.text,
          location: _locationController.text,
          imagePaths: imagePaths,
          videoPath:
              _video?.path, // الحصول على المسار من الفيديو إذا كان موجودًا
        );

        // إخفاء مؤشر التحميل
        if (mounted) Navigator.pop(context);

        // 3. التعامل مع النتيجة
        if (result['success'] == true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تم نشر المنشور بنجاح!'),
                backgroundColor: Colors.green,
              ),
            );
            // الرجوع إلى الصفحة السابقة مع إشارة للنجاح (لتحديث البيانات هناك)
            Navigator.pop(context, true);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'فشل في نشر المنشور'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        // إخفاء مؤشر التحميل في حال حدوث خطأ
        if (mounted) Navigator.pop(context);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('حدث خطأ: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('إنشاء منشور جديد'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // قسم اختيار السوق/القسم
              Text(
                'اختر القسم:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedMarket,
                hint: Text('اختر القسم المناسب للمنشور'),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedMarket = newValue;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء اختيار قسم للمنشور';
                  }
                  return null;
                },
                items: _markets.map<DropdownMenuItem<String>>((market) {
                  return DropdownMenuItem<String>(
                    value: market['category'],
                    child: Text(market['name']),
                  );
                }).toList(),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'عنوان المنشور',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال عنوان للمنشور';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              // حقل السعر (أصبح إجباري)
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'السعر',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال السعر';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // حقل المكان (أصبح إجباري)
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'المكان',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال المكان';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // حقل الملاحظات
              TextFormField(
                controller: _notesController,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: 'وصف المنشور',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال وصف للمنشور';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // أزرار إضافة الوسائط
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: Icon(Icons.image, color: Colors.white),
                      label: Text('إضافة صور',
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickVideo,
                      icon: Icon(Icons.video_file, color: Colors.white),
                      label: Text('إضافة فيديو',
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // معاينة الصور المضافة
              // بدلاً من استخدام Image.file
              if (_images.isNotEmpty) ...[
                Text('الصور المضافة:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: _images.map((img) {
                    return Stack(
                      children: [
                        Image.memory(
                          // استخدام Image.memory هنا
                          img['bytes'],
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: IconButton(
                            icon: Icon(Icons.close, color: Colors.white),
                            onPressed: () {
                              setState(() {
                                _images.remove(img);
                              });
                            },
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
                SizedBox(height: 16),
              ],
              // معاينة الفيديو المضاف
              if (_video != null) ...[
                Text('الفيديو المضاف:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 200,
                      color: Colors.black,
                      child: Center(
                        child: Icon(Icons.play_circle_fill,
                            color: Colors.white, size: 50),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: IconButton(
                        icon: Icon(Icons.close, color: Colors.white),
                        onPressed: () {
                          setState(() {
                            _video = null;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
              ],

              // زر النشر
              ElevatedButton(
                onPressed: _submitPost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'نشر المنشور',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
