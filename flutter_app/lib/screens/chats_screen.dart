import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../models/chat_message.dart';
import '../services/firebase_service.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import 'chat_room_screen.dart';

class ChatsScreen extends StatelessWidget {
  const ChatsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AppAuthProvider>(context);
    final lang = Provider.of<LanguageProvider>(context);
    final firebaseService = FirebaseService();

    if (!auth.isAuthenticated) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(lang.t('chats'), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.chat_outlined, size: 60, color: Colors.grey),
              const SizedBox(height: 12),
              Text(lang.t('loginRequired'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(lang.t('chats'), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<List<ChatConversation>>(
        stream: firebaseService.getConversationsStream(auth.user!.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final convos = snapshot.data ?? [];

          if (convos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.forum_outlined, size: 60, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('No chats yet. Inquire about a part to start chatting!', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: convos.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final c = convos[index];
              final isBuyer = c.buyerId == auth.user!.uid;
              final otherName = isBuyer ? c.sellerName : c.buyerName;
              final timeStr = DateFormat('hh:mm a').format(c.lastMessageAt);

              return ListTile(
                tileColor: Colors.white,
                leading: CircleAvatar(
                  backgroundColor: AppColors.primaryLight,
                  child: Text(
                    otherName.isNotEmpty ? otherName[0].toUpperCase() : 'U',
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        otherName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    Text(timeStr, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Re: ${c.partTitle}',
                      style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      c.lastMessageText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatRoomScreen(
                        conversationId: c.id,
                        partTitle: c.partTitle,
                        sellerName: otherName,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
