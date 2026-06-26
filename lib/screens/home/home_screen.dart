import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  File? _localProfileImage;
  File? _selectedPostImage;

  int? _currentUserId;
  String? _currentUserEmail;
  String? _currentUserName;

  int _unreadNotificationCount = 0;

  static const String _profileImageKey = 'profile_image_path';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _contentController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await _loadSavedProfileImage();
    await _loadCurrentUser();
    await _loadUnreadNotifications();
    await _loadPosts();
  }

  Future<void> _loadSavedProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPath = prefs.getString(_profileImageKey);

    if (savedPath != null && savedPath.isNotEmpty) {
      final file = File(savedPath);

      if (await file.exists()) {
        if (!mounted) return;
        setState(() {
          _localProfileImage = file;
        });
      }
    }
  }

  Future<void> _loadCurrentUser() async {
    try {
      final response = await ApiService.getProfile();
      final user = response['user'];

      if (user != null) {
        if (!mounted) return;

        setState(() {
          _currentUserId = user['id'] != null
              ? int.tryParse(user['id'].toString())
              : null;
          _currentUserEmail = user['email']?.toString();
          _currentUserName = user['name']?.toString();
        });
      }
    } catch (_) {}
  }

  Future<void> _loadUnreadNotifications() async {
    try {
      final response = await ApiService.getNotifications();

      if (response['success'] == true) {
        if (!mounted) return;

        setState(() {
          _unreadNotificationCount = response['unread_count'] ?? 0;
        });
      }
    } catch (_) {}
  }

  bool _isCurrentUserPost(dynamic user, bool isOwn) {
    if (isOwn) return true;

    final int? postUserId = user?['id'] != null
        ? int.tryParse(user['id'].toString())
        : null;

    final String? postUserEmail = user?['email']?.toString();
    final String? postUserName = user?['name']?.toString();

    if (_currentUserId != null && postUserId != null) {
      return _currentUserId == postUserId;
    }

    if (_currentUserEmail != null &&
        postUserEmail != null &&
        _currentUserEmail == postUserEmail) {
      return true;
    }

    if (_currentUserName != null &&
        postUserName != null &&
        _currentUserName == postUserName) {
      return true;
    }

    return false;
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoading = true);

    await _loadSavedProfileImage();
    await _loadCurrentUser();
    await _loadUnreadNotifications();

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

  Future<void> _pickPostImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.camera_alt_outlined,
                    color: AppColors.primary,
                  ),
                  title: const Text('Ambil dari Kamera'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.photo_library_outlined,
                    color: AppColors.primary,
                  ),
                  title: const Text('Pilih dari Galeri'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source == null) return;

    try {
      final picker = ImagePicker();

      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 75,
      );

      if (pickedFile == null) return;

      setState(() {
        _selectedPostImage = File(pickedFile.path);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengambil foto: $e')),
        );
      }
    }
  }

  void _removeSelectedPostImage() {
    setState(() {
      _selectedPostImage = null;
    });
  }

  Future<void> _createPost() async {
    if (_contentController.text.trim().isEmpty) return;

    try {
      final response = await ApiService.createForumPost(
        {
          'title': _titleController.text.trim().isNotEmpty
              ? _titleController.text.trim()
              : null,
          'content': _contentController.text.trim(),
        },
        imagePath: _selectedPostImage?.path,
      );

      if (response['success'] == true || response['post'] != null) {
        _titleController.clear();
        _contentController.clear();

        setState(() {
          _selectedPostImage = null;
        });

        _loadPosts();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Gagal membuat postingan'),
            ),
          );
        }
      }
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

        _loadUnreadNotifications();
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
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Hapus',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ApiService.deleteForumPost(id);
      _loadPosts();
    }
  }

  Widget _buildPostAvatar(dynamic user, bool isOwn) {
    final profilePhoto = user?['profile_photo'];
    final bool isCurrentUser = _isCurrentUserPost(user, isOwn);

    if (isCurrentUser && _localProfileImage != null) {
      return CircleAvatar(
        radius: 20,
        backgroundColor: AppColors.primaryLighter,
        backgroundImage: FileImage(_localProfileImage!),
      );
    }

    if (profilePhoto != null && profilePhoto.toString().isNotEmpty) {
      return CircleAvatar(
        radius: 20,
        backgroundColor: AppColors.primaryLighter,
        backgroundImage: NetworkImage(profilePhoto.toString()),
      );
    }

    return const CircleAvatar(
      radius: 20,
      backgroundColor: AppColors.primaryLighter,
      child: Icon(
        Icons.person,
        color: AppColors.primary,
        size: 20,
      ),
    );
  }

  Widget _buildNotificationIcon() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(
          Icons.notifications_outlined,
          color: AppColors.primaryDark,
        ),
        if (_unreadNotificationCount > 0)
          Positioned(
            right: -6,
            top: -6,
            child: Container(
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                _unreadNotificationCount > 99
                    ? '99+'
                    : '$_unreadNotificationCount',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
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
          icon: _buildNotificationIcon(),
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const NotificationScreen(),
              ),
            );

            _loadUnreadNotifications();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.person_search,
              color: AppColors.primaryDark,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SearchUsersScreen(),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.filter_list,
              color: AppColors.primaryDark,
            ),
            onSelected: (value) {
              setState(() => _filter = value);
              _loadPosts();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'terbaru',
                child: Text('Terbaru'),
              ),
              const PopupMenuItem(
                value: 'trending',
                child: Text('Trending'),
              ),
              const PopupMenuItem(
                value: 'populer',
                child: Text('Populer'),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadPosts,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildCreatePostCard(),
                  const SizedBox(height: 16),
                  if (_posts.isEmpty)
                    _buildEmptyState()
                  else
                    ..._posts.asMap().entries.map(
                          (entry) => _buildPostCard(
                            entry.value,
                            entry.key,
                          ),
                        ),
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
        border: Border.all(
          color: AppColors.primaryLighter,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Judul diskusi (opsional)...',
                hintStyle: TextStyle(
                  color: AppColors.textGray,
                  fontSize: 14,
                ),
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
                hintStyle: TextStyle(
                  color: AppColors.textGray,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textBody,
              ),
            ),
          ),
          if (_selectedPostImage != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _selectedPostImage!,
                      width: double.infinity,
                      height: 160,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: _removeSelectedPostImage,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: AppColors.primaryLighter,
                  width: 1.5,
                ),
              ),
            ),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: _pickPostImage,
                  icon: const Icon(
                    Icons.image_outlined,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  label: const Text(
                    'Foto',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _createPost,
                  icon: const Icon(Icons.send, size: 16),
                  label: const Text('Posting'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
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
        border: Border.all(
          color: AppColors.primaryLighter,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    if (user?['id'] != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UserProfileScreen(
                            userId: user['id'],
                          ),
                        ),
                      );
                    }
                  },
                  child: _buildPostAvatar(user, isOwn),
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
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textGray,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isOwn)
                  PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_vert,
                      color: AppColors.textGray,
                      size: 20,
                    ),
                    onSelected: (value) {
                      if (value == 'delete') _deletePost(post['id']);
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Hapus'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (post['title'] != null &&
                    post['title'].toString().isNotEmpty)
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
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textBody,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          if (post['image'] != null && post['image'].toString().isNotEmpty)
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
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            decoration: const BoxDecoration(
              color: AppColors.primarySurface,
              border: Border(
                top: BorderSide(
                  color: AppColors.primaryLighter,
                  width: 1.5,
                ),
              ),
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
                        color: isLiked
                            ? AppColors.primary
                            : AppColors.textGray,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$likesCount',
                        style: TextStyle(
                          fontSize: 13,
                          color: isLiked
                              ? AppColors.primary
                              : AppColors.textGray,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ForumDetailScreen(
                          postId: post['id'],
                        ),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline,
                        size: 20,
                        color: AppColors.textGray,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$repliesCount',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textGray,
                        ),
                      ),
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
            const Icon(
              Icons.forum_outlined,
              size: 60,
              color: AppColors.primaryLight,
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum ada diskusi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDarker,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Jadilah yang pertama memulai!',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textGray,
              ),
            ),
          ],
        ),
      ),
    );
  }
}