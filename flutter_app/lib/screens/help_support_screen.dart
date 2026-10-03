import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({Key? key}) : super(key: key);

  static const String supportEmail = 'autopartsindia7@gmail.com';

  void _launchEmail(BuildContext context) async {
    final uri = Uri.parse('mailto:$supportEmail?subject=Auto%20Parts%20India%20Support%20Request');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _copyEmail(context);
      }
    } catch (_) {
      _copyEmail(context);
    }
  }

  void _copyEmail(BuildContext context) {
    Clipboard.setData(const ClipboardData(text: supportEmail));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📋 Email address copied: autopartsindia7@gmail.com'),
        backgroundColor: Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Help & Support',
          style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A), fontSize: 18),
        ),
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
          // 1. Official Email Support Card
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
                BoxShadow(
                  color: const Color(0xFF0075FF).withOpacity(0.24),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.mail_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Official Email Support',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Colors.white),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Quick assistance for all users & traders',
                            style: TextStyle(fontSize: 12, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Have questions about your spare part listings, account assistance, or platform feedback? Contact our team directly via email.',
                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, height: 1.45),
                ),
                const SizedBox(height: 16),

                // Email Address Container with Copy Action
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.18)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.alternate_email_rounded, color: Color(0xFF38BDF8), size: 18),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: SelectableText(
                          supportEmail,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => _copyEmail(context),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.copy_rounded, color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text('Copy', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Primary Send Email Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _launchEmail(context),
                    icon: const Icon(Icons.send_rounded, color: Color(0xFF0F172A), size: 18),
                    label: const Text(
                      'Open Mail & Send Message',
                      style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0F172A),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 2. Buyer Protection & Safety Guidelines
          Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(color: const Color(0xFF0075FF), borderRadius: BorderRadius.circular(2)),
              ),
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
                _buildProtectionRow(Icons.no_photography_rounded, 'No Advance Fees', 'Never transfer courier advances to unverified callers before checking the part in person.'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 3. FAQs Accordion
          Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(color: const Color(0xFF0075FF), borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 8),
              const Text('Frequently Asked Questions (FAQ)', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF0F172A))),
            ],
          ),
          const SizedBox(height: 10),

          _buildFaqTile(
            'How do I contact Auto Parts India support?',
            'You can write directly to our official support email at autopartsindia7@gmail.com. We answer inquiries regarding listings, account verification, and technical help.',
          ),
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
            'Use our in-app Chat Room to discuss condition and propose offers. Once accepted, you can arrange a meetup to inspect and finalize the deal.',
          ),
          _buildFaqTile(
            'How can I edit or mark my part as Sold?',
            'Go to Profile -> My Ads. Tap "Edit" to modify price and details, or tap "Mark Sold" once your part is sold out.',
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
