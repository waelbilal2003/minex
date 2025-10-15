import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'signup_page.dart';
// ملفات المشروع
import 'firebase_options.dart';
import 'auth_service.dart';
import 'home_page.dart';
import 'notifications_page.dart';
import 'firebase_api.dart';

// مفتاح عام للتنقل
import 'app_globals.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Attach a global error handler so we can see uncaught Flutter errors
  FlutterError.onError = (details) {
    FlutterError.dumpErrorToConsole(details);
  };

  // Try to initialize Firebase but don't block the app indefinitely.
  // Put a timeout and catch errors so build can proceed even if Firebase fails.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 8));
    debugPrint('✅ Firebase initialized');
  } catch (e, st) {
    debugPrint('⚠️ Firebase.initializeApp failed or timed out: $e');
    debugPrint('$st');
  }

  // Load stored user data with a timeout to avoid long blocking on startup
  try {
    await AuthService.loadUserData().timeout(const Duration(seconds: 5));
  } catch (e) {
    debugPrint("⚠️ loadUserData error: $e");
  }

  // Run the app inside a guarded zone to capture any uncaught Dart errors.
  runZonedGuarded(() {
    runApp(const MyApp());
  }, (error, stack) {
    debugPrint('Uncaught error (zone): $error');
    debugPrint('$stack');
  });
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Minex',
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Arial',
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.blue, width: 2),
          ),
        ),
      ),
      navigatorKey: navigatorKey,
      home: const SplashScreen(),
      routes: {
        '/notifications': (context) => const NotificationsPage(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // بعد ال frame الأولي نقوم بالتنقل والتحقق ونشغّل الإشعارات (غير محظور)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // تشغيل الإشعارات بدون حظر واجهة المستخدم
      FirebaseApi().initNotifications().catchError((e) {
        debugPrint("⚠️ initNotifications failed: $e");
      });

      _navigateBasedOnAuthStatus();
    });
  }

  void _navigateBasedOnAuthStatus() async {
    await AuthService.loadUserData();
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    if (AuthService.isLoggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } else {
      // --- ✅ التعديل هنا ---
      Navigator.pushReplacement(
        context,
        // غيرنا LoginPage إلى SignupPage
        MaterialPageRoute(builder: (context) => const SignupPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                image: const DecorationImage(
                  image: AssetImage('assets/images/logo.png'),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Minex',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'بيع وشراء بكل سهولة',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 50),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
