import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.createdAt,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    DateTime created;
    if (data['createdAt'] is Timestamp) {
      created = (data['createdAt'] as Timestamp).toDate();
    } else if (data['createdAt'] is int) {
      created = DateTime.fromMillisecondsSinceEpoch(data['createdAt']);
    } else {
      created = DateTime.now();
    }

    return ChatMessage(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? 'User',
      text: data['text'] ?? '',
      createdAt: created,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

class ChatConversation {
  final String id;
  final String partId;
  final String partTitle;
  final String partImageUrl;
  final double partPrice;
  final String lastMessageText;
  final DateTime lastMessageAt;
  final String lastSenderId;
  final List<String> participants;
  final String buyerId;
  final String buyerName;
  final String sellerId;
  final String sellerName;

  ChatConversation({
    required this.id,
    required this.partId,
    required this.partTitle,
    required this.partImageUrl,
    required this.partPrice,
    required this.lastMessageText,
    required this.lastMessageAt,
    required this.lastSenderId,
    required this.participants,
    required this.buyerId,
    required this.buyerName,
    required this.sellerId,
    required this.sellerName,
  });

  factory ChatConversation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    DateTime lastMsg;
    if (data['lastMessageAt'] is Timestamp) {
      lastMsg = (data['lastMessageAt'] as Timestamp).toDate();
    } else if (data['lastMessageAt'] is int) {
      lastMsg = DateTime.fromMillisecondsSinceEpoch(data['lastMessageAt']);
    } else {
      lastMsg = DateTime.now();
    }

    return ChatConversation(
      id: doc.id,
      partId: data['partId'] ?? '',
      partTitle: data['partTitle'] ?? 'Spare Part',
      partImageUrl: data['partImageUrl'] ?? '',
      partPrice: (data['partPrice'] is num) ? (data['partPrice'] as num).toDouble() : 0.0,
      lastMessageText: data['lastMessageText'] ?? '',
      lastMessageAt: lastMsg,
      lastSenderId: data['lastSenderId'] ?? '',
      participants: List<String>.from(data['participants'] ?? []),
      buyerId: data['buyerId'] ?? '',
      buyerName: data['buyerName'] ?? 'Buyer',
      sellerId: data['sellerId'] ?? '',
      sellerName: data['sellerName'] ?? 'Seller',
    );
  }
}
