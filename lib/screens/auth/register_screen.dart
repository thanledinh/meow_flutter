import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../api/auth_api.dart';
import '../../widgets/toast.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  bool _showPassword = false;

  Future<void> _handleRegister() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();

    if (name.isEmpty) { MoewToast.show(context, message: 'Nhập tên hiển thị', type: ToastType.warning); return; }
    if (email.isEmpty) { MoewToast.show(context, message: 'Nhập email', type: ToastType.warning); return; }
    if (password.isEmpty) { MoewToast.show(context, message: 'Nhập mật khẩu', type: ToastType.warning); return; }
    if (password.length < 6) { MoewToast.show(context, message: 'Mật khẩu ít nhất 6 ký tự', type: ToastType.warning); return; }
    if (password != confirm) { MoewToast.show(context, message: 'Mật khẩu xác nhận không đúng', type: ToastType.error); return; }

    setState(() => _loading = true);
    try {
      final result = await AuthApi.register({
        'displayName': name, 'email': email,
        'password': password, 'confirmPassword': confirm,
      });
      if (!mounted) return;
      if (!result.success) {
        MoewToast.show(context, message: result.error ?? 'Đăng ký thất bại', type: ToastType.error);
        return;
      }
      await AuthApi.logout(); // không auto-login
      if (!mounted) return;
      MoewToast.show(context, message: 'Đăng ký thành công! Đăng nhập để bắt đầu.', type: ToastType.success);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.pop(context);
      });
    } catch (_) {
      if (mounted) MoewToast.show(context, message: 'Không thể kết nối server.', type: ToastType.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose();
    _passCtrl.dispose(); _confirmCtrl.dispose();
    super.dispose();
  }

  Widget _buildInput(String label, IconData icon, String hint, TextEditingController ctrl, {bool isPassword = false, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: MoewTextStyles.label),
        const SizedBox(height: MoewSpacing.sm),
        TextField(
          controller: ctrl,
          obscureText: isPassword && !_showPassword,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20, color: MoewColors.textSub),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(_showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 22, color: MoewColors.textSub),
                    onPressed: () => setState(() => _showPassword = !_showPassword),
                  )
                : null,
          ),
        ),
        const SizedBox(height: MoewSpacing.md),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MoewColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: MoewSpacing.lg, vertical: MoewSpacing.xl),
            child: Column(
              children: [
                // Logo
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: MoewColors.surface,
                    borderRadius: BorderRadius.circular(MoewRadius.full),
                    boxShadow: MoewShadows.card,
                  ),
                  child: const Icon(Icons.pets, size: 38, color: MoewColors.secondary),
                ),
                const SizedBox(height: MoewSpacing.md),
                Text('Tạo tài khoản', style: MoewTextStyles.h1),
                const SizedBox(height: MoewSpacing.sm),
                Text('Tham gia cộng đồng yêu thú cưng', style: TextStyle(fontSize: 14, color: MoewColors.textSub)),
                const SizedBox(height: MoewSpacing.lg),

                // Form card
                Container(
                  padding: const EdgeInsets.all(MoewSpacing.lg),
                  decoration: BoxDecoration(
                    color: MoewColors.white,
                    borderRadius: BorderRadius.circular(MoewRadius.xl),
                    boxShadow: MoewShadows.card,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInput('Tên hiển thị', Icons.person_outline, 'Tên của bạn', _nameCtrl),
                      _buildInput('Email', Icons.mail_outline, 'your@email.com', _emailCtrl, keyboardType: TextInputType.emailAddress),
                      _buildInput('Mật khẩu', Icons.lock_outline, 'Ít nhất 6 ký tự', _passCtrl, isPassword: true),
                      _buildInput('Xác nhận mật khẩu', Icons.shield_outlined, 'Nhập lại mật khẩu', _confirmCtrl, isPassword: true),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _handleRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: MoewColors.secondary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MoewRadius.md)),
                          ),
                          child: _loading
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.person_add_outlined, size: 22, color: Colors.white),
                                    const SizedBox(width: 8),
                                    Text('Tạo tài khoản', style: MoewTextStyles.button),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: MoewSpacing.lg),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Đã có tài khoản? ', style: TextStyle(color: MoewColors.textSub, fontSize: 14)),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text('Đăng nhập', style: TextStyle(color: MoewColors.primary, fontSize: 14, fontWeight: FontWeight.w700)),
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
