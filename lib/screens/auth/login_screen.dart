import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../api/auth_api.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/toast.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _showPassword = false;

  Future<void> _handleLogin() async {
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text.trim();
    if (email.isEmpty) {
      MoewToast.show(context, message: 'Vui lòng nhập email', type: ToastType.warning);
      return;
    }
    if (password.isEmpty) {
      MoewToast.show(context, message: 'Vui lòng nhập mật khẩu', type: ToastType.warning);
      return;
    }

    setState(() => _loading = true);
    try {
      final result = await AuthApi.login({'email': email, 'password': password});
      if (!mounted) return;
      if (!result.success) {
        MoewToast.show(context, message: result.error ?? 'Đăng nhập thất bại', type: ToastType.error);
        return;
      }
      MoewToast.show(context, message: 'Chào mừng trở lại!', type: ToastType.success);
      if (mounted) {
        context.read<AuthProvider>().onLoginSuccess();
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (_) {
      if (mounted) MoewToast.show(context, message: 'Không thể kết nối server.', type: ToastType.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      MoewToast.show(context, message: 'Nhập email trước khi reset.', type: ToastType.warning);
      return;
    }
    final result = await AuthApi.forgotPassword(email);
    if (!mounted) return;
    if (result.success) {
      MoewToast.show(context, message: 'Kiểm tra hộp thư để reset mật khẩu!', type: ToastType.success);
    } else {
      MoewToast.show(context, message: result.error ?? 'Không thể gửi', type: ToastType.error);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).textTheme.bodyLarge?.color),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: MoewSpacing.lg, vertical: MoewSpacing.xl),
            child: Column(
              children: [
                // Logo
                Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(MoewRadius.full),
                    boxShadow: MoewShadows.card,
                  ),
                  child: Icon(Icons.pets, size: 48, color: MoewColors.primary),
                ),
                SizedBox(height: MoewSpacing.md),
                Text('Đăng nhập', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Theme.of(context).textTheme.headlineLarge?.color, letterSpacing: 1)),
                SizedBox(height: MoewSpacing.sm),
                Text('Vui lòng điền thông tin để tiếp tục', style: TextStyle(fontSize: 15, color: Theme.of(context).textTheme.bodySmall?.color)),
                SizedBox(height: MoewSpacing.xl),

                // Form card
                Container(
                  padding: EdgeInsets.all(MoewSpacing.lg),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(MoewRadius.xl),
                    boxShadow: MoewShadows.card,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Email
                      Text('EMAIL', style: Theme.of(context).textTheme.labelSmall),
                      SizedBox(height: MoewSpacing.sm),
                      TextField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: 'your@email.com',
                          prefixIcon: Icon(Icons.mail_outline, size: 20, color: Theme.of(context).textTheme.bodySmall?.color),
                        ),
                      ),
                      SizedBox(height: MoewSpacing.md),

                      // Password
                      Text('MẬT KHẨU', style: Theme.of(context).textTheme.labelSmall),
                      SizedBox(height: MoewSpacing.sm),
                      TextField(
                        controller: _passCtrl,
                        obscureText: !_showPassword,
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          prefixIcon: Icon(Icons.lock_outline, size: 20, color: Theme.of(context).textTheme.bodySmall?.color),
                          suffixIcon: IconButton(
                            icon: Icon(_showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 22, color: Theme.of(context).textTheme.bodySmall?.color),
                            onPressed: () => setState(() => _showPassword = !_showPassword),
                          ),
                        ),
                      ),
                      SizedBox(height: MoewSpacing.xs),

                      // Forgot
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _handleForgotPassword,
                          child: Text('Quên mật khẩu?', style: TextStyle(color: MoewColors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      SizedBox(height: MoewSpacing.sm),

                      // Login button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: MoewColors.primary,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MoewRadius.md)),
                          ),
                          child: _loading
                              ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.login, size: 22, color: Colors.white),
                                    SizedBox(width: 8),
                                    Text('Đăng nhập', style: MoewTextStyles.button),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: MoewSpacing.lg),

                // Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Chưa có tài khoản? ', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 14)),
                    GestureDetector(
                      onTap: () => Navigator.pushReplacementNamed(context, '/register'),
                      child: Text('Đăng ký ngay', style: TextStyle(color: MoewColors.secondary, fontSize: 14, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
