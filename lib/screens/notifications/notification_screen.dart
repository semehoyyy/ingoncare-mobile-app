import 'package:flutter/material.dart';
import '../../utils/theme.dart';
import '../../services/api_service.dart';
import '../home/forum_detail_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<dynamic> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getNotifications();
      if (response['success'] == true) {
        setState(() {
          _notifications = response['notifications'] ?? [];
          _unreadCount = response['unread_count'] ?? 0;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAllRead() async {
    try {
      await ApiService.markAllNotificationsRead();
      _loadNotifications();
    } catch (_) {}
  }

  Future<void> _onNotificationTap(dynamic notification) async {
    // Mark as read
    if (notification['is_read'] == false) {
      await ApiService.markNotificationRead(notification['id']);
    }

    // Navigate based on link
    final link = notification['link'] as String?;
    if (link != null && link.startsWith('/forum/') && mounted) {
      final postId = int.tryParse(link.replaceAll('/forum/', ''));
      if (postId != null) {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => ForumDetailScreen(postId: postId),
        ));
      }
    }

    _loadNotifications();
  }

  Future<void> _deleteNotification(int id) async {
    await ApiService.deleteNotification(id);
    _loadNotifications();
  }

  IconData _getNotificationIcon(String? type) {
    switch (type) {
      case 'like':
        return Icons.favorite;
      case 'comment':
        return Icons.chat_bubble;
      case 'follow':
        return Icons.person_add;
      case 'pengingat':
        return Icons.notifications_active;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String? type) {
    switch (type) {
      case 'like':
        return Colors.red;
      case 'comment':
        return AppColors.primary;
      case 'follow':
        return Colors.blue;
      case 'pengingat':
        return Colors.orange;
      default:
        return AppColors.textGray;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBg,
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text('Baca Semua', style: TextStyle(color: AppColors.primary, fontSize: 13)),
            ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadNotifications,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _notifications.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    itemBuilder: (ctx, i) => _buildNotificationCard(_notifications[i]),
                  ),
      ),
    );
  }

  Widget _buildNotificationCard(dynamic notification) {
    final isRead = notification['is_read'] == true;
    final type = notification['type'] as String?;

    return Dismissible(
      key: Key(notification['id'].toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => _deleteNotification(notification['id']),
      child: GestureDetector(
        onTap: () => _onNotificationTap(notification),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isRead ? AppColors.white : AppColors.primarySurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isRead ? AppColors.primaryLighter : AppColors.primaryLight,
              width: 1.5,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getNotificationColor(type).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getNotificationIcon(type),
                  color: _getNotificationColor(type),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification['title'] ?? 'Notifikasi',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                        color: AppColors.primaryDarker,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      notification['message'] ?? '',
                      style: const TextStyle(fontSize: 13, color: AppColors.textBody),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification['time_ago'] ?? '',
                      style: const TextStyle(fontSize: 11, color: AppColors.textGray),
                    ),
                  ],
                ),
              ),
              if (!isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primaryLighter,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.notifications_none, size: 50, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          const Text('Belum ada notifikasi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryDarker)),
          const SizedBox(height: 8),
          const Text('Notifikasi akan muncul saat ada aktivitas.', style: TextStyle(color: AppColors.textGray)),
        ],
      ),
    );
  }
}
