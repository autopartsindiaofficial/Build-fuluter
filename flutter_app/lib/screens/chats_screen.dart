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

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AppAuthProvider>(context);
    final lang = Provider.of<LanguageProvider>(context);
    final user = auth.user;

    if (user == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: Text(lang.t('chats'), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          backgroundColor: Colors.white,
          elevation: 0.5,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: const Color(0xFF0075FF).withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.chat_bubble_outline, size: 54, color: Color(0xFF0075FF)),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Sign In to View Messages',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Connect with verified auto parts buyers and sellers across India.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0075FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.login),
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

    final currentUid = user.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(lang.t('chats'), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          // Filter Tabs (All / Buying / Selling)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('all', 'All Chats'),
                const SizedBox(width: 8),
                _buildFilterChip('buy', 'Buying'),
                const SizedBox(width: 8),
                _buildFilterChip('sell', 'Selling'),
              ],
            ),
          ),

          // Search Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search chats by user or part name...',
                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF64748B)),
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                          child: const Icon(Icons.forum_outlined, size: 48, color: Colors.grey),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No conversations found',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Find spare parts and chat with sellers to make offers!',
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: userChats.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  itemBuilder: (context, index) {
                    final doc = userChats[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final isBuyer = data['buyerId'] == currentUid;
                    final otherName = isBuyer ? (data['sellerName'] ?? 'Seller') : (data['buyerName'] ?? 'Buyer');
                    final otherPhoto = isBuyer ? data['sellerPhoto'] : data['buyerPhoto'];
                    final partTitle = data['partTitle'] ?? 'Auto Spare Part';
                    final partImageUrl = data['partImageUrl'] ?? data['partImage'] ?? '';
                    final lastMsg = data['lastMessageText'] ?? data['lastMessage'] ?? 'Started a conversation';
                    final unreadCount = (data['unreadCount'] is Map ? (data['unreadCount'][currentUid] ?? 0) : 0);

                    return ListTile(
                      tileColor: unreadCount > 0 ? const Color(0xFFF0F7FF) : Colors.white,
                      leading: Stack(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: const Color(0xFF0075FF).withOpacity(0.12),
                            backgroundImage: (otherPhoto != null && otherPhoto.isNotEmpty)
                                ? CachedNetworkImageProvider(otherPhoto)
                                : null,
                            child: (otherPhoto == null || otherPhoto.isEmpty)
                                ? Text(
                                    otherName.isNotEmpty ? otherName[0].toUpperCase() : 'U',
                                    style: const TextStyle(color: Color(0xFF0075FF), fontWeight: FontWeight.bold, fontSize: 18),
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: const Color(0xFF16A34A),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              otherName,
                              style: TextStyle(
                                fontWeight: unreadCount > 0 ? FontWeight.w900 : FontWeight.bold,
                                fontSize: 15,
                                color: const Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isBuyer ? const Color(0xFFDCFCE7) : const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isBuyer ? 'Seller' : 'Buyer',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isBuyer ? const Color(0xFF16A34A) : const Color(0xFF0075FF),
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(Icons.directions_car, size: 13, color: Color(0xFF0075FF)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  partTitle,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0075FF)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            lastMsg,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                              color: unreadCount > 0 ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (partImageUrl.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: CachedNetworkImage(
                                imageUrl: partImageUrl,
                                width: 36,
                                height: 36,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => const Icon(Icons.car_repair, size: 24, color: Colors.grey),
                              ),
                            ),
                          if (unreadCount > 0)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.all(5),
                              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                              child: Text(
                                '$unreadCount',
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatRoomScreen(
                              conversationId: doc.id,
                              partTitle: partTitle,
                              sellerName: otherName,
                              partPrice: data['partPrice'] ?? 0,
                              partImageUrl: partImageUrl,
                              partId: data['partId'] ?? '',
                            ),
                          ),
                        );
                      },
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0075FF) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}
