import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/app_colors.dart';
import '../constants/categories_data.dart';
import '../models/spare_part.dart';
import '../services/firebase_service.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';

class SellPartScreen extends StatefulWidget {
  const SellPartScreen({Key? key}) : super(key: key);

  @override
  State<SellPartScreen> createState() => _SellPartScreenState();
}

class _SellPartScreenState extends State<SellPartScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseService _firebaseService = FirebaseService();
  
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _priceCtrl = TextEditingController();
  final TextEditingController _oemCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _locationCtrl = TextEditingController(text: 'Chennai, Tamil Nadu');
  final TextEditingController _phoneCtrl = TextEditingController();

  String _selectedCategory = MASTER_CATEGORIES.first.name;
  String _selectedBrand = TOP_BRANDS.first['name'];
  String _selectedModel = 'Swift';
  String _selectedCondition = 'Used - Excellent';
  bool _isSubmitting = false;

  void _submitAd() async {
    if (!_formKey.currentState!.validate()) return;
    
    final auth = Provider.of<AppAuthProvider>(context, listen: false);
    if (!auth.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to post your spare part ad.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final part = SparePart(
        id: '',
        title: _titleCtrl.text.trim(),
        carBrand: _selectedBrand,
        carModel: _selectedModel,
        category: _selectedCategory,
        condition: _selectedCondition,
        price: double.tryParse(_priceCtrl.text.trim()) ?? 0,
        location: _locationCtrl.text.trim(),
        contactName: auth.userProfile?.displayName ?? auth.user?.displayName ?? 'Seller',
        contactPhone: _phoneCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        imageUrl: 'https://res.cloudinary.com/rqf1hlrx/image/upload/v1788828857/categories/v40ctc1xzsul1nmquwno.png',
        sellerId: auth.user!.uid,
        sellerEmail: auth.user!.email,
        createdAt: DateTime.now(),
        oemNumber: _oemCtrl.text.trim(),
      );

      await _firebaseService.addSparePart(part);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your spare part has been listed successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to list spare part: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          lang.t('postAd'),
          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo Upload Box
              GestureDetector(
                onTap: () async {
                  final picker = ImagePicker();
                  await picker.pickImage(source: ImageSource.gallery);
                },
                child: Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border, style: BorderStyle.solid),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_a_photo_outlined, size: 36, color: AppColors.primary),
                      const SizedBox(height: 6),
                      Text(
                        lang.t('photos'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const Text('Upload up to 5 clear photos of the part', style: TextStyle(color: Colors.grey, fontSize: 11)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
              _buildSectionTitle('Part Title *'),
              TextFormField(
                controller: _titleCtrl,
                validator: (v) => v!.isEmpty ? 'Title is required' : null,
                decoration: _inputDecoration('e.g. Maruti Suzuki Swift Headlight OEM Original'),
              ),

              const SizedBox(height: 16),
              _buildSectionTitle('Category *'),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: MASTER_CATEGORIES.map((c) => DropdownMenuItem(value: c.name, child: Text(c.name))).toList(),
                onChanged: (v) => setState(() => _selectedCategory = v!),
                decoration: _inputDecoration(''),
              ),

              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Car Brand *'),
                        DropdownButtonFormField<String>(
                          value: _selectedBrand,
                          items: TOP_BRANDS.map((b) => DropdownMenuItem(value: b['name'] as String, child: Text(b['name']))).toList(),
                          onChanged: (v) => setState(() => _selectedBrand = v!),
                          decoration: _inputDecoration(''),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Price (₹) *'),
                        TextFormField(
                          controller: _priceCtrl,
                          keyboardType: TextInputType.number,
                          validator: (v) => v!.isEmpty ? 'Price required' : null,
                          decoration: _inputDecoration('₹ 2,500'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              _buildSectionTitle('Contact Phone *'),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                validator: (v) => v!.isEmpty ? 'Phone is required' : null,
                decoration: _inputDecoration('e.g. 9876543210'),
              ),

              const SizedBox(height: 16),
              _buildSectionTitle('Location'),
              TextFormField(
                controller: _locationCtrl,
                decoration: _inputDecoration('City, State'),
              ),

              const SizedBox(height: 16),
              _buildSectionTitle('Description'),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: _inputDecoration('Details about the part condition, compatibility, etc.'),
              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitAd,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Submit & Publish Ad',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary)),
    );
  }
}
