import 'package:flutter/material.dart';
import '../../utils/theme.dart';
import '../../services/api_service.dart';
import '../social/user_profile_screen.dart';

class ForumDetailScreen extends StatefulWidget {
  final int postId;
  const ForumDetailScreen({super.key, required this.postId});

  @override
  State<ForumDetailScreen> createState() => _ForumDetailScreenState();
}

class _ForumDetailScreenState extends State<ForumDetailScreen> {
  final _replyController = TextEditingController();
  Map<String, dynamic>? _post;
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadPost();
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _loadPost() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getForumPost(widget.postId);
      if (response['success'] == true) {
        setState(() {
          _post = response['post'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendReply() async {
    if (_replyController.text.trim().isEmpty) return;

    setState(() => _isSending = true);
    try {
      final response = await ApiService.createForumPost({
        'content': _replyController.text.trim(),
        'parent_id': widget.postId.toString(),
      });
      if (response['success'] == true) {
        _replyController.clear();
        _loadPost();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? 'Gagal mengirim balasan')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengirim balasan')),
        );
      }
    }
    setState(() => _isSending = false);
  }

  Future<void> _likePost(int id) async {
    try {
      final response = await ApiService.likeForumPost(id);
      if (response['success'] == true) {
        _loadPost();
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBg,
      appBar: AppBar(
        title: const Text('Detail Diskusi'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _post == null
              ? const Center(child: Text('Postingan tidak ditemukan'))
              : Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadPost,
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            // Original Post
                            _buildOriginalPost(),
                            const SizedBox(height: 16),

                            // Replies header
                            Text(
                              'Balasan (${(_post!['replies'] as List?)?.length ?? 0})',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryDarker,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Replies
                            if (_post!['replies'] != null && (_post!['replies'] as List).isNotEmpty)
                              ...(_post!['replies'] as List).map((reply) => _buildReplyCard(reply))
                            else
                              const Padding(
                                padding: EdgeInsets.all(20),
                                child: Center(
                                  child: Text(
                                    'Belum ada balasan. Jadilah yang pertama!',
                                    style: TextStyle(color: AppColors.textGray),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // Reply input
                    _buildReplyInput(),
                  ],
                ),
    );
  }

  Widget _buildOriginalPost() {
    final user = _post!['user'];
    final isLiked = _post!['is_liked'] == true;
    final likesCount = _post!['likes_count'] ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryLighter, width: 1.5),
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
                      Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfileScreen(userId: user['id'])));
                    }
                  },
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primaryLighter,
                    backgroundImage: user?['profile_photo'] != null ? NetworkImage(user['profile_photo']) : null,
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
                      Text(user?['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryDarker)),
                      Text(_post!['time_ago'] ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textGray)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_post!['title'] != null && _post!['title'].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(_post!['title'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryDarker)),
                  ),
                Text(_post!['content'] ?? '', style: const TextStyle(fontSize: 14, color: AppColors.textBody, height: 1.5)),
              ],
            ),
          ),
          if (_post!['image'] != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(_post!['image'], width: double.infinity, height: 200, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
              ),
            ),
          // Like button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: GestureDetector(
              onTap: () => _likePost(_post!['id']),
              child: Row(
                children: [
                  Icon(isLiked ? Icons.favorite : Icons.favorite_border, size: 22, color: isLiked ? AppColors.primary : AppColors.textGray),
                  const SizedBox(width: 6),
                  Text('$likesCount suka', style: TextStyle(fontSize: 13, color: isLiked ? AppColors.primary : AppColors.textGray)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyCard(dynamic reply) {
    final user = reply['user'];
    final isLiked = reply['is_liked'] == true;
    final likesCount = reply['likes_count'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryLighter),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  if (user?['id'] != null) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfileScreen(userId: user['id'])));
                  }
                },
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primaryLighter,
                  backgroundImage: user?['profile_photo'] != null ? NetworkImage(user['profile_photo']) : null,
                  child: user?['profile_photo'] == null
                      ? const Icon(Icons.person, color: AppColors.primary, size: 16)
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user?['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.primaryDarker)),
                    Text(reply['time_ago'] ?? '', style: const TextStyle(fontSize: 11, color: AppColors.textGray)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(reply['content'] ?? '', style: const TextStyle(fontSize: 14, color: AppColors.textBody, height: 1.4)),
          if (reply['image'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(reply['image'], height: 120, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
              ),
            ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _likePost(reply['id']),
            child: Row(
              children: [
                Icon(isLiked ? Icons.favorite : Icons.favorite_border, size: 16, color: isLiked ? AppColors.primary : AppColors.textGray),
                const SizedBox(width: 4),
                Text('$likesCount', style: TextStyle(fontSize: 12, color: isLiked ? AppColors.primary : AppColors.textGray)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyInput() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).viewInsets.bottom + 12),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.primaryLighter, width: 1.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _replyController,
              decoration: InputDecoration(
                hintText: 'Tulis balasan...',
                hintStyle: const TextStyle(color: AppColors.textGray, fontSize: 14),
                filled: true,
                fillColor: AppColors.primarySurface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _isSending ? null : _sendReply,
            icon: _isSending
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                : const Icon(Icons.send, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
