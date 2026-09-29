import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../models/chat_message.dart';
import '../services/firebase_service.dart';
import '../providers/auth_provider.dart';

class ChatRoomScreen extends StatefulWidget {
  final String conversationId;
  final String partTitle;
  final String sellerName;

  const ChatRoomScreen({
    Key? key,
    required this.conversationId,
    required this.partTitle,
    required this.sellerName,
  }) : super(key: key);

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();

  void _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    final auth = Provider.of<AppAuthProvider>(context, listen: false);
    final senderId = auth.user?.uid ?? 'guest';
    final senderName = auth.userProfile?.displayName ?? auth.user?.displayName ?? 'Buyer';

    _msgCtrl.clear();
    await _firebaseService.sendMessage(
      conversationId: widget.conversationId,
      senderId: senderId,
      senderName: senderName,
      text: text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AppAuthProvider>(context);
    final myUid = auth.user?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.sellerName,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.partTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _firebaseService.getMessagesStream(widget.conversationId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return const Center(
                    child: Text('Say Hello and ask about the spare part! 🚗', style: TextStyle(color: Colors.grey)),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderId == myUid;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: isMe ? AppColors.primary : Colors.white,
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
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Text(
                              msg.text,
                              style: TextStyle(
                                color: isMe ? Colors.white : AppColors.textPrimary,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('hh:mm a').format(msg.createdAt),
                              style: TextStyle(
                                color: isMe ? Colors.white70 : Colors.grey,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Message Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.white,
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: AppColors.background,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 18),
                      onPressed: _sendMessage,
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
