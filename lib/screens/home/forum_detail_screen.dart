import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  final _focusNode = FocusNode();

  Map<String, dynamic>? _post;
  bool _isLoading = true;
  bool _isSending = false;

  int? _selectedReplyToId;
  String? _replyingToName;

  File? _localProfileImage;
  int? _currentUserId;

  // ✅ Local state untuk like — tidak akan di-reset oleh _loadPost()
  final Map<int, bool> _likedState = {};
  final Map<int, int> _likesCount = {};

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _replyController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await _loadSavedProfileImage();
    await _loadCurrentUser();
    await _loadPost();
  }

  Future<void> _loadSavedProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPath = prefs.getString('profile_image_path');
    if (savedPath != null && savedPath.isNotEmpty) {
      final file = File(savedPath);
      if (await file.exists()) {
        if (!mounted) return;
        setState(() => _localProfileImage = file);
      }
    }
  }

  Future<void> _loadCurrentUser() async {
    try {
      final response = await ApiService.getProfile();
      final user = response['user'];
      if (user != null && mounted) {
        setState(() {
          _currentUserId = int.tryParse(user['id'].toString());
        });
      }
    } catch (_) {}
  }

  // ✅ Sync local state dari API, tapi HANYA kalau belum ada — supaya tidak di-overwrite
  void _syncLikeState(Map<String, dynamic> item) {
    final id = item['id'] as int;
    if (!_likedState.containsKey(id)) {
      _likedState[id] = item['is_liked'] == true || item['is_liked'] == 1;
      _likesCount[id] = item['likes_count'] ?? 0;
    }
  }

  Future<void> _loadPost() async {
    if (_post == null) setState(() => _isLoading = true);
    try {
      final response = await ApiService.getForumPost(widget.postId);
      if (mounted && response['success'] == true) {
        final post = response['post'];

        // Sync like state dari API untuk post utama
        _syncLikeState(post);

        // Sync like state dari API untuk semua replies (flat)
        if (post['replies'] != null) {
          for (var reply in post['replies']) {
            _syncLikeState(reply);
            if (reply['replies'] != null) {
              for (var sub in reply['replies']) {
                _syncLikeState(sub);
              }
            }
          }
        }

        setState(() {
          _post = post;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _initiateReply(int replyId, String userName) {
    setState(() {
      _selectedReplyToId = replyId;
      _replyingToName = userName;
    });
    FocusScope.of(context).requestFocus(_focusNode);
  }

  Future<void> _sendReply() async {
    if (_replyController.text.trim().isEmpty) return;
    setState(() => _isSending = true);

    try {
      final response = await ApiService.createForumPost({
        'content': _replyController.text.trim(),
        'parent_id': _post!['id'],
        'reply_to_id': _selectedReplyToId,
      });

      if (mounted && response['success'] == true) {
        _replyController.clear();
        FocusScope.of(context).unfocus();
        setState(() {
          _selectedReplyToId = null;
          _replyingToName = null;
        });
        await _loadPost();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengirim balasan')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  // ✅ Like pakai local state — tidak bergantung data dari _post map
  Future<void> _likePost(int id) async {
    final currentlyLiked = _likedState[id] ?? false;
    final currentCount = _likesCount[id] ?? 0;

    // Update UI seketika (optimistic)
    setState(() {
      _likedState[id] = !currentlyLiked;
      _likesCount[id] = currentCount + (currentlyLiked ? -1 : 1);
    });

    try {
      await ApiService.likeForumPost(id);
      // Tidak perlu _loadPost() di sini — UI sudah benar
    } catch (_) {
      // Rollback kalau server error
      setState(() {
        _likedState[id] = currentlyLiked;
        _likesCount[id] = currentCount;
      });
    }
  }

  List<Widget> _buildStructuredComments() {
    if (_post!['replies'] == null || (_post!['replies'] as List).isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: Text(
              'Belum ada komentar. Tulis sesuatu...',
              style: TextStyle(color: AppColors.textGray),
            ),
          ),
        )
      ];
    }

    List<dynamic> allReplies = List.from(_post!['replies']);
    List<Widget> commentTreeWidgets = [];

    var rootComments =
        allReplies.where((r) => r['reply_to_id'] == null).toList();

    if (rootComments.isEmpty && allReplies.isNotEmpty) {
      return allReplies
          .expand((reply) => _renderCommentNode(reply, 0, allReplies))
          .toList();
    }

    for (var root in rootComments) {
      commentTreeWidgets.addAll(_renderCommentNode(root, 0, allReplies));
    }

    return commentTreeWidgets;
  }

  List<Widget> _renderCommentNode(
      dynamic reply, double depth, List<dynamic> allReplies) {
    List<Widget> nodes = [];
    nodes.add(_buildCommentTile(reply, depth));

    var children =
        allReplies.where((r) => r['reply_to_id'] == reply['id']).toList();
    for (var child in children) {
      double nextDepth = depth < 3 ? depth + 1 : depth;
      nodes.addAll(_renderCommentNode(child, nextDepth, allReplies));
    }

    return nodes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBg,
      appBar: AppBar(title: const Text('Detail Diskusi')),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _post == null
              ? const Center(child: Text('Postingan tidak ditemukan'))
              : Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: _loadPost,
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            _buildOriginalPost(),
                            const SizedBox(height: 16),
                            Text(
                              'Komentar',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textGray.withOpacity(0.8),
                              ),
                            ),
                            const SizedBox(height: 12),
                            ..._buildStructuredComments(),
                          ],
                        ),
                      ),
                    ),
                    _buildReplyInput(),
                  ],
                ),
    );
  }

  Widget _buildOriginalPost() {
    final user = _post?['user'] ?? {};
    // ✅ Baca dari local state
    final isLiked = _likedState[_post!['id']] ?? false;
    final likesCount = _likesCount[_post!['id']] ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildAvatar(user, 20),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user['name'] ?? 'User',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(_post!['time_ago'] ?? '',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textGray)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(_post!['content'] ?? '',
              style: const TextStyle(fontSize: 15, height: 1.4)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _likePost(_post!['id']),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked ? Colors.red : AppColors.textGray,
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text('$likesCount suka',
                    style: const TextStyle(fontSize: 13)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCommentTile(dynamic reply, double depth) {
    final user = reply['user'] ?? {};
    // ✅ Baca dari local state
    final isLiked = _likedState[reply['id']] ?? false;
    final likesCount = _likesCount[reply['id']] ?? 0;
    final String? mention = reply['mention'];

    return Container(
      margin: EdgeInsets.only(left: depth * 24, bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(user, 16),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                        fontSize: 13.5, color: Colors.black, height: 1.3),
                    children: [
                      TextSpan(
                          text: '${user['name'] ?? 'User'} ',
                          style:
                              const TextStyle(fontWeight: FontWeight.bold)),
                      if (mention != null && mention.isNotEmpty)
                        TextSpan(
                            text: '@$mention ',
                            style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.w500)),
                      TextSpan(text: reply['content'] ?? ''),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(reply['time_ago'] ?? 'Now',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textGray)),
                    if (likesCount > 0) ...[
                      const SizedBox(width: 12),
                      Text('$likesCount suka',
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textGray,
                              fontWeight: FontWeight.bold)),
                    ],
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () =>
                          _initiateReply(reply['id'], user['name'] ?? 'User'),
                      child: const Text('Balas',
                          style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textGray,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                )
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _likePost(reply['id']),
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                size: 15,
                color: isLiked ? Colors.red : AppColors.textGray,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildReplyInput() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_replyingToName != null)
          Container(
            color: Colors.grey[100],
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                Expanded(
                    child: Text('Membalas @$_replyingToName',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textGray))),
                GestureDetector(
                  onTap: () => setState(() {
                    _selectedReplyToId = null;
                    _replyingToName = null;
                  }),
                  child: const Icon(Icons.close,
                      size: 16, color: AppColors.textGray),
                )
              ],
            ),
          ),
        Container(
          padding: EdgeInsets.fromLTRB(
              16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 12),
          color: AppColors.white,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _replyController,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: _replyingToName != null
                        ? 'Balas @$_replyingToName...'
                        : 'Tambahkan komentar...',
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              IconButton(
                onPressed: _isSending ? null : _sendReply,
                icon: _isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.send, color: AppColors.primary),
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(dynamic user, double radius) {
    if (user?['profile_photo'] != null) {
      return CircleAvatar(
          radius: radius,
          backgroundImage: NetworkImage(user['profile_photo']));
    }
    return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey[300],
        child: Icon(Icons.person, size: radius * 1.2, color: Colors.white));
  }
}