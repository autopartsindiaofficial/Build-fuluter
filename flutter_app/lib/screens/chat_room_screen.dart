import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/app_colors.dart';
import '../services/cloudinary_service.dart';
import '../providers/auth_provider.dart';
import '../widgets/make_offer_dialog.dart';
import '../models/spare_part.dart';
import 'product_detail_screen.dart';

class ChatRoomScreen extends StatefulWidget {
  final String conversationId;
  final String partTitle;
  final String sellerName;
  final dynamic partPrice;
  final String? partImageUrl;
  final String? partId;

  const ChatRoomScreen({
    Key? key,
    required this.conversationId,
    required this.partTitle,
    required this.sellerName,
    this.partPrice,
    this.partImageUrl,
    this.partId,
  }) : super(key: key);

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  final CloudinaryService _cloudinary = CloudinaryService();
  bool _isUploadingImage = false;

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

  final List<String> _quickReplies = [
    'Is this part available?',
    'What is your final best price?',
    'Can you ship to my city?',
    'Please send more clear photos',
    'Is there any warranty on this?',
  ];

  @override
  void initState() {
    super.initState();
    _markChatAsRead();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _markChatAsRead() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || widget.conversationId.isEmpty) return;

    try {
      _db.collection('chats').doc(widget.conversationId).update({
        'unreadCount.$uid': 0,
      }).catchError((_) {});
    } catch (_) {}
  }

  Future<void> _sendMessage({String? customText, String? imageUrl, double? offerPrice}) async {
    final text = customText ?? _msgCtrl.text.trim();
    if (text.isEmpty && imageUrl == null && offerPrice == null) return;

    final user = FirebaseAuth.instance.currentUser;
    final senderId = user?.uid ?? 'guest';
    final senderName = user?.displayName ?? 'Buyer';

    if (customText == null) {
      _msgCtrl.clear();
    }

    try {
      final msgRef = _db
          .collection('chats')
          .doc(widget.conversationId)
          .collection('messages')
          .doc();

      final msgData = {
        'id': msgRef.id,
        'senderId': senderId,
        'senderName': senderName,
        'text': text,
        'imageUrl': imageUrl,
        'offerPrice': offerPrice,
        'offerStatus': offerPrice != null ? 'pending' : null,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await msgRef.set(msgData);

      // Update parent chat document
      final updateData = {
        'lastMessageText': offerPrice != null ? '🏷️ Sent an offer: ₹${offerPrice.toInt()}' : (imageUrl != null ? '📷 Sent a photo' : text),
        'lastMessageTime': DateTime.now().millisecondsSinceEpoch,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _db.collection('chats').doc(widget.conversationId).set(updateData, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error sending message: $e');
    }
  }

  Future<void> _pickAndSendImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 75);
      if (picked == null) return;

      setState(() => _isUploadingImage = true);

      final url = await _cloudinary.uploadImage(picked.path);
      if (url != null && url.isNotEmpty) {
        await _sendMessage(imageUrl: url);
      }
    } catch (e) {
      debugPrint('Image attachment error: $e');
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  void _showAttachmentSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Send Photo of Part', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF0075FF)),
                title: const Text('Take Photo with Camera'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndSendImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF0075FF)),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndSendImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _respondToOffer(String messageId, String status) async {
    try {
      await _db
          .collection('chats')
          .doc(widget.conversationId)
          .collection('messages')
          .doc(messageId)
          .update({'offerStatus': status});

      _sendMessage(customText: status == 'accepted' ? '🤝 Offer Accepted!' : '❌ Offer Declined.');
    } catch (e) {
      debugPrint('Error updating offer: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF0075FF).withOpacity(0.12),
              child: Text(
                widget.sellerName.isNotEmpty ? widget.sellerName[0].toUpperCase() : 'U',
                style: const TextStyle(color: Color(0xFF0075FF), fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.sellerName,
                    style: const TextStyle(color: Color(0xFF0F172A), fontSize: 15, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text(
                    'Online • Active Trader',
                    style: TextStyle(color: Color(0xFF16A34A), fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // 1. Top Part Sticky Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                if (widget.partImageUrl != null && widget.partImageUrl!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: widget.partImageUrl!,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(width: 44, height: 44, color: Colors.grey.shade200),
                    ),
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.partTitle,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.partPrice != null)
                        Text(
                          currencyFormatter.format(widget.partPrice is num ? widget.partPrice : double.tryParse(widget.partPrice.toString()) ?? 0),
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0075FF)),
                        ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    if (widget.partId != null && widget.partId!.isNotEmpty) {
                      _db.collection('spareParts').doc(widget.partId).get().then((doc) {
                        if (doc.exists && mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ProductDetailScreen(part: SparePart.fromFirestore(doc))),
                          );
                        }
                      });
                    }
                  },
                  child: const Text('View Ad', style: TextStyle(color: Color(0xFF0075FF), fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
          ),

          // 2. Chat Messages Stream
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _db
                  .collection('chats')
                  .doc(widget.conversationId)
                  .collection('messages')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF0075FF)));
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.handshake_outlined, size: 48, color: Colors.grey),
                          const SizedBox(height: 12),
                          const Text(
                            'Start Negotiation',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Inquire about condition, discount price, or delivery options below.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  controller: _scrollController,
                  padding: const EdgeInsets.all(14),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final isMe = data['senderId'] == currentUid;
                    final text = (data['text'] ?? '').toString();
                    final imageUrl = data['imageUrl'] as String?;
                    final offerPrice = data['offerPrice'];
                    final offerStatus = data['offerStatus'];

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.78,
                        ),
                        decoration: BoxDecoration(
                          color: isMe ? const Color(0xFF0075FF) : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
                            bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Column(
                            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              // Photo Message
                              if (imageUrl != null && imageUrl.isNotEmpty)
                                CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Container(height: 160, color: Colors.grey.shade100, child: const Center(child: CircularProgressIndicator())),
                                  errorWidget: (_, __, ___) => Container(height: 160, color: Colors.grey.shade200, child: const Icon(Icons.broken_image, size: 40)),
                                ),

                              // Offer Card Message
                              if (offerPrice != null)
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  color: isMe ? Colors.white.withOpacity(0.15) : const Color(0xFFEFF6FF),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.local_offer, size: 16, color: Color(0xFF0075FF)),
                                          const SizedBox(width: 6),
                                          Text(
                                            'OFFER PROPOSED: ₹${offerPrice is num ? offerPrice.toInt() : offerPrice}',
                                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF0075FF)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      if (offerStatus == 'accepted')
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(4)),
                                          child: const Text('✅ OFFER ACCEPTED', style: TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold, fontSize: 11)),
                                        )
                                      else if (offerStatus == 'rejected')
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(4)),
                                          child: const Text('❌ OFFER DECLINED', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11)),
                                        )
                                      else if (!isMe)
                                        Row(
                                          children: [
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF16A34A),
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                minimumSize: Size.zero,
                                              ),
                                              onPressed: () => _respondToOffer(docs[index].id, 'accepted'),
                                              child: const Text('Accept', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                            ),
                                            const SizedBox(width: 8),
                                            OutlinedButton(
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: Colors.red,
                                                side: const BorderSide(color: Colors.red),
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                minimumSize: Size.zero,
                                              ),
                                              onPressed: () => _respondToOffer(docs[index].id, 'rejected'),
                                              child: const Text('Decline', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),

                              // Text Message
                              if (text.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  child: Text(
                                    text,
                                    style: TextStyle(
                                      color: isMe ? Colors.white : const Color(0xFF0F172A),
                                      fontSize: 14,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          if (_isUploadingImage)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.white,
              child: Row(
                children: const [
                  SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 8),
                  Text('Uploading part photo...', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),

          // 3. Quick Replies Carousel
          Container(
            height: 38,
            color: Colors.white,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _quickReplies.length,
              itemBuilder: (context, index) {
                final reply = _quickReplies[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8, top: 4, bottom: 4),
                  child: ActionChip(
                    backgroundColor: const Color(0xFFEFF6FF),
                    side: const BorderSide(color: Color(0xFFDBEAFE)),
                    label: Text(reply, style: const TextStyle(fontSize: 11, color: Color(0xFF0075FF), fontWeight: FontWeight.w600)),
                    onPressed: () => _sendMessage(customText: reply),
                  ),
                );
              },
            ),
          ),

          // 4. Message Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_photo_alternate_outlined, color: Color(0xFF0075FF), size: 24),
                    onPressed: _showAttachmentSheet,
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: TextField(
                        controller: _msgCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    decoration: const BoxDecoration(color: Color(0xFF0075FF), shape: BoxShape.circle),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 18),
                      onPressed: () => _sendMessage(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
