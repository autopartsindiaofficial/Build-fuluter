import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import 'chat_room_screen.dart';
import 'auth_screen.dart';
import 'search_screen.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({Key? key}) : super(key: key);

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  String _activeFilter = 'all'; // 'all', 'buy', 'sell'
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

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

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _formatChatTime(dynamic rawTime) {
    if (rawTime == null) return '';
    DateTime dt;
    if (rawTime is Timestamp) {
      dt = rawTime.toDate();
    } else if (rawTime is int) {
      dt = DateTime.fromMillisecondsSinceEpoch(rawTime);
    } else {
      return '';
    }

    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return DateFormat('EEE').format(dt);
    return DateFormat('d MMM').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AppAuthProvider>(context);
    final lang = Provider.of<LanguageProvider>(context);
    final user = auth.user;

    if (user == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: Text(lang.t('chats'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF0F172A))),
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
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0075FF).withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.chat_bubble_outline_rounded, size: 58, color: Color(0xFF0075FF)),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Sign In to Chat with Sellers',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 19, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Connect in real-time with genuine automobile parts sellers and send instant price offers.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 13, height: 1.45),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0075FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.login_rounded, size: 20),
                  label: const Text('Sign In Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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

    final currentUid = user.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              lang.t('chats'),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 19, color: Color(0xFF0F172A)),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF0075FF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bolt_rounded, size: 12, color: Color(0xFF0075FF)),
                  SizedBox(width: 2),
                  Text('LIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF0075FF))),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFF1F5F9), height: 1),
        ),
      ),
      body: Column(
        children: [
          // Filter Tabs & Search Bar Container
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                // Filter Tabs (All / Buying / Selling)
                Row(
                  children: [
                    _buildFilterChip('all', 'All Chats'),
                    const SizedBox(width: 8),
                    _buildFilterChip('buy', 'Buying'),
                    const SizedBox(width: 8),
                    _buildFilterChip('sell', 'Selling'),
                  ],
                ),
                const SizedBox(height: 10),

                // Search Box
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                    decoration: InputDecoration(
                      hintText: 'Search chats by user or part name...',
                      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                      prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF64748B)),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.cancel_rounded, size: 16, color: Color(0xFF94A3B8)),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Real-time Chat List Stream
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _db.collection('chats').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF0075FF)));
                }

                var allDocs = snapshot.data?.docs ?? [];

                // Filter to only conversations where user is a participant
                var userChats = allDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final buyerId = (data['buyerId'] ?? '').toString();
                  final sellerId = (data['sellerId'] ?? '').toString();
                  final participants = (data['participants'] as List?)?.map((e) => e.toString()).toList() ?? [];

                  return buyerId == currentUid || sellerId == currentUid || participants.contains(currentUid);
                }).toList();

                // Sort by lastMessageTime descending
                userChats.sort((a, b) {
                  final aTime = (a.data() as Map<String, dynamic>)['lastMessageTime'] ?? (a.data() as Map<String, dynamic>)['updatedAt'] ?? 0;
                  final bTime = (b.data() as Map<String, dynamic>)['lastMessageTime'] ?? (b.data() as Map<String, dynamic>)['updatedAt'] ?? 0;
                  return (bTime is num ? bTime : 0).compareTo(aTime is num ? aTime : 0);
                });

                // Apply Buyer / Seller Filter
                if (_activeFilter == 'buy') {
                  userChats = userChats.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return data['buyerId'] == currentUid;
                  }).toList();
                } else if (_activeFilter == 'sell') {
                  userChats = userChats.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return data['sellerId'] == currentUid;
                  }).toList();
                }

                // Apply Search Filter
                if (_searchQuery.isNotEmpty) {
                  userChats = userChats.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final title = (data['partTitle'] ?? '').toString().toLowerCase();
                    final seller = (data['sellerName'] ?? '').toString().toLowerCase();
                    final buyer = (data['buyerName'] ?? '').toString().toLowerCase();
                    final msg = (data['lastMessageText'] ?? data['lastMessage'] ?? '').toString().toLowerCase();
                    return title.contains(_searchQuery) || seller.contains(_searchQuery) || buyer.contains(_searchQuery) || msg.contains(_searchQuery);
                  }).toList();
                }

                if (userChats.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.chat_bubble_outline_rounded, size: 50, color: Color(0xFF94A3B8)),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No Conversations Found',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Browse auto spare parts and chat with sellers to make price offers!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Color(0xFF64748B), fontSize: 13, height: 1.4),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0075FF),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.search_rounded, size: 18),
                            label: const Text('Browse Spare Parts', style: TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen()));
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: userChats.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9), indent: 76),
                  itemBuilder: (context, index) {
                    final doc = userChats[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final isBuyer = data['buyerId'] == currentUid;
                    final otherName = isBuyer ? (data['sellerName'] ?? 'Seller') : (data['buyerName'] ?? 'Buyer');
                    final otherPhoto = isBuyer ? data['sellerPhoto'] : data['buyerPhoto'];
                    final partTitle = data['partTitle'] ?? 'Auto Spare Part';
                    final partImageUrl = data['partImageUrl'] ?? data['partImage'] ?? '';
                    final lastMsg = data['lastMessageText'] ?? data['lastMessage'] ?? 'Started a conversation';
                    final rawTime = data['lastMessageTime'] ?? data['updatedAt'];
                    final timeFormatted = _formatChatTime(rawTime);

                    int unreadCount = 0;
                    if (data['unreadCount'] is Map && data['unreadCount'][currentUid] != null) {
                      unreadCount = (data['unreadCount'][currentUid] as num).toInt();
                    } else if (data['lastSenderId'] != currentUid && data['isRead'] == false) {
                      unreadCount = 1;
                    }

                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatRoomScreen(
                              conversationId: doc.id,
                              partTitle: partTitle,
                              sellerName: otherName,
                              partImageUrl: partImageUrl,
                              partPrice: data['partPrice'],
                              partId: data['partId'],
                            ),
                          ),
                        );
                      },
                      child: Container(
                        color: unreadCount > 0 ? const Color(0xFFF0F7FF) : Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // User Avatar with Online Indicator
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 26,
                                  backgroundColor: const Color(0xFF0075FF).withOpacity(0.12),
                                  backgroundImage: (otherPhoto != null && otherPhoto.isNotEmpty)
                                      ? CachedNetworkImageProvider(otherPhoto)
                                      : null,
                                  child: (otherPhoto == null || otherPhoto.isEmpty)
                                      ? Text(
                                          otherName.isNotEmpty ? otherName[0].toUpperCase() : 'U',
                                          style: const TextStyle(color: Color(0xFF0075FF), fontWeight: FontWeight.w900, fontSize: 18),
                                        )
                                      : null,
                                ),
                                Positioned(
                                  bottom: 1,
                                  right: 1,
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),

                            // Main Conversation Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Flexible(
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Flexible(
                                              child: Text(
                                                otherName,
                                                style: TextStyle(
                                                  fontWeight: unreadCount > 0 ? FontWeight.w900 : FontWeight.w800,
                                                  fontSize: 15,
                                                  color: const Color(0xFF0F172A),
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: isBuyer ? const Color(0xFFDCFCE7) : const Color(0xFFEFF6FF),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                isBuyer ? 'SELLER' : 'BUYER',
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w900,
                                                  color: isBuyer ? const Color(0xFF16A34A) : const Color(0xFF0075FF),
                                                  letterSpacing: 0.3,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        timeFormatted,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: unreadCount > 0 ? const Color(0xFF0075FF) : const Color(0xFF94A3B8),
                                          fontWeight: unreadCount > 0 ? FontWeight.w800 : FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  // Part Title Preview
                                  Row(
                                    children: [
                                      const Icon(Icons.directions_car_rounded, size: 12, color: Color(0xFF64748B)),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          partTitle,
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  // Last Message Text & Unread Badge
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          lastMsg,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: unreadCount > 0 ? FontWeight.w800 : FontWeight.w500,
                                            color: unreadCount > 0 ? const Color(0xFF0F172A) : const Color(0xFF475569),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (unreadCount > 0)
                                        Container(
                                          margin: const EdgeInsets.only(left: 8),
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                                            ),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '$unreadCount',
                                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Part Image Thumbnail on Trailing Edge
                            if (partImageUrl.isNotEmpty) ...[
                              const SizedBox(width: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl: partImageUrl,
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => Container(
                                    width: 44,
                                    height: 44,
                                    color: const Color(0xFFF1F5F9),
                                    child: const Icon(Icons.image_not_supported_rounded, size: 20, color: Colors.grey),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _activeFilter == key;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0075FF) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}
