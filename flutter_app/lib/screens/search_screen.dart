import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/spare_part.dart';
import '../services/firebase_service.dart';
import '../providers/language_provider.dart';
import '../widgets/product_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();
  List<SparePart> _results = [];
  bool _isLoading = false;

  void _onSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final res = await _firebaseService.searchParts(query);
      setState(() => _results = res);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _searchCtrl,
          autofocus: true,
          onChanged: _onSearch,
          decoration: InputDecoration(
            hintText: lang.t('searchPlaceholder'),
            border: InputBorder.none,
            hintStyle: const TextStyle(fontSize: 14, color: AppColors.textMuted),
          ),
        ),
        actions: [
          if (_searchCtrl.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.grey),
              onPressed: () {
                _searchCtrl.clear();
                setState(() => _results = []);
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _searchCtrl.text.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.search, size: 60, color: Colors.grey),
                      SizedBox(height: 12),
                      Text(
                        'Type to search for engines, bumpers, lights...',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : _results.isEmpty
                  ? Center(
                      child: Text(
                        'No results found for "${_searchCtrl.text}"',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.72,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: _results.length,
                      itemBuilder: (context, index) => ProductCard(part: _results[index]),
                    ),
    );
  }
}
