import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({Key? key}) : super(key: key);

  void _launchEmail() async {
    final uri = Uri.parse('mailto:support@autopartsindia.com?subject=Customer%20Support%20Enquiry');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _launchCall() async {
    final uri = Uri.parse('tel:+919876543210');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Help & Support', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Contact Channels Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Contact Marketplace Support', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
                const SizedBox(height: 6),
                const Text('Our dedicated team is ready to assist you with listings, orders, or seller inquiries.', style: TextStyle(color: Color(0xFF64748B), fontSize: 13, height: 1.4)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _launchCall,
                        icon: const Icon(Icons.phone, color: Colors.white, size: 18),
                        label: const Text('Toll-Free Call', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _launchEmail,
                        icon: const Icon(Icons.email, color: Colors.white, size: 18),
                        label: const Text('Official Email', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0075FF),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // FAQs
          const Text('Frequently Asked Questions (FAQ)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
          const SizedBox(height: 12),

          _buildFaqTile(
            'How do I post a spare part listing?',
            'Tap the "+" Sell button on the bottom navigation bar. Add clear photos of your spare part, select vehicle brand and model, enter price, and submit.',
          ),
          _buildFaqTile(
            'Is listing spare parts free?',
            'Yes! Auto Parts India is 100% free for individual sellers and auto repair shops.',
          ),
          _buildFaqTile(
            'How do I negotiate or buy parts safely?',
            'Use our in-app Chat Room to discuss details and propose offers. You can also directly call the seller using the Call button.',
          ),
          _buildFaqTile(
            'How can I edit or mark my part as Sold?',
            'Go to Profile -> My Ads. Tap the Edit button to update details, or tap "Mark Sold" once your part is sold.',
          ),
          _buildFaqTile(
            'How do I contact sellers directly?',
            'On any spare part details page, tap "Call Seller" to dial directly, or tap "Chat with Seller" to open instant in-app messaging.',
          ),
        ],
      ),
    );
  }

  Widget _buildFaqTile(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ExpansionTile(
        title: Text(question, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF0F172A))),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(answer, style: const TextStyle(color: Color(0xFF64748B), height: 1.4, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
