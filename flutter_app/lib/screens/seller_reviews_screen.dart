import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../providers/auth_provider.dart';

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

  void _showAddReviewDialog() {
    final auth = Provider.of<AppAuthProvider>(context, listen: false);
    if (!auth.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to submit a review.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Rate ${widget.sellerName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starIndex = index + 1;
                  return IconButton(
                    icon: Icon(
                      starIndex <= _selectedRating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
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
                decoration: const InputDecoration(
                  hintText: 'Share your experience with this seller...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _isSubmitting
                  ? null
                  : () async {
                      if (_commentController.text.trim().isEmpty) return;
                      setDialogState(() => _isSubmitting = true);
                      try {
                        await FirebaseFirestore.instance.collection('seller_reviews').add({
                          'sellerId': widget.sellerId,
                          'buyerId': auth.user!.uid,
                          'buyerName': auth.profile?.displayName ?? 'Buyer',
                          'rating': _selectedRating,
                          'comment': _commentController.text.trim(),
                          'createdAt': FieldValue.serverTimestamp(),
                        });
                        Navigator.pop(ctx);
                        _commentController.clear();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Review submitted!'), backgroundColor: Colors.green),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Submit', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('${widget.sellerName}\'s Reviews', style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddReviewDialog,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.rate_review, color: Colors.white),
        label: const Text('Write Review', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('seller_reviews')
            .where('sellerId', isEqualTo: widget.sellerId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text('No reviews yet for ${widget.sellerName}.', style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  const Text('Be the first to review!', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }

          // Calculate average rating
          double avgRating = 0;
          for (var d in docs) {
            avgRating += (d.data() as Map<String, dynamic>)['rating'] ?? 5;
          }
          avgRating = avgRating / docs.length;

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          avgRating.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        Row(
                          children: List.generate(5, (i) => Icon(
                            i < avgRating.round() ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 18,
                          )),
                        ),
                        Text('${docs.length} Reviews', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                    const VerticalDivider(),
                    const Text('100% Genuine Community Feedback', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final rating = data['rating'] ?? 5;
                    final comment = data['comment'] ?? '';
                    final buyerName = data['buyerName'] ?? 'Anonymous';

                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: AppColors.primaryLight,
                                  child: Text(
                                    buyerName.isNotEmpty ? buyerName[0].toUpperCase() : 'B',
                                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(buyerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                ),
                                Row(
                                  children: List.generate(5, (i) => Icon(
                                    i < rating ? Icons.star : Icons.star_border,
                                    color: Colors.amber,
                                    size: 14,
                                  )),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(comment, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
