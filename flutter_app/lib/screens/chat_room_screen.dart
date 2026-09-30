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

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
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
        'lastSenderId': senderId,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _db.collection('chats').doc(widget.conversationId).set(updateData, SetOptions(merge: true));
      _scrollToBottom();
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: const [
                  Icon(Icons.add_photo_alternate_rounded, color: Color(0xFF0075FF), size: 24),
                  SizedBox(width: 8),
                  Text('Send Photo of Part', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
                ],
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFF0075FF).withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF0075FF)),
                ),
                title: const Text('Take Photo with Camera', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Capture direct condition of the spare part', style: TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndSendImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.photo_library_rounded, color: Color(0xFF10B981)),
                ),
                title: const Text('Choose from Photo Gallery', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Send existing photos from device gallery', style: TextStyle(fontSize: 12)),
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

      _sendMessage(customText: status == 'accepted' ? '🤝 Deal Accepted! Please call to arrange delivery.' : '❌ Offer Declined. Let’s negotiate a better price.');
    } catch (e) {
      debugPrint('Error updating offer: $e');
    }
  }

  void _openFullPartDetails() async {
    if (widget.partId != null && widget.partId!.isNotEmpty) {
      try {
        final doc = await _db.collection('spareParts').doc(widget.partId).get();
        if (doc.exists && mounted) {
          final part = SparePart.fromFirestore(doc);
          Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(part: part)));
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final currentUid = currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leadingWidth: 40,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF0075FF).withOpacity(0.12),
              child: Text(
                widget.sellerName.isNotEmpty ? widget.sellerName[0].toUpperCase() : 'U',
                style: const TextStyle(color: Color(0xFF0075FF), fontWeight: FontWeight.w900, fontSize: 14),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.sellerName,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0F172A)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.verified_rounded, size: 14, color: Color(0xFF0075FF)),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Active Now',
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: Column(
        children: [
          // 1. Pinned Part Context Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: const Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
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
                      errorWidget: (_, __, ___) => Container(width: 44, height: 44, color: const Color(0xFFF1F5F9)),
                    ),
                  )
                else
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0075FF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.directions_car_rounded, color: Color(0xFF0075FF)),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.partTitle,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.partPrice != null)
                        Text(
                          'Asking: ₹${widget.partPrice}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF0075FF)),
                        ),
                    ],
                  ),
                ),
                if (widget.partId != null && widget.partId!.isNotEmpty)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.open_in_new_rounded, size: 14, color: Color(0xFF0075FF)),
                    label: const Text('View Part', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0075FF))),
                    onPressed: _openFullPartDetails,
                  ),
              ],
            ),
          ),

          // 2. Quick Negotiation Suggestions Rail
          Container(
            height: 36,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _quickReplies.length,
              itemBuilder: (context, i) {
                final reply = _quickReplies[i];
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ActionChip(
                    label: Text(reply),
                    labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                    backgroundColor: const Color(0xFFF1F5F9),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    onPressed: () => _sendMessage(customText: reply),
                  ),
                );
              },
            ),
          ),

          // 3. Real-Time Messages List
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

                final messages = snapshot.data?.docs ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.waving_hand_rounded, size: 40, color: Color(0xFFF59E0B)),
                          SizedBox(height: 12),
                          Text('Say Hello & Make an Offer!', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF0F172A))),
                          SizedBox(height: 4),
                          Text('Start the conversation or tap one of the chips above.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final doc = messages[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final isMe = data['senderId'] == currentUid;
                    final text = (data['text'] ?? '').toString();
                    final imageUrl = data['imageUrl'] as String?;
                    final offerPrice = data['offerPrice'] as num?;
                    final offerStatus = data['offerStatus'] as String?;
                    final ts = data['createdAt'] as Timestamp?;
                    final timeStr = ts != null ? DateFormat('h:mm a').format(ts.toDate()) : '';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          // 1. Offer Card Bubble (If offerPrice != null)
                          if (offerPrice != null)
                            Container(
                              width: 260,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                gradient: isMe
                                    ? const LinearGradient(colors: [Color(0xFF0075FF), Color(0xFF0052B4)])
                                    : const LinearGradient(colors: [Colors.white, Color(0xFFF8FAFC)]),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: isMe ? Colors.transparent : const Color(0xFFCBD5E1)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.local_offer_rounded, size: 16, color: isMe ? Colors.white : const Color(0xFF0075FF)),
                                          const SizedBox(width: 4),
                                          Text(
                                            'PRICE OFFER',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 0.8,
                                              color: isMe ? Colors.white.withOpacity(0.85) : const Color(0xFF0075FF),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: (offerStatus == 'accepted')
                                              ? const Color(0xFF10B981)
                                              : (offerStatus == 'declined' ? const Color(0xFFEF4444) : const Color(0xFFF59E0B)),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          (offerStatus ?? 'pending').toUpperCase(),
                                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '₹${offerPrice.toInt()}',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      color: isMe ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isMe ? 'You proposed this price' : '${data['senderName']} sent this price offer',
                                    style: TextStyle(fontSize: 11, color: isMe ? Colors.white70 : const Color(0xFF64748B)),
                                  ),
                                  // Seller Decision Buttons (If received by other user & pending)
                                  if (!isMe && offerStatus == 'pending') ...[
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF10B981),
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(vertical: 6),
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                            onPressed: () => _respondToOffer(doc.id, 'accepted'),
                                            child: const Text('Accept', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: OutlinedButton(
                                            style: OutlinedButton.styleFrom(
                                              side: const BorderSide(color: Color(0xFFEF4444)),
                                              foregroundColor: const Color(0xFFEF4444),
                                              padding: const EdgeInsets.symmetric(vertical: 6),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                            onPressed: () => _respondToOffer(doc.id, 'declined'),
                                            child: const Text('Decline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            )

                          // 2. Photo Attachment Bubble
                          else if (imageUrl != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: CachedNetworkImage(
                                imageUrl: imageUrl,
                                width: 220,
                                height: 220,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(
                                  width: 220,
                                  height: 220,
                                  color: Colors.grey.shade200,
                                  child: const Center(child: CircularProgressIndicator(color: Color(0xFF0075FF))),
                                ),
                              ),
                            )

                          // 3. Regular Text Message Bubble
                          else
                            Container(
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isMe ? const Color(0xFF0075FF) : Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                                  bottomRight: Radius.circular(isMe ? 4 : 16),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Text(
                                text,
                                style: TextStyle(
                                  color: isMe ? Colors.white : const Color(0xFF0F172A),
                                  fontSize: 14,
                                  height: 1.35,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),

                          // Message Timestamp & Status
                          const SizedBox(height: 2),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                timeStr,
                                style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                              ),
                              if (isMe) ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.done_all_rounded, size: 12, color: Color(0xFF0075FF)),
                              ],
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Uploading Image Indicator
          if (_isUploadingImage)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
              color: const Color(0xFFEFF6FF),
              child: Row(
                children: const [
                  SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0075FF))),
                  SizedBox(width: 8),
                  Text('Uploading part photo...', style: TextStyle(fontSize: 12, color: Color(0xFF0075FF), fontWeight: FontWeight.bold)),
                ],
              ),
            ),

          // 4. Message Input Dock
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Attachment Button
                  IconButton(
                    icon: const Icon(Icons.add_a_photo_outlined, color: Color(0xFF0075FF), size: 22),
                    onPressed: _showAttachmentSheet,
                  ),
                  // Make Offer Quick Trigger
                  IconButton(
                    icon: const Icon(Icons.local_offer_outlined, color: Color(0xFF0075FF), size: 22),
                    onPressed: () {
                      _showQuickOfferDialog(currentUid, currentUser?.displayName ?? 'Buyer');
                    },
                  ),
                  // Text Input Field
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TextField(
                        controller: _msgCtrl,
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: 4,
                        minLines: 1,
                        decoration: const InputDecoration(
                          hintText: 'Type your message...',
                          hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Send Button
                  GestureDetector(
                    onTap: () => _sendMessage(),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF0075FF), Color(0xFF0052B4)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
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

  void _showQuickOfferDialog(String currentUid, String currentName) {
    final offerCtrl = TextEditingController(
      text: widget.partPrice != null ? (widget.partPrice * 0.9).toInt().toString() : '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.local_offer_rounded, color: Color(0xFF0075FF), size: 24),
            SizedBox(width: 8),
            Text('Make a Price Offer', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Part: ${widget.partTitle}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
            if (widget.partPrice != null)
              Text('Original Asking Price: ₹${widget.partPrice}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            const SizedBox(height: 16),
            TextField(
              controller: offerCtrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                prefixText: '₹ ',
                prefixStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF0F172A)),
                labelText: 'Your Offer Price (₹)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0075FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: () {
              final val = double.tryParse(offerCtrl.text.trim());
              if (val != null && val > 0) {
                Navigator.pop(ctx);
                _sendMessage(offerPrice: val);
              }
            },
            child: const Text('Send Offer', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
