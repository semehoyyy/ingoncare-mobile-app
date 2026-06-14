import 'package:flutter/material.dart';
import '../../utils/theme.dart';
import '../../services/api_service.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
final String email;

const ResetPasswordScreen({
super.key,
required this.email,
});

@override
State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
final _passwordController = TextEditingController();
final _confirmController = TextEditingController();

bool _isLoading = false;
bool _obscurePassword = true;
bool _obscureConfirm = true;

String? _errorMessage;

@override
void dispose() {
_passwordController.dispose();
_confirmController.dispose();
super.dispose();
}

Future<void> _handleResetPassword() async {
final password = _passwordController.text.trim();
final confirm = _confirmController.text.trim();

```
if (password.isEmpty || confirm.isEmpty) {
  setState(() {
    _errorMessage = 'Semua field wajib diisi';
  });
  return;
}

if (password.length < 8) {
  setState(() {
    _errorMessage = 'Password minimal 8 karakter';
  });
  return;
}

if (password != confirm) {
  setState(() {
    _errorMessage = 'Konfirmasi password tidak cocok';
  });
  return;
}

setState(() {
  _isLoading = true;
  _errorMessage = null;
});

try {
  final response = await ApiService.resetPasswordDirect(
    widget.email,
    password,
    confirm,
  );

  if (response['success'] == true) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Berhasil'),
        content: const Text(
          'Password berhasil diperbarui. Silakan login kembali.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => const LoginScreen(),
                ),
                (route) => false,
              );
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  } else {
    setState(() {
      _errorMessage =
          response['message'] ?? 'Gagal memperbarui password';
    });
  }
} catch (e) {
  setState(() {
    _errorMessage = 'Terjadi kesalahan. Silakan coba lagi.';
  });
}

setState(() {
  _isLoading = false;
});
```

}

Widget _buildPasswordField({
required TextEditingController controller,
required String label,
required bool obscure,
required VoidCallback onToggle,
}) {
return TextFormField(
controller: controller,
obscureText: obscure,
decoration: InputDecoration(
labelText: label,
prefixIcon: const Icon(Icons.lock_outline),
suffixIcon: IconButton(
icon: Icon(
obscure
? Icons.visibility_off_outlined
: Icons.visibility_outlined,
),
onPressed: onToggle,
),
),
);
}

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: AppColors.primaryBg,
appBar: AppBar(
title: const Text('Reset Kata Sandi'),
),
body: Center(
child: SingleChildScrollView(
padding: const EdgeInsets.all(24),
child: Container(
padding: const EdgeInsets.all(24),
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(20),
boxShadow: const [
BoxShadow(
blurRadius: 12,
offset: Offset(0, 4),
color: Colors.black12,
),
],
),
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
const Icon(
Icons.lock_reset,
size: 70,
color: AppColors.primaryLight,
),

```
            const SizedBox(height: 16),

            const Text(
              'Buat Kata Sandi Baru',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDarker,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Masukkan kata sandi baru untuk akun Anda.',
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 28),

            _buildPasswordField(
              controller: _passwordController,
              label: 'Kata Sandi Baru',
              obscure: _obscurePassword,
              onToggle: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),

            const SizedBox(height: 16),

            _buildPasswordField(
              controller: _confirmController,
              label: 'Konfirmasi Kata Sandi',
              obscure: _obscureConfirm,
              onToggle: () {
                setState(() {
                  _obscureConfirm = !_obscureConfirm;
                });
              },
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(
                  color: Colors.red,
                ),
              ),
            ],

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    _isLoading ? null : _handleResetPassword,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : const Text(
                        'Reset Kata Sandi',
                      ),
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);
```

}
}
