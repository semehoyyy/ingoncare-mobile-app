import 'package:flutter/material.dart';
import '../../utils/theme.dart';
import '../../services/api_service.dart';
import '../social/search_users_screen.dart';
import '../social/user_profile_screen.dart';
import '../notifications/notification_screen.dart';
import 'forum_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _contentController = TextEditingController();
  final _titleController = TextEditingController();
  List<dynamic> _posts = [];
  bool _isLoading = true;
  String _filter = 'terbaru';

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  @override
  void dispose() {
    _contentController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getForumPosts(filter: _filter);
      setState(() {
        _posts = response['posts'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createPost() async {
    if (_contentController.text.trim().isEmpty) return;

    try {
      await ApiService.createForumPost({
        'title': _titleController.text.trim().isNotEmpty ? _titleController.text.trim() : null,
        'content': _contentController.text.trim(),
      });
      _titleController.clear();
      _contentController.clear();
      _loadPosts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal membuat postingan')),
        );
      }
    }
  }

  Future<void> _likePost(int id, int index) async {
    try {
      final response = await ApiService.likeForumPost(id);
      if (response['success'] == true) {
        setState(() {
          _posts[index]['likes_count'] = response['likes_count'];
          _posts[index]['is_liked'] = response['is_liked'];
        });
      }
    } catch (_) {}
  }

  Future<void> _deletePost(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Postingan'),
        content: const Text('Yakin ingin menghapus postingan ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ApiService.deleteForumPost(id);
      _loadPosts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBg,
      appBar: AppBar(
        title: const Text(
          'IngonCare',
          style: TextStyle(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.notifications_outlined, color: AppColors.primaryDark),
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen()));
          },
        ),
        actions: [
          // Search users
          IconButton(
            icon: const Icon(Icons.person_search, color: AppColors.primaryDark),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchUsersScreen()));
            },
          ),
          // Filter chips
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list, color: AppColors.primaryDark),
            onSelected: (value) {
              setState(() => _filter = value);
              _loadPosts();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'terbaru', child: Text('Terbaru')),
              const PopupMenuItem(value: 'trending', child: Text('Trending')),
              const PopupMenuItem(value: 'populer', child: Text('Populer')),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadPosts,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Create Post Card
                  _buildCreatePostCard(),
                  const SizedBox(height: 16),

                  // Posts
                  if (_posts.isEmpty)
                    _buildEmptyState()
                  else
                    ..._posts.asMap().entries.map((entry) => _buildPostCard(entry.value, entry.key)),
                ],
              ),
      ),
    );
  }

  Widget _buildCreatePostCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryLighter, width: 1.5),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Judul diskusi (opsional)...',
                hintStyle: TextStyle(color: AppColors.textGray, fontSize: 14),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: AppColors.primaryDarker,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _contentController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Apa yang ingin kamu diskusikan?',
                hintStyle: TextStyle(color: AppColors.textGray, fontSize: 14),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              style: const TextStyle(fontSize: 14, color: AppColors.textBody),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.primaryLighter, width: 1.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: _createPost,
                  icon: const Icon(Icons.send, size: 16),
                  label: const Text('Posting'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(dynamic post, int index) {
    final user = post['user'];
    final isLiked = post['is_liked'] == true;
    final likesCount = post['likes_count'] ?? 0;
    final repliesCount = post['replies_count'] ?? 0;
    final isOwn = post['is_own'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryLighter, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    if (user?['id'] != null) {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfileScreen(userId: user['id'])));
                    }
                  },
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primaryLighter,
                    backgroundImage: user?['profile_photo'] != null
                        ? NetworkImage(user['profile_photo'])
                        : null,
                    child: user?['profile_photo'] == null
                        ? const Icon(Icons.person, color: AppColors.primary, size: 20)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?['name'] ?? 'Unknown',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.primaryDarker,
                        ),
                      ),
                      Text(
                        post['time_ago'] ?? '',
                        style: const TextStyle(fontSize: 12, color: AppColors.textGray),
                      ),
                    ],
                  ),
                ),
                if (isOwn)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: AppColors.textGray, size: 20),
                    onSelected: (value) {
                      if (value == 'delete') _deletePost(post['id']);
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'delete', child: Text('Hapus')),
                    ],
                  ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (post['title'] != null && post['title'].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      post['title'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDarker,
                      ),
                    ),
                  ),
                Text(
                  post['content'] ?? '',
                  style: const TextStyle(fontSize: 14, color: AppColors.textBody, height: 1.5),
                ),
              ],
            ),
          ),

          // Image
          if (post['image'] != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  post['image'],
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),

          // Actions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.primarySurface,
              border: Border(top: BorderSide(color: AppColors.primaryLighter, width: 1.5)),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _likePost(post['id'], index),
                  child: Row(
                    children: [
                      Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        size: 20,
                        color: isLiked ? AppColors.primary : AppColors.textGray,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$likesCount',
                        style: TextStyle(
                          fontSize: 13,
                          color: isLiked ? AppColors.primary : AppColors.textGray,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => ForumDetailScreen(postId: post['id']),
                    ));
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline, size: 20, color: AppColors.textGray),
                      const SizedBox(width: 4),
                      Text('$repliesCount', style: const TextStyle(fontSize: 13, color: AppColors.textGray)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            const Icon(Icons.forum_outlined, size: 60, color: AppColors.primaryLight),
            const SizedBox(height: 16),
            const Text(
              'Belum ada diskusi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryDarker),
            ),
            const SizedBox(height: 8),
            const Text(
              'Jadilah yang pertama memulai!',
              style: TextStyle(fontSize: 14, color: AppColors.textGray),
            ),
          ],
        ),
      ),
    );
  }
}
