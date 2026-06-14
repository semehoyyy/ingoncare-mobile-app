import 'package:flutter/material.dart';
import '../../utils/theme.dart';
import '../../services/api_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSendLink() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() => _errorMessage = 'Email wajib diisi');
      return;
    }

    if (!email.contains('@')) {
      setState(() => _errorMessage = 'Email tidak valid');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.forgotPassword(email);
      if (mounted) {
        if (response['success'] == true) {
          setState(() => _emailSent = true);
        } else {
          setState(() => _errorMessage = response['message'] ?? 'Gagal mengirim link reset');
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
          child: _emailSent ? _buildSuccessView() : _buildFormView(),
        ),
      ),
    );
  }

  Widget _buildFormView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          'Lupa Kata Sandi?',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryDarker,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Masukkan email akun Anda. Kami akan mengirimkan link untuk membuat kata sandi baru.',
          style: TextStyle(fontSize: 14, color: AppColors.textGray),
        ),
        const SizedBox(height: 32),

        // Email field
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'EMAIL',
            labelStyle: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryDark,
              letterSpacing: 1,
            ),
            hintText: 'email@gmail.com',
            prefixIcon: Icon(Icons.mail_outline, color: AppColors.primaryLight),
          ),
        ),

        // Error message
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: AppColors.danger, fontSize: 13),
            ),
          ),

        const SizedBox(height: 28),

        // Kirim button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleSendLink,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Kirim Link Reset',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 60),
        const Icon(Icons.mark_email_read_outlined, size: 80, color: AppColors.primaryLight),
        const SizedBox(height: 24),
        const Text(
          'Cek Email Kamu!',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryDarker,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Link reset kata sandi telah dikirim ke\n${_emailController.text.trim()}\n\nSilakan cek inbox atau folder spam kamu.',
          style: const TextStyle(fontSize: 14, color: AppColors.textGray),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Kembali ke Login',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}