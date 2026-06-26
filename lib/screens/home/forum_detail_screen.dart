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

  Future<void> _loadPost() async {
    if (_post == null) setState(() => _isLoading = true);
    try {
      final response = await ApiService.getForumPost(widget.postId);
      if (mounted && response['success'] == true) {
        setState(() {
          _post = response['post'];
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

  // 🔹 FIX 1: Mengunci State Love di UI agar Tidak Tergantung/Ter-reset data Null dari API
  Future<void> _likePost(int id) async {
    if (_post == null) return;

    // Fungsi lokal untuk mengubah data secara instan
    void toggleLike(Map<String, dynamic> item) {
      final bool currentlyLiked = item['is_liked'] == true || item['is_liked'] == 1;
      item['is_liked'] = !currentlyLiked;
      item['likes_count'] = (item['likes_count'] ?? 0) + (currentlyLiked ? -1 : 1);
    }

    setState(() {
      if (_post!['id'] == id) {
        toggleLike(_post!);
      } else if (_post!['replies'] != null) {
        for (var reply in _post!['replies']) {
          if (reply['id'] == id) {
            toggleLike(reply);
            break;
          }
          // Antisipasi jika data bertingkat
          if (reply['replies'] != null) {
            for (var sub in reply['replies']) {
              if (sub['id'] == id) { toggleLike(sub); break; }
            }
          }
        }
      }
    });

    try {
      // Tembak API di background
      await ApiService.likeForumPost(id);
      // Opsional: hapus `await _loadPost()` di sini jika API kamu mengembalikan data lama/null 
      // yang malah merusak UI yang sudah benar.
    } catch (_) {
      // Rollback jika server error
      await _loadPost();
    }
  }

  // 🔹 FIX 2: Mesin Penyusun Komentar Bertingkat (Mengatasi Data Backend yang Flat/Mendatar)
  List<Widget> _buildStructuredComments() {
    if (_post!['replies'] == null || (_post!['replies'] as List).isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: Text('Belum ada komentar. Tulis sesuatu...', style: TextStyle(color: AppColors.textGray))),
        )
      ];
    }

    List<dynamic> allReplies = List.from(_post!['replies']);
    List<Widget> commentTreeWidgets = [];

    // 1. Ambil komentar utama (yang tidak membalas komentar lain / reply_to_id null)
    var rootComments = allReplies.where((r) => r['reply_to_id'] == null).toList();

    // Jika backend ternyata bertingkat (tidak flat), langsung petakan seperti biasa
    if (rootComments.isEmpty && allReplies.isNotEmpty) {
  return allReplies.expand((reply) => _renderCommentNode(reply, 0, allReplies)).toList();
}
    for (var root in rootComments) {
      commentTreeWidgets.addAll(_renderCommentNode(root, 0, allReplies));
    }

    return commentTreeWidgets;
  }

  List<Widget> _renderCommentNode(dynamic reply, double depth, List<dynamic> allReplies) {
    List<Widget> nodes = [];
    
    // Tambahkan komponen komentar saat ini
    nodes.add(_buildCommentTile(reply, depth));

    // Cari anak balasan dari komentar ini berdasarkan id di list datar (Flat Array)
    var children = allReplies.where((r) => r['reply_to_id'] == reply['id']).toList();
    for (var child in children) {
      double nextDepth = depth < 3 ? depth + 1 : depth; // Batasi geser kanan maks 3 tingkat
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
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
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
                            // Memanggil generator struktur pohon komentar yang baru
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
    final isLiked = _post!['is_liked'] == true || _post!['is_liked'] == 1;
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
                  Text(user['name'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(_post!['time_ago'] ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textGray)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(_post!['content'] ?? '', style: const TextStyle(fontSize: 15, height: 1.4)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _likePost(_post!['id']),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: isLiked ? Colors.red : AppColors.textGray, size: 20),
                const SizedBox(width: 4),
                Text('${_post!['likes_count'] ?? 0} suka', style: const TextStyle(fontSize: 13)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCommentTile(dynamic reply, double depth) {
    final user = reply['user'] ?? {};
    // Pengecekan boolean fleksibel (mengantisipasi jika API mengirim data integer 1/0 atau boolean)
    final isLiked = reply['is_liked'] == true || reply['is_liked'] == 1;
    final String? mention = reply['mention'];

    return Container(
      // Margin kiri dinamis dikalikan 24 pixel per kedalaman balasan
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
                    style: const TextStyle(fontSize: 13.5, color: Colors.black, height: 1.3),
                    children: [
                      TextSpan(text: '${user['name'] ?? 'User'} ', style: const TextStyle(fontWeight: FontWeight.bold)),
                      if (mention != null && mention.isNotEmpty)
                        TextSpan(text: '@$mention ', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w500)),
                      TextSpan(text: reply['content'] ?? ''),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(reply['time_ago'] ?? 'Now', style: const TextStyle(fontSize: 11, color: AppColors.textGray)),
                    if ((reply['likes_count'] ?? 0) > 0) ...[
                      const SizedBox(width: 12),
                      Text('${reply['likes_count']} suka', style: const TextStyle(fontSize: 11, color: AppColors.textGray, fontWeight: FontWeight.bold)),
                    ],
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => _initiateReply(reply['id'], user['name'] ?? 'User'),
                      child: const Text('Balas', style: TextStyle(fontSize: 11, color: AppColors.textGray, fontWeight: FontWeight.bold)),
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
                Expanded(child: Text('Membalas @$_replyingToName', style: const TextStyle(fontSize: 12, color: AppColors.textGray))),
                GestureDetector(
                  onTap: () => setState(() {
                    _selectedReplyToId = null;
                    _replyingToName = null;
                  }),
                  child: const Icon(Icons.close, size: 16, color: AppColors.textGray),
                )
              ],
            ),
          ),
        Container(
          padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 12),
          color: AppColors.white,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _replyController,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: _replyingToName != null ? 'Balas @$_replyingToName...' : 'Tambahkan komentar...',
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              IconButton(
                onPressed: _isSending ? null : _sendReply,
                icon: _isSending 
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
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
      return CircleAvatar(radius: radius, backgroundImage: NetworkImage(user['profile_photo']));
    }
    return CircleAvatar(radius: radius, backgroundColor: Colors.grey[300], child: Icon(Icons.person, size: radius * 1.2, color: Colors.white));
  }
}