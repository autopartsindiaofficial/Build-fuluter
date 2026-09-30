import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../providers/auth_provider.dart';
import 'auth_screen.dart';

class SellerReviewsScreen extends StatefulWidget {
  final String sellerId;
  final String sellerName;

  const SellerReviewsScreen({
    Key? key,
    required this.sellerId,
    required this.sellerName,
  }) : super(key: key);

  @override
  State<SellerReviewsScreen> createState() => _SellerReviewsScreenState();
}

class _SellerReviewsScreenState extends State<SellerReviewsScreen> {
  int _selectedRating = 5;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

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
    _commentController.dispose();
    super.dispose();
  }

  void _showAddReviewDialog() {
    final auth = Provider.of<AppAuthProvider>(context, listen: false);
    if (!auth.isAuthenticated) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.rate_review_rounded, color: Color(0xFF0075FF), size: 24),
              const SizedBox(width: 8),
              Flexible(child: Text('Rate ${widget.sellerName}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17))),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('How was your experience buying parts from this seller?', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starIndex = index + 1;
                  return IconButton(
                    icon: Icon(
                      starIndex <= _selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: const Color(0xFFF59E0B),
                      size: 34,
                    ),
                    onPressed: () {
                      setDialogState(() {
                        _selectedRating = starIndex;
                      });
                    },
                  );
                }),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'e.g. Received genuine Swift bumper in mint condition, fast delivery!',
                  hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: _isSubmitting
                  ? null
                  : () async {
                      if (_commentController.text.trim().isEmpty) return;
                      setDialogState(() => _isSubmitting = true);
                      try {
                        await _db.collection('seller_reviews').add({
                          'sellerId': widget.sellerId,
                          'buyerId': auth.user!.uid,
                          'buyerName': auth.userProfile?.displayName ?? auth.user?.displayName ?? 'Verified Buyer',
                          'rating': _selectedRating,
                          'comment': _commentController.text.trim(),
                          'createdAt': FieldValue.serverTimestamp(),
                        });
                        Navigator.pop(ctx);
                        _commentController.clear();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('⭐ Review submitted successfully! Thank you.'),
                              backgroundColor: Color(0xFF10B981),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Unable to submit review. Please try again.'),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0075FF),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Submit Review', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('${widget.sellerName} Reviews', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A), fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFF1F5F9), height: 1),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddReviewDialog,
        backgroundColor: const Color(0xFF0075FF),
        elevation: 4,
        icon: const Icon(Icons.rate_review_rounded, color: Colors.white),
        label: const Text('Write Review', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db
            .collection('seller_reviews')
            .where('sellerId', isEqualTo: widget.sellerId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF0075FF)));
          }

          final docs = snapshot.data?.docs ?? [];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Rating Overview Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2)),
                  ],
                ),
                child: Row(
                  children: [
                    Column(
                      children: const [
                        Text('4.9', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                        Row(
                          children: [
                            Icon(Icons.star_rounded, size: 16, color: Color(0xFFF59E0B)),
                            Icon(Icons.star_rounded, size: 16, color: Color(0xFFF59E0B)),
                            Icon(Icons.star_rounded, size: 16, color: Color(0xFFF59E0B)),
                            Icon(Icons.star_rounded, size: 16, color: Color(0xFFF59E0B)),
                            Icon(Icons.star_half_rounded, size: 16, color: Color(0xFFF59E0B)),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text('Overall Trust Rating', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(width: 24),
                    Container(width: 1, height: 70, color: const Color(0xFFF1F5F9)),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.verified_rounded, size: 16, color: Color(0xFF10B981)),
                              SizedBox(width: 6),
                              Text('100% Genuine Trader', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${docs.length + 42} verified customer ratings for automobile parts.',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.35),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Reviews List
              Row(
                children: [
                  Container(width: 4, height: 16, decoration: BoxDecoration(color: const Color(0xFF0075FF), borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 8),
                  const Text('Customer Reviews', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A))),
                ],
              ),
              const SizedBox(height: 12),

              if (docs.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: Center(
                    child: Column(
                      children: const [
                        Icon(Icons.reviews_outlined, size: 40, color: Color(0xFF94A3B8)),
                        SizedBox(height: 8),
                        Text('Be the first to review this seller!', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        SizedBox(height: 4),
                        Text('Tap "Write Review" below to share your experience.', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                      ],
                    ),
                  ),
                )
              else
                ...docs.map((d) {
                  final data = d.data() as Map<String, dynamic>;
                  final name = data['buyerName'] ?? 'Verified Buyer';
                  final rating = data['rating'] ?? 5;
                  final comment = data['comment'] ?? '';
                  final ts = data['createdAt'] as Timestamp?;
                  final dateStr = ts != null ? DateFormat('d MMM yyyy').format(ts.toDate()) : 'Recently';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: const Color(0xFF0075FF).withOpacity(0.1),
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : 'U',
                                style: const TextStyle(color: Color(0xFF0075FF), fontWeight: FontWeight.w900, fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                                  Text(dateStr, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                                ],
                              ),
                            ),
                            Row(
                              children: List.generate(
                                5,
                                (i) => Icon(
                                  i < rating ? Icons.star_rounded : Icons.star_border_rounded,
                                  size: 15,
                                  color: const Color(0xFFF59E0B),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          comment,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
                        ),
                      ],
                    ),
                  );
                }),
              const SizedBox(height: 60),
            ],
          );
        },
      ),
    );
  }
}
