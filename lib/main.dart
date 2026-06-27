import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';

import 'utils/theme.dart';
import 'services/auth_provider.dart';
import 'services/api_service.dart'; // ✅ Ganti notification_service dengan ini
import 'screens/auth/login_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/home/main_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    // ✅ initNotification dipanggil di sini hanya untuk setup handler background/terminated
    // Token FCM akan dikirim ke backend setelah user login
    await ApiService.initNotification();
  } catch (e) {
    debugPrint('Firebase Init Error: $e');
  }

  runApp(const IngonCareApp());
}

class IngonCareApp extends StatefulWidget {
  const IngonCareApp({super.key});

  @override
  State<IngonCareApp> createState() => _IngonCareAppState();
}

class _IngonCareAppState extends State<IngonCareApp> {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _listenDeepLinks();
  }

  void _listenDeepLinks() {
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        _handleDeepLink(uri);
      },
      onError: (error) {
        debugPrint('Deep link error: $error');
      },
    );
  }

  void _handleDeepLink(Uri uri) {
    if (uri.scheme == 'ingoncare' && uri.host == 'reset-password') {
      final email = uri.queryParameters['email'];
      final token = uri.queryParameters['token'];

      if (email != null &&
          email.isNotEmpty &&
          token != null &&
          token.isNotEmpty) {
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => ResetPasswordScreen(
              email: email,
              token: token,
            ),
          ),
          (route) => false,
        );
      }
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'IngonCare',
        theme: AppTheme.theme,
        debugShowCheckedModeBanner: false,
        home: const SplashScreen(),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  final AppLinks _appLinks = AppLinks();

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();
    _checkInitialLinkOrAuth();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkInitialLinkOrAuth() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    try {
      final Uri? initialUri = await _appLinks.getInitialLink();

      if (initialUri != null &&
          initialUri.scheme == 'ingoncare' &&
          initialUri.host == 'reset-password') {
        final email = initialUri.queryParameters['email'];
        final token = initialUri.queryParameters['token'];

        if (email != null &&
            email.isNotEmpty &&
            token != null &&
            token.isNotEmpty) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ResetPasswordScreen(
                email: email,
                token: token,
              ),
            ),
          );
          return;
        }
      }
    } catch (e) {
      debugPrint('Initial deep link error: $e');
    }

    await _checkAuth();
  }

  Future<void> _checkAuth() async {
    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.checkAuth();

    if (!mounted) return;

    if (authProvider.isAuthenticated) {
      // ✅ User sudah login (token ada) — kirim FCM token ke backend sekarang
      try {
        await ApiService.initNotification();
      } catch (e) {
        debugPrint('FCM re-init error: $e');
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/logo_ingoncare.png',
                  width: 260,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLighter,
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: const Icon(
                        Icons.pets,
                        size: 70,
                        color: AppColors.primary,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 28),
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.primary,
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