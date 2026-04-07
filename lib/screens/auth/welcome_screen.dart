import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../api/auth_api.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/toast.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _loading = false;
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _pages = [
    {
      'image': 'assets/images/welcome1.png',
      'title': 'Chăm Sóc Boss Yêu\nDễ Dàng Tới Tự Nhiên',
      'subtitle':
          'Theo dõi, yêu thương và đồng hành cùng thú cưng của bạn.\nMỗi bé đều xứng đáng có tình thương siêu to khổng lồ!',
    },
    {
      'image': 'assets/images/welcome2.png',
      'title': 'Bác Sĩ Tại Gia\nAn Tâm Tuyệt Đối',
      'subtitle':
          'Mọi chỉ số sức khỏe, lịch tiêm phòng và hồ sơ y tế\nđều được quản lý và nhắc nhở đúng lúc kịp thời.',
    },
    {
      'image': 'assets/images/welcome3.png',
      'title': 'Nổi Bật Khí Chất\nSang Chảnh Mỗi Ngày',
      'subtitle':
          'Cùng tạo ra và lưu giữ những kỷ niệm đáng yêu,\nkhoe ngay ảnh Boss cho các "sen" khác chiêm ngưỡng!',
    },
  ];

  Future<void> _handleGoogleLogin() async {
    setState(() => _loading = true);
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);
      final idToken = await userCredential.user?.getIdToken(true);
      if (idToken != null) {
        final result = await AuthApi.socialLogin(idToken);
        if (!mounted) return;
        if (!result.success) {
          MoewToast.show(
            context,
            message: result.error ?? 'Đăng nhập Google thất bại',
            type: ToastType.error,
          );
        } else {
          MoewToast.show(
            context,
            message: 'Đăng nhập thành công!',
            type: ToastType.success,
          );
          context.read<AuthProvider>().onLoginSuccess();
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } catch (e) {
      if (mounted)
        MoewToast.show(
          context,
          message: 'Google API khước từ. Vui lòng thử lại.',
          type: ToastType.error,
        );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleAppleLogin() async {
    setState(() => _loading = true);
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final OAuthProvider oAuthProvider = OAuthProvider('apple.com');
      final AuthCredential authCredential = oAuthProvider.credential(
        idToken: credential.identityToken,
        accessToken: credential.authorizationCode,
      );
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(authCredential);
      final idToken = await userCredential.user?.getIdToken(true);
      if (idToken != null) {
        final result = await AuthApi.socialLogin(idToken);
        if (!mounted) return;
        if (!result.success) {
          MoewToast.show(
            context,
            message: result.error ?? 'Đăng nhập Apple thất bại',
            type: ToastType.error,
          );
        } else {
          MoewToast.show(
            context,
            message: 'Đăng nhập thành công!',
            type: ToastType.success,
          );
          context.read<AuthProvider>().onLoginSuccess();
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } catch (e) {
      if (mounted)
        MoewToast.show(
          context,
          message: 'Apple API khước từ. Vui lòng thử lại.',
          type: ToastType.error,
        );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFFE55C6D)),
        ),
      );
    }

    final primaryColor = const Color(0xFFE55C6D);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              // 1. CAROUSEL AREA (Auto shrinks/expands to fit the screen)
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (index) =>
                      setState(() => _currentPage = index),
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Image (Flexible so it scales down on small screens without overflowing)
                        Flexible(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxHeight: 300,
                              maxWidth: 300,
                            ),
                            child: Container(
                              margin: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark
                                    ? const Color(0xFF1E1C29)
                                    : Colors.white,
                                image: DecorationImage(
                                  image: AssetImage(_pages[index]['image']!),
                                  fit: BoxFit.contain,
                                ),
                                boxShadow: isDark
                                    ? []
                                    : [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 20,
                                          spreadRadius: 5,
                                        ),
                                      ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Title
                        Text(
                          _pages[index]['title']!,
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(
                              context,
                            ).textTheme.headlineLarge?.color,
                            height: 1.25,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        // Subtitle
                        Text(
                          _pages[index]['subtitle']!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // 2. DOTS INDICATOR
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? primaryColor
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // 3. BOTTOM BUTTONS (fixed heights)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Bắt Đầu Ngay',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Divider(color: Colors.grey.shade300, thickness: 1),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Hoặc',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(color: Colors.grey.shade300, thickness: 1),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _loading ? null : _handleGoogleLogin,
                  icon: const Icon(
                    Icons.g_mobiledata,
                    color: Colors.blue,
                    size: 28,
                  ),
                  label: Text(
                    'Google',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _handleAppleLogin,
                  icon: const Icon(Icons.apple, color: Colors.white, size: 22),
                  label: const Text(
                    'Apple',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? const Color(0xFF2A2645)
                        : const Color(0xFF1E1E1E),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
