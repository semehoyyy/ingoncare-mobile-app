import 'package:flutter/material.dart';
import '../../utils/theme.dart';
import '../../services/api_service.dart';
import 'login_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (email.isEmpty || password.isEmpty || confirm.isEmpty) {
      setState(() => _errorMessage = 'Semua field wajib diisi');
      return;
    }

    if (!email.contains('@')) {
      setState(() => _errorMessage = 'Email tidak valid');
      return;
    }

    if (password.length < 8) {
      setState(() => _errorMessage = 'Password minimal 8 karakter');
      return;
    }

    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      setState(() => _errorMessage = 'Password harus ada huruf besar');
      return;
    }

    if (!RegExp(r'[0-9]').hasMatch(password)) {
      setState(() => _errorMessage = 'Password harus ada angka');
      return;
    }

    if (!RegExp(r'[@$!%*#?&]').hasMatch(password)) {
      setState(() => _errorMessage = 'Password harus ada simbol (@\$!%*#?&)');
      return;
    }

    if (password != confirm) {
      setState(() => _errorMessage = 'Konfirmasi password tidak cocok');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.resetPasswordDirect(email, password, confirm);
      if (mounted) {
        if (response['success'] == true) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              title: const Text('Berhasil!'),
              content: const Text('Password berhasil diubah. Silakan login dengan password baru.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                  child: const Text('Login'),
                ),
              ],
            ),
          );
        } else {
          setState(() => _errorMessage = response['message'] ?? 'Gagal reset password');
        }
      }
    } catch (e) {
      setState(() => _errorMessage = 'Koneksi gagal. Periksa jaringan.');
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBg,
      appBar: AppBar(
        title: const Text('Lupa Kata Sandi'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Reset Kata Sandi',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryDarker),
              ),
              const SizedBox(height: 8),
              const Text(
                'Masukkan email akun Anda dan buat kata sandi baru.',
                style: TextStyle(fontSize: 14, color: AppColors.textGray),
              ),
              const SizedBox(height: 32),

              // Email
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'EMAIL',
                  labelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primaryDark, letterSpacing: 1),
                  hintText: 'email@gmail.com',
                  prefixIcon: Icon(Icons.mail_outline, color: AppColors.primaryLight),
                ),
              ),
              const SizedBox(height: 16),

              // New Password
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'KATA SANDI BARU',
                  labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primaryDark, letterSpacing: 1),
                  hintText: '••••••••',
                  helperText: 'Min 8 karakter, huruf besar, angka, simbol',
                  helperMaxLines: 2,
                  prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primaryLight),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: AppColors.primaryLight),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Confirm Password
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  labelText: 'KONFIRMASI KATA SANDI BARU',
                  labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primaryDark, letterSpacing: 1),
                  hintText: '••••••••',
                  prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primaryLight),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility, color: AppColors.primaryLight),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
              ),

              // Error message
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: AppColors.danger, fontSize: 13),
                  ),
                ),

              const SizedBox(height: 28),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleReset,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Reset Kata Sandi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
