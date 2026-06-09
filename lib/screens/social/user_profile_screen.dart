import 'package:flutter/material.dart';
import '../../utils/theme.dart';
import '../../services/api_service.dart';
import 'followers_following_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final int userId;
  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  Map<String, dynamic>? _user;
  List<dynamic> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getUserProfile(widget.userId);
      setState(() {
        _user = response['user'];
        _posts = response['posts'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFollow() async {
    if (_user == null) return;
    final isFollowed = _user!['is_followed'] == true;

    try {
      if (isFollowed) {
        await ApiService.unfollowUser(widget.userId);
      } else {
        await ApiService.followUser(widget.userId);
      }
      setState(() {
        _user!['is_followed'] = !isFollowed;
        _user!['followers_count'] = (_user!['followers_count'] ?? 0) + (isFollowed ? -1 : 1);
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBg,
      appBar: AppBar(
        title: Text(_user?['name'] ?? 'Profil'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _loadProfile,
              color: AppColors.primary,
              child: ListView(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  // Posts
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Postingan (${_posts.length})',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryDarker),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_posts.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text('Belum ada postingan', style: TextStyle(color: AppColors.textGray)),
                      ),
                    )
                  else
                    ..._posts.map((post) => _buildPostCard(post)),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    final isFollowed = _user?['is_followed'] == true;
    final isSelf = _user?['is_self'] == true;

    return Column(
      children: [
        // Cover
        Container(
          height: 120,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryDarker, AppColors.primaryDark, AppColors.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        // Avatar & Info
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Transform.translate(
                offset: const Offset(0, -40),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        color: AppColors.primaryLighter,
                      ),
                      child: ClipOval(
                        child: _user?['profile_photo'] != null
                            ? Image.network(
                                _user!['profile_photo'],
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 36, color: AppColors.primary),
                              )
                            : const Icon(Icons.person, size: 36, color: AppColors.primary),
                      ),
                    ),
                    const Spacer(),
                    if (!isSelf)
                      ElevatedButton(
                        onPressed: _toggleFollow,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isFollowed ? AppColors.primaryLighter : AppColors.primary,
                          foregroundColor: isFollowed ? AppColors.primaryDark : Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: Text(isFollowed ? 'Unfollow' : 'Follow', style: const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                  ],
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _user?['name'] ?? '',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryDarker),
                    ),
                    if (_user?['address'] != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(_user!['address'], style: const TextStyle(fontSize: 13, color: AppColors.textGray)),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    // Stats
                    Row(
                      children: [
                        _buildStat('${_user?['posts_count'] ?? 0}', 'Postingan', null),
                        const SizedBox(width: 24),
                        _buildStat('${_user?['followers_count'] ?? 0}', 'Pengikut', () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => FollowersFollowingScreen(
                              userId: widget.userId,
                              username: _user?['name'] ?? '',
                              initialTab: 0,
                            ),
                          ));
                        }),
                        const SizedBox(width: 24),
                        _buildStat('${_user?['following_count'] ?? 0}', 'Mengikuti', () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => FollowersFollowingScreen(
                              userId: widget.userId,
                              username: _user?['name'] ?? '',
                              initialTab: 1,
                            ),
                          ));
                        }),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStat(String value, String label, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryDarker)),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textGray)),
        ],
      ),
    );
  }

  Widget _buildPostCard(dynamic post) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryLighter, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post['title'] != null && post['title'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                post['title'],
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryDarker),
              ),
            ),
          Text(
            post['content'] ?? '',
            style: const TextStyle(fontSize: 14, color: AppColors.textBody, height: 1.5),
          ),
          if (post['image'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  post['image'],
                  width: double.infinity,
                  height: 160,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                post['is_liked'] == true ? Icons.favorite : Icons.favorite_border,
                size: 18,
                color: post['is_liked'] == true ? AppColors.primary : AppColors.textGray,
              ),
              const SizedBox(width: 4),
              Text('${post['likes_count'] ?? 0}', style: const TextStyle(fontSize: 12, color: AppColors.textGray)),
              const SizedBox(width: 16),
              const Icon(Icons.chat_bubble_outline, size: 18, color: AppColors.textGray),
              const SizedBox(width: 4),
              Text('${post['replies_count'] ?? 0}', style: const TextStyle(fontSize: 12, color: AppColors.textGray)),
              const Spacer(),
              Text(post['time_ago'] ?? '', style: const TextStyle(fontSize: 11, color: AppColors.textGray)),
            ],
          ),
        ],
      ),
    );
  }
}
