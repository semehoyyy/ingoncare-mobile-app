import 'package:flutter/material.dart';
import '../../utils/theme.dart';
import '../../services/api_service.dart';
import 'user_profile_screen.dart';

class SearchUsersScreen extends StatefulWidget {
  const SearchUsersScreen({super.key});

  @override
  State<SearchUsersScreen> createState() => _SearchUsersScreenState();
}

class _SearchUsersScreenState extends State<SearchUsersScreen> {
  final _searchController = TextEditingController();
  List<dynamic> _users = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.length < 2) {
      setState(() => _users = []);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.searchUsers(query);
      setState(() {
        _users = response['users'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFollow(int index) async {
    final user = _users[index];
    final isFollowed = user['is_followed'] == true;

    try {
      if (isFollowed) {
        await ApiService.unfollowUser(user['id']);
      } else {
        await ApiService.followUser(user['id']);
      }
      setState(() {
        _users[index]['is_followed'] = !isFollowed;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBg,
      appBar: AppBar(
        title: const Text('Cari Pengguna'),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _search,
              decoration: InputDecoration(
                hintText: 'Cari nama atau email...',
                prefixIcon: const Icon(Icons.search, color: AppColors.primaryLight),
                filled: true,
                fillColor: AppColors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.primaryLighter, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.primaryLighter, width: 1.5),
                ),
              ),
            ),
          ),

          // Results
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _users.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.person_search, size: 60, color: AppColors.primaryLight),
                            const SizedBox(height: 16),
                            Text(
                              _searchController.text.isEmpty
                                  ? 'Ketik minimal 2 huruf untuk mencari'
                                  : 'Tidak ada hasil',
                              style: const TextStyle(color: AppColors.textGray),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _users.length,
                        itemBuilder: (ctx, i) => _buildUserCard(_users[i], i),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(dynamic user, int index) {
    final isFollowed = user['is_followed'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryLighter, width: 1.5),
      ),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => UserProfileScreen(userId: user['id'])),
          );
        },
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.primaryLighter,
          backgroundImage: user['profile_photo'] != null
              ? NetworkImage(user['profile_photo'])
              : null,
          child: user['profile_photo'] == null
              ? const Icon(Icons.person, color: AppColors.primary)
              : null,
        ),
        title: Text(
          user['name'] ?? '',
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDarker),
        ),
        subtitle: Text(
          '${user['email'] ?? ''} · ${user['followers_count'] ?? 0} pengikut',
          style: const TextStyle(fontSize: 12, color: AppColors.textGray),
        ),
        trailing: ElevatedButton(
          onPressed: () => _toggleFollow(index),
          style: ElevatedButton.styleFrom(
            backgroundColor: isFollowed ? AppColors.primaryLighter : AppColors.primary,
            foregroundColor: isFollowed ? AppColors.primaryDark : Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
          child: Text(isFollowed ? 'Unfollow' : 'Follow', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}
