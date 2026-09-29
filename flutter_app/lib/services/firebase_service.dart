import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/spare_part.dart';
import '../models/chat_message.dart';

class FirebaseService {
  static const String customDatabaseId = 'ai-studio-autopartsmarketp-6b6de595-2abc-431d-a6dc-0141a5eff96f';

  FirebaseFirestore get _db {
    try {
      return FirebaseFirestore.instanceFor(
        app: FirebaseFirestore.instance.app,
        databaseId: customDatabaseId,
      );
    } catch (_) {
      return FirebaseFirestore.instance;
    }
  }

  // Stream of recent spare parts
  Stream<List<SparePart>> getSparePartsStream({String? category, String? brand}) {
    Query query = _db.collection('spareParts').orderBy('createdAt', descending: true);
    
    if (category != null && category.isNotEmpty && category != 'All') {
      query = query.where('category', isEqualTo: category);
    }
    if (brand != null && brand.isNotEmpty && brand != 'All') {
      query = query.where('carBrand', isEqualTo: brand);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => SparePart.fromFirestore(doc)).toList();
    });
  }

  // Search spare parts
  Future<List<SparePart>> searchParts(String query) async {
    final lowerQuery = query.toLowerCase().trim();
    final snapshot = await _db.collection('spareParts').get();
    
    return snapshot.docs
        .map((doc) => SparePart.fromFirestore(doc))
        .where((part) {
          return part.title.toLowerCase().contains(lowerQuery) ||
                 part.carBrand.toLowerCase().contains(lowerQuery) ||
                 part.carModel.toLowerCase().contains(lowerQuery) ||
                 part.category.toLowerCase().contains(lowerQuery) ||
                 (part.description?.toLowerCase().contains(lowerQuery) ?? false);
        })
        .toList();
  }

  // Add new spare part
  Future<String> addSparePart(SparePart part) async {
    final docRef = await _db.collection('spareParts').add(part.toMap());
    return docRef.id;
  }

  // Update spare part
  Future<void> updateSparePart(String id, Map<String, dynamic> data) async {
    await _db.collection('spareParts').doc(id).update(data);
  }

  // Delete spare part
  Future<void> deleteSparePart(String id) async {
    await _db.collection('spareParts').doc(id).delete();
  }

  // Chat conversations
  Stream<List<ChatConversation>> getConversationsStream(String userId) {
    return _db
        .collection('conversations')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ChatConversation.fromFirestore(doc)).toList());
  }

  // Get or Create a chat conversation
  Future<String> getOrCreateChat({
    required String buyerId,
    required String sellerId,
    required String partId,
    String? partTitle,
    String? partImageUrl,
    double? partPrice,
    String? buyerName,
    String? sellerName,
  }) async {
    final convoId = '${buyerId}_${sellerId}_$partId';
    final docRef = _db.collection('conversations').doc(convoId);
    final doc = await docRef.get();

    if (!doc.exists) {
      await docRef.set({
        'partId': partId,
        'partTitle': partTitle ?? 'Automobile Spare Part',
        'partImageUrl': partImageUrl ?? '',
        'partPrice': partPrice ?? 0.0,
        'participants': [buyerId, sellerId],
        'buyerId': buyerId,
        'buyerName': buyerName ?? 'Buyer',
        'sellerId': sellerId,
        'sellerName': sellerName ?? 'Seller',
        'lastMessageText': '',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastSenderId': buyerId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    return convoId;
  }

  // Chat messages for a specific conversation
  Stream<List<ChatMessage>> getMessagesStream(String conversationId) {
    return _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ChatMessage.fromFirestore(doc)).toList());
  }

  // Send message
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    required String text,
  }) async {
    final batch = _db.batch();
    
    final messageRef = _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc();

    batch.set(messageRef, {
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });

    final conversationRef = _db.collection('conversations').doc(conversationId);
    batch.update(conversationRef, {
      'lastMessageText': text,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastSenderId': senderId,
    });

    await batch.commit();
  }
}
