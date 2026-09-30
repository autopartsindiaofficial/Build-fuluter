import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/auth_provider.dart';
import 'auth_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  FirebaseFirestore get _db {
    try {
      return FirebaseFirestore.instanceFor(
        app: FirebaseFirestore.instance.app,
        databaseId: 'ai-studio-autopartsmarketp-6b6de595-2abc-431d-a6dc-0141a5eff96f',
      );
    } catch (_) {
      return FirebaseFirestore.instance;
    }
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('dd MMM yyyy').format(dt);
  }

  Future<void> _markAllAsRead(String userId, List<QueryDocumentSnapshot> docs) async {
    final batch = _db.batch();
    for (var doc in docs) {
      if ((doc.data() as Map<String, dynamic>)['read'] != true &&
          (doc.data() as Map<String, dynamic>)['isRead'] != true) {
        batch.update(doc.reference, {'isRead': true, 'read': true});
      }
    }
    await batch.commit();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All notifications marked as read.'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _clearAllNotifications(String userId, List<QueryDocumentSnapshot> docs) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Clear Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to clear all notifications?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final batch = _db.batch();
      for (var doc in docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AppAuthProvider>(context);
    final userId = auth.user?.uid;

    if (userId == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF0F172A))),
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: const Color(0xFFF1F5F9), height: 1),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0075FF).withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.notifications_off_outlined, size: 54, color: Color(0xFF0075FF)),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Sign In to View Notifications',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Live price offers, negotiation alerts, and seller updates will appear here in real-time.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.45),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0075FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.login_rounded, size: 18),
                  label: const Text('Sign In Now', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _db
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final hasUnread = docs.any((d) => (d.data() as Map<String, dynamic>)['read'] != true && (d.data() as Map<String, dynamic>)['isRead'] != true);

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: Row(
              children: [
                const Text(
                  'Notifications',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF0F172A)),
                ),
                if (hasUnread) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                  ),
                ],
              ],
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            actions: [
              if (docs.isNotEmpty) ...[
                TextButton(
                  onPressed: () => _markAllAsRead(userId, docs),
                  child: const Text('Mark all read', style: TextStyle(color: Color(0xFF0075FF), fontWeight: FontWeight.w800, fontSize: 12)),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_sweep_rounded, color: Color(0xFF64748B), size: 20),
                  onPressed: () => _clearAllNotifications(userId, docs),
                ),
              ],
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(color: const Color(0xFFF1F5F9), height: 1),
            ),
          ),
          body: snapshot.connectionState == ConnectionState.waiting
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF0075FF)))
              : docs.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(22),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.notifications_none_rounded, size: 52, color: Color(0xFF94A3B8)),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No Notifications Yet',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'You will receive instant alerts for incoming price offers, chat messages, and marketplace updates.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.45),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        String title = data['title'] ?? 'Notification';
                        if (title.toLowerCase().contains('system notification') || title.trim().toLowerCase() == 'system') {
                          title = 'Marketplace Announcement';
                        }
                        final message = data['message'] ?? data['body'] ?? '';
                        final isRead = data['isRead'] == true || data['read'] == true;
                        final ts = data['createdAt'] as Timestamp?;
                        final createdAt = ts?.toDate() ?? DateTime.now();
                        final type = (data['type'] ?? '').toString().toLowerCase();

                        // Determine icon & color based on type
                        IconData iconData = Icons.campaign_rounded;
                        Color iconColor = const Color(0xFF0075FF);

                        if (type.contains('offer') || title.toLowerCase().contains('offer')) {
                          iconData = Icons.local_offer_rounded;
                          iconColor = const Color(0xFFF59E0B);
                        } else if (type.contains('chat') || title.toLowerCase().contains('chat') || title.toLowerCase().contains('message')) {
                          iconData = Icons.chat_bubble_rounded;
                          iconColor = const Color(0xFF0075FF);
                        } else if (type.contains('sold') || title.toLowerCase().contains('sold') || title.toLowerCase().contains('approved')) {
                          iconData = Icons.check_circle_rounded;
                          iconColor = const Color(0xFF10B981);
                        }

                        return Dismissible(
                          key: Key(doc.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
                          ),
                          onDismissed: (_) {
                            doc.reference.delete();
                          },
                          child: GestureDetector(
                            onTap: () async {
                              if (!isRead) {
                                await doc.reference.update({'isRead': true, 'read': true});
                              }
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isRead ? Colors.white : const Color(0xFFF0F7FF),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isRead ? const Color(0xFFE2E8F0) : const Color(0xFFBFDBFE),
                                  width: isRead ? 1 : 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.02),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: iconColor.withOpacity(0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(iconData, color: iconColor, size: 20),
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
                                                title,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: isRead ? FontWeight.bold : FontWeight.w900,
                                                  color: const Color(0xFF0F172A),
                                                ),
                                              ),
                                            ),
                                            Text(
                                              _formatTime(createdAt),
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: isRead ? const Color(0xFF94A3B8) : const Color(0xFF0075FF),
                                                fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          message,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: isRead ? const Color(0xFF64748B) : const Color(0xFF334155),
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        );
      },
    );
  }
}
