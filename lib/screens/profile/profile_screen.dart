import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/theme.dart';
import '../../services/auth_provider.dart';
import '../../services/api_service.dart';
import '../auth/login_screen.dart';
import '../social/followers_following_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getProfile();
      setState(() {
        _profile = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Yakin ingin keluar dari akun?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Keluar', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await Provider.of<AuthProvider>(context, listen: false).logout();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  void _showEditProfileDialog() {
    final user = _profile?['user'];
    if (user == null) return;

    final nameC = TextEditingController(text: user['name'] ?? '');
    final emailC = TextEditingController(text: user['email'] ?? '');
    final phoneC = TextEditingController(text: user['phone'] ?? '');
    final addressC = TextEditingController(text: user['address'] ?? '');
    final dobC = TextEditingController(text: user['dob'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Edit Profil', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryDarker)),
              const SizedBox(height: 20),
              TextField(
                controller: nameC,
                decoration: const InputDecoration(labelText: 'Nama *', prefixIcon: Icon(Icons.person_outline, color: AppColors.primaryLight)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailC,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email *', prefixIcon: Icon(Icons.email_outlined, color: AppColors.primaryLight)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneC,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'No. Telepon *', prefixIcon: Icon(Icons.phone_outlined, color: AppColors.primaryLight)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: dobC,
                decoration: const InputDecoration(labelText: 'Tanggal Lahir (YYYY-MM-DD)', prefixIcon: Icon(Icons.cake_outlined, color: AppColors.primaryLight)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressC,
                decoration: const InputDecoration(labelText: 'Alamat', prefixIcon: Icon(Icons.location_on_outlined, color: AppColors.primaryLight)),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nameC.text.isEmpty || emailC.text.isEmpty || phoneC.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Nama, Email, dan Telepon wajib diisi')),
                      );
                      return;
                    }
                    try {
                      final data = <String, dynamic>{
                        'name': nameC.text,
                        'email': emailC.text,
                        'phone': phoneC.text,
                      };
                      if (dobC.text.isNotEmpty) data['dob'] = dobC.text;
                      if (addressC.text.isNotEmpty) data['address'] = addressC.text;

                      final response = await ApiService.updateProfile(data);
                      if (mounted) {
                        Navigator.pop(ctx);
                        if (response['success'] == true) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Profil berhasil diperbarui!')),
                          );
                          _loadProfile();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(response['message'] ?? 'Gagal memperbarui profil')),
                          );
                        }
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Gagal memperbarui profil')),
                        );
                      }
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentC = TextEditingController();
    final newC = TextEditingController();
    final confirmC = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Ubah Password', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryDarker)),
              const SizedBox(height: 20),
              TextField(
                controller: currentC,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password Saat Ini *', prefixIcon: Icon(Icons.lock_outline, color: AppColors.primaryLight)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newC,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password Baru * (min 8 karakter)', prefixIcon: Icon(Icons.lock, color: AppColors.primaryLight)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmC,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Konfirmasi Password Baru *', prefixIcon: Icon(Icons.lock, color: AppColors.primaryLight)),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (currentC.text.isEmpty || newC.text.isEmpty || confirmC.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Semua field wajib diisi')),
                      );
                      return;
                    }
                    if (newC.text != confirmC.text) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Konfirmasi password tidak cocok')),
                      );
                      return;
                    }
                    if (newC.text.length < 8) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Password minimal 8 karakter')),
                      );
                      return;
                    }
                    try {
                      final response = await ApiService.updatePassword(
                        currentC.text,
                        newC.text,
                        confirmC.text,
                      );
                      if (mounted) {
                        Navigator.pop(ctx);
                        if (response['success'] == true) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Password berhasil diubah!')),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(response['message'] ?? 'Gagal mengubah password')),
                          );
                        }
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Gagal mengubah password')),
                        );
                      }
                    }
                  },
                  child: const Text('Ubah Password'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNotificationSettings() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setLocalState) {
          bool pengingatEnabled = true;
          bool forumEnabled = true;

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Pengaturan Notifikasi', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryDarker)),
                const SizedBox(height: 20),
                SwitchListTile(
                  title: const Text('Pengingat Hewan'),
                  subtitle: const Text('Notifikasi untuk jadwal vaksin, grooming, dll'),
                  value: pengingatEnabled,
                  activeColor: AppColors.primary,
                  onChanged: (v) => setLocalState(() => pengingatEnabled = v),
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile(
                  title: const Text('Aktivitas Forum'),
                  subtitle: const Text('Notifikasi likes dan balasan'),
                  value: forumEnabled,
                  activeColor: AppColors.primary,
                  onChanged: (v) => setLocalState(() => forumEnabled = v),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Pengaturan notifikasi disimpan')),
                      );
                    },
                    child: const Text('Simpan'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showPrivacyInfo() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Privasi', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryDarker)),
            const SizedBox(height: 16),
            const Text(
              'IngonCare menghargai privasi Anda. Data yang kami kumpulkan:',
              style: TextStyle(fontSize: 14, color: AppColors.textBody),
            ),
            const SizedBox(height: 12),
            _privacyItem(Icons.person_outline, 'Informasi profil untuk personalisasi'),
            _privacyItem(Icons.pets, 'Data hewan untuk rekomendasi kesehatan'),
            _privacyItem(Icons.chat_bubble_outline, 'Riwayat chat untuk konteks AI'),
            const SizedBox(height: 16),
            const Text(
              'Kami tidak membagikan data Anda kepada pihak ketiga tanpa izin.',
              style: TextStyle(fontSize: 13, color: AppColors.textGray),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Tutup'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _privacyItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textBody))),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Bantuan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryDarker)),
            const SizedBox(height: 16),
            _helpItem(Icons.pets, 'Hewan', 'Tambah dan kelola data hewan peliharaan'),
            _helpItem(Icons.notifications, 'Pengingat', 'Atur jadwal vaksinasi, grooming, dan kontrol'),
            _helpItem(Icons.chat_bubble, 'AI Chat', 'Tanya seputar kesehatan hewan ke AI'),
            _helpItem(Icons.forum, 'Forum', 'Diskusi dengan sesama pecinta hewan'),
            _helpItem(Icons.assignment, 'Riwayat', 'Catat riwayat kesehatan hewan'),
            const SizedBox(height: 16),
            const Text(
              'Butuh bantuan lebih? Hubungi kami di support@ingoncare.id',
              style: TextStyle(fontSize: 13, color: AppColors.textGray),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Tutup'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _helpItem(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: AppColors.primaryLighter, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.primaryDarker)),
                Text(desc, style: const TextStyle(fontSize: 12, color: AppColors.textGray)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBg,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _loadProfile,
              child: ListView(
                children: [
                  _buildHeader(),
                  _buildStats(),
                  const SizedBox(height: 16),
                  _buildMenuSection(),
                  const SizedBox(height: 16),
                  _buildLogoutButton(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    final user = _profile?['user'];
    return Stack(
      children: [
        Container(
          height: 160,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryDarker, AppColors.primaryDark, AppColors.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 100, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: const [BoxShadow(color: Color(0x309F86C0), blurRadius: 12, offset: Offset(0, 4))],
                  color: AppColors.primaryLighter,
                ),
                child: ClipOval(
                  child: user?['profile_photo'] != null
                      ? Image.network(
                          user['profile_photo'],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 40, color: AppColors.primary),
                        )
                      : const Icon(Icons.person, size: 40, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                user?['name'] ?? 'User',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryDarker),
              ),
              const SizedBox(height: 4),
              Text(
                user?['email'] ?? '',
                style: const TextStyle(fontSize: 14, color: AppColors.textGray),
              ),
              if (user?['address'] != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(user['address'], style: const TextStyle(fontSize: 13, color: AppColors.textGray)),
                  ],
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStats() {
    final stats = _profile?['stats'] ?? {};
    final user = _profile?['user'];
    final userId = user?['id'];
    final userName = user?['name'] ?? 'User';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildStatItem('Postingan', '${stats['total_posts'] ?? 0}', null),
          const SizedBox(width: 10),
          _buildStatItem('Pengikut', '${stats['followers_count'] ?? 0}', userId != null ? () {
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => FollowersFollowingScreen(
                userId: userId,
                username: userName,
                initialTab: 0,
              ),
            ));
          } : null),
          const SizedBox(width: 10),
          _buildStatItem('Mengikuti', '${stats['following_count'] ?? 0}', userId != null ? () {
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => FollowersFollowingScreen(
                userId: userId,
                username: userName,
                initialTab: 1,
              ),
            ));
          } : null),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, VoidCallback? onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primaryLighter, width: 1.5),
          ),
          child: Column(
            children: [
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryDarker)),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textGray)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuSection() {
    final menuItems = [
      {'icon': Icons.person_outline, 'title': 'Edit Profil', 'onTap': _showEditProfileDialog},
      {'icon': Icons.lock_outline, 'title': 'Keamanan', 'onTap': _showChangePasswordDialog},
      {'icon': Icons.notifications_outlined, 'title': 'Notifikasi', 'onTap': _showNotificationSettings},
      {'icon': Icons.shield_outlined, 'title': 'Privasi', 'onTap': _showPrivacyInfo},
      {'icon': Icons.help_outline, 'title': 'Bantuan', 'onTap': _showHelpDialog},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryLighter, width: 1.5),
      ),
      child: Column(
        children: menuItems.asMap().entries.map((entry) {
          final item = entry.value;
          final isLast = entry.key == menuItems.length - 1;
          return Column(
            children: [
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLighter,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item['icon'] as IconData, color: AppColors.primary, size: 20),
                ),
                title: Text(
                  item['title'] as String,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.primaryDarker),
                ),
                trailing: const Icon(Icons.chevron_right, color: AppColors.primaryLight),
                onTap: item['onTap'] as VoidCallback,
              ),
              if (!isLast) Divider(height: 1, color: AppColors.primaryLighter, indent: 68),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryLighter, width: 1.5),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.logout, color: AppColors.danger, size: 20),
        ),
        title: const Text('Keluar', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.danger)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.primaryLight),
        onTap: _logout,
      ),
    );
  }
}
