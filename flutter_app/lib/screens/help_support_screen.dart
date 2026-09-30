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
        title: const Text('Help & 24/7 Support', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A), fontSize: 18)),
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. 24x7 Customer Support Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0A1938), Color(0xFF0052B4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: const Color(0xFF0075FF).withOpacity(0.24), blurRadius: 16, offset: const Offset(0, 6)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
                      child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Dedicated Trader Support',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Need assistance verifying OEM parts, tracking orders, or resolving trader inquiries? We are available 24/7.',
                  style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13, height: 1.45),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _launchCall,
                        icon: const Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 18),
                        label: const Text('Helpline Call', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _launchEmail,
                        icon: const Icon(Icons.email_rounded, color: Colors.white, size: 18),
                        label: const Text('Email Desk', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 2. Buyer Protection & Safety Rules
          Row(
            children: [
              Container(width: 4, height: 16, decoration: BoxDecoration(color: const Color(0xFF0075FF), borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 8),
              const Text('Buyer Protection Guidelines', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF0F172A))),
            ],
          ),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                _buildProtectionRow(Icons.verified_user_rounded, 'OEM Verification', 'Always cross-check the OEM part number stamped on the component with your car manual.'),
                const Divider(height: 18, color: Color(0xFFF1F5F9)),
                _buildProtectionRow(Icons.handshake_rounded, 'Safe Meetups', 'Meet sellers at an authorized workshop or garage where a mechanic can inspect the part.'),
                const Divider(height: 18, color: Color(0xFFF1F5F9)),
                _buildProtectionRow(Icons.no_photography_rounded, 'No Advance Fees', 'Never transfer courier advances to unverified phone callers before checking the part.'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 3. FAQs Accordion
          Row(
            children: [
              Container(width: 4, height: 16, decoration: BoxDecoration(color: const Color(0xFF0075FF), borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 8),
              const Text('Frequently Asked Questions (FAQ)', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF0F172A))),
            ],
          ),
          const SizedBox(height: 10),

          _buildFaqTile(
            'How do I post a spare part listing?',
            'Tap the "+" Sell button on the bottom navigation dock. Add photos showing OEM labels, select vehicle brand and model, enter price, and submit.',
          ),
          _buildFaqTile(
            'Is listing spare parts free?',
            'Yes! Auto Parts India is 100% free for individual car owners, mechanics, and scrap dealers across India.',
          ),
          _buildFaqTile(
            'How do I negotiate prices safely?',
            'Use our in-app Chat Room to discuss condition and propose offers. Once accepted, you can call the seller to finalize pickup.',
          ),
          _buildFaqTile(
            'How can I edit or mark my part as Sold?',
            'Go to Profile -> My Ads. Tap "Edit" to modify price and details, or tap "Mark Sold" once your part is sold out.',
          ),
          _buildFaqTile(
            'How do I contact sellers directly?',
            'On any spare part details page, tap the green Call icon to dial directly, or tap "Chat with Seller" to start instant in-app messaging.',
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildProtectionRow(IconData icon, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: const Color(0xFF0075FF).withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, size: 18, color: const Color(0xFF0075FF)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
              const SizedBox(height: 2),
              Text(desc, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFaqTile(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ExpansionTile(
        title: Text(question, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A))),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Text(answer, style: const TextStyle(color: Color(0xFF64748B), height: 1.45, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
