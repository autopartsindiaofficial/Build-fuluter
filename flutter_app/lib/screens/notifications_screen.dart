import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
  });
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = false;

  final List<NotificationItem> _notifications = [
    NotificationItem(
      id: '1',
      title: 'Welcome to Auto Parts Marketplace!',
      message: 'Explore thousands of genuine spare parts across India. You can buy directly or list your parts for sale.',
      createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
      isRead: false,
    ),
    NotificationItem(
      id: '2',
      title: 'Real-time Chat & Price Negotiation',
      message: 'You can now make price offers and chat directly with sellers in real-time.',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      isRead: false,
    ),
    NotificationItem(
      id: '3',
      title: 'Verified Sellers Across All States',
      message: 'New verified sellers from Chennai, Coimbatore, Delhi and Mumbai have joined the platform.',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
    ),
  ];

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('dd MMM yyyy').format(dt);
  }

  void _markAllRead() {
    setState(() {
      for (var n in _notifications) {
        n.isRead = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All notifications marked as read.')),
    );
  }

  void _clearAll() {
    setState(() {
      _notifications.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          if (unreadCount > 0)
            TextButton.icon(
              onPressed: _markAllRead,
              icon: const Icon(Icons.done_all, size: 16, color: AppColors.primary),
              label: const Text('Read all', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          if (_notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, color: Colors.red),
              onPressed: _clearAll,
              tooltip: 'Clear all',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 12),
                      Text(
                        'No notifications yet',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'System updates and announcements will appear here.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final item = _notifications[index];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          item.isRead = true;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: item.isRead ? Colors.white : const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: item.isRead ? AppColors.border : const Color(0xFFBFDBFE),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            )
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: item.isRead ? Colors.grey.shade100 : AppColors.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.campaign,
                                color: item.isRead ? Colors.grey.shade600 : Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.title,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: item.isRead ? AppColors.textPrimary : const Color(0xFF1E3A8A),
                                          ),
                                        ),
                                      ),
                                      Text(
                                        _formatTime(item.createdAt),
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    item.message,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: item.isRead ? AppColors.textSecondary : const Color(0xFF1E293B),
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
