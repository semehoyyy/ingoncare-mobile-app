import 'package:flutter/material.dart';
import '../../utils/theme.dart';
import '../../services/api_service.dart';
import 'user_profile_screen.dart';

class FollowersFollowingScreen extends StatefulWidget {
  final int userId;
  final String username;
  final int initialTab; // 0 = followers, 1 = following

  const FollowersFollowingScreen({
    super.key,
    required this.userId,
    required this.username,
    this.initialTab = 0,
  });

  @override
  State<FollowersFollowingScreen> createState() => _FollowersFollowingScreenState();
}

class _FollowersFollowingScreenState extends State<FollowersFollowingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _followers = [];
  List<dynamic> _following = [];
  bool _loadingFollowers = true;
  bool _loadingFollowing = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTab);
    _loadFollowers();
    _loadFollowing();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFollowers() async {
    setState(() => _loadingFollowers = true);
    try {
      final response = await ApiService.getFollowers(widget.userId);
      setState(() {
        _followers = response['followers'] ?? [];
        _loadingFollowers = false;
      });
    } catch (e) {
      setState(() => _loadingFollowers = false);
    }
  }

  Future<void> _loadFollowing() async {
    setState(() => _loadingFollowing = true);
    try {
      final response = await ApiService.getFollowing(widget.userId);
      setState(() {
        _following = response['following'] ?? [];
        _loadingFollowing = false;
      });
    } catch (e) {
      setState(() => _loadingFollowing = false);
    }
  }

  Future<void> _toggleFollow(int userId, bool isFollowed, bool isFollowerTab) async {
    try {
      if (isFollowed) {
        await ApiService.unfollowUser(userId);
      } else {
        await ApiService.followUser(userId);
      }
      // Reload both lists
      _loadFollowers();
      _loadFollowing();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBg,
      appBar: AppBar(
        title: Text(widget.username),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryDark,
          unselectedLabelColor: AppColors.textGray,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          tabs: [
            Tab(text: 'Pengikut (${_followers.length})'),
            Tab(text: 'Mengikuti (${_following.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUserList(_followers, _loadingFollowers, true),
          _buildUserList(_following, _loadingFollowing, false),
        ],
      ),
    );
  }

  Widget _buildUserList(List<dynamic> users, bool isLoading, bool isFollowerTab) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline, size: 60, color: AppColors.primaryLight),
            const SizedBox(height: 16),
            Text(
              isFollowerTab ? 'Belum ada pengikut' : 'Belum mengikuti siapapun',
              style: const TextStyle(fontSize: 16, color: AppColors.textGray),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        await _loadFollowers();
        await _loadFollowing();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return _buildUserTile(user, isFollowerTab);
        },
      ),
    );
  }

  Widget _buildUserTile(dynamic user, bool isFollowerTab) {
    final isFollowed = user['is_followed'] == true;
    final isSelf = user['is_self'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryLighter, width: 1.5),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => UserProfileScreen(userId: user['id'])),
              );
            },
            child: CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primaryLighter,
              backgroundImage: user['profile_photo'] != null
                  ? NetworkImage(user['profile_photo'])
                  : null,
              child: user['profile_photo'] == null
                  ? const Icon(Icons.person, color: AppColors.primary, size: 24)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => UserProfileScreen(userId: user['id'])),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user['name'] ?? 'Unknown',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDarker,
                    ),
                  ),
                  if (user['username'] != null)
                    Text(
                      '@${user['username']}',
                      style: const TextStyle(fontSize: 13, color: AppColors.textGray),
                    ),
                ],
              ),
            ),
          ),
          if (!isSelf)
            SizedBox(
              height: 34,
              child: ElevatedButton(
                onPressed: () => _toggleFollow(user['id'], isFollowed, isFollowerTab),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isFollowed ? AppColors.primaryLighter : AppColors.primary,
                  foregroundColor: isFollowed ? AppColors.primaryDark : Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: Text(
                  isFollowed ? 'Unfollow' : 'Follow',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
