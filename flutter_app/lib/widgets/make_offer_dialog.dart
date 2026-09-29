import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../models/spare_part.dart';
import '../services/firebase_service.dart';

class MakeOfferDialog extends StatefulWidget {
  final SparePart part;
  final String currentUserId;
  final String currentUserName;

  const MakeOfferDialog({
    Key? key,
    required this.part,
    required this.currentUserId,
    required this.currentUserName,
  }) : super(key: key);

  @override
  State<MakeOfferDialog> createState() => _MakeOfferDialogState();
}

class _MakeOfferDialogState extends State<MakeOfferDialog> {
  final _amountController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Default suggestion: 90% of listed price
    final suggested = (widget.part.price * 0.9).round();
    _amountController.text = suggested.toString();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitOffer() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid offer amount.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final firebaseService = FirebaseService();

    try {
      final chatId = await firebaseService.getOrCreateChat(
        buyerId: widget.currentUserId,
        sellerId: widget.part.sellerId,
        partId: widget.part.id,
        partTitle: widget.part.title,
        partImageUrl: widget.part.imageUrl,
        partPrice: widget.part.price,
        buyerName: widget.currentUserName,
        sellerName: widget.part.contactName ?? 'Seller',
      );

      final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
      final offerText = '🏷️ Offer Made: ${currencyFormatter.format(amount)}\n${_messageController.text.trim()}';

      await firebaseService.sendMessage(
        conversationId: chatId,
        senderId: widget.currentUserId,
        senderName: widget.currentUserName,
        text: offerText,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Offer sent to seller via chat!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send offer: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Make an Offer',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Original Price: ${currencyFormatter.format(widget.part.price)}',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Your Offer Price (₹)',
                prefixIcon: Icon(Icons.currency_rupee, size: 20),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _messageController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Add a message (Optional)',
                hintText: 'e.g. Can pick up today evening in Chennai',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitOffer,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Send Offer to Seller', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
