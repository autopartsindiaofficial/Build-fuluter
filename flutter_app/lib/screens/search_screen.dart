import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';
import '../models/spare_part.dart';
import '../providers/language_provider.dart';
import '../widgets/product_card.dart';

class SearchScreen extends StatefulWidget {
  final String? initialQuery;
  final String? initialCategory;
  final String? initialBrand;

  const SearchScreen({
    Key? key,
    this.initialQuery,
    this.initialCategory,
    this.initialBrand,
  }) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedCategory = 'All Categories';
  String _selectedBrand = 'All Brands';
  String _selectedCondition = 'All Conditions';
  String _sortBy = 'newest'; // 'newest', 'price_low', 'price_high'
  List<String> _recentSearches = [];

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

  final List<String> _popularBrands = [
    'All Brands',
    'Maruti Suzuki',
    'Hyundai',
    'Tata',
    'Mahindra',
    'Toyota',
    'Honda',
    'Kia',
    'Volkswagen',
    'Skoda',
    'Ford',
  ];

  final List<String> _categories = [
    'All Categories',
    'Engine & Mechanical',
    'Body & Exterior',
    'Lights & Electricals',
    'Suspension & Brakes',
    'Interior & Dashboard',
    'Transmission & Clutch',
  ];

  final List<String> _trendingSuggestions = [
    'Swift Bumper',
    'Creta Headlight',
    'Thar Grille',
    'Innova Brake Disc',
    'Nexon Tail Light',
    'Brezza ORVM Mirror',
    'Fortuner Shock Absorber',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) _searchCtrl.text = widget.initialQuery!;
    if (widget.initialCategory != null) _selectedCategory = widget.initialCategory!;
    if (widget.initialBrand != null) _selectedBrand = widget.initialBrand!;
    _loadRecentSearches();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('recent_part_searches') ?? [];
      setState(() => _recentSearches = list);
    } catch (_) {}
  }

  Future<void> _saveSearchQuery(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      var list = prefs.getStringList('recent_part_searches') ?? [];
      list.remove(clean);
      list.insert(0, clean);
      if (list.length > 8) list = list.sublist(0, 8);
      await prefs.setStringList('recent_part_searches', list);
      setState(() => _recentSearches = list);
    } catch (_) {}
  }

  Future<void> _clearRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('recent_part_searches');
      setState(() => _recentSearches = []);
    } catch (_) {}
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height * 0.70,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Filters & Sorting', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A))),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedCategory = 'All Categories';
                        _selectedBrand = 'All Brands';
                        _selectedCondition = 'All Conditions';
                        _sortBy = 'newest';
                      });
                      Navigator.pop(ctx);
                    },
                    child: const Text('Reset All', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: ListView(
                  children: [
                    // Sort By
                    const Text('Sort By', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildModalChip('newest', '✨ Newest First', _sortBy, (val) => setModalState(() => _sortBy = val)),
                        _buildModalChip('price_low', '₹ Price: Low to High', _sortBy, (val) => setModalState(() => _sortBy = val)),
                        _buildModalChip('price_high', '₹ Price: High to Low', _sortBy, (val) => setModalState(() => _sortBy = val)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Condition
                    const Text('Part Condition', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildModalChip('All Conditions', 'All', _selectedCondition, (val) => setModalState(() => _selectedCondition = val)),
                        _buildModalChip('Brand New', '✨ Brand New', _selectedCondition, (val) => setModalState(() => _selectedCondition = val)),
                        _buildModalChip('Used', '🔧 Used / Pre-owned', _selectedCondition, (val) => setModalState(() => _selectedCondition = val)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Category
                    const Text('Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _categories.map((c) {
                        return _buildModalChip(c, c, _selectedCategory, (val) => setModalState(() => _selectedCategory = val));
                      }).toList(),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0075FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    setState(() {});
                    Navigator.pop(ctx);
                  },
                  child: const Text('Apply Filters', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModalChip(String key, String label, String currentVal, Function(String) onSelect) {
    final isSelected = currentVal == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: const Color(0xFF0075FF),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? Colors.white : const Color(0xFF334155),
      ),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isSelected ? const Color(0xFF0075FF) : const Color(0xFFE2E8F0)),
      ),
      onSelected: (val) {
        if (val) onSelect(key);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final queryText = _searchCtrl.text.trim().toLowerCase();
    final hasFilterApplied = _selectedCategory != 'All Categories' || _selectedBrand != 'All Brands' || _selectedCondition != 'All Conditions' || _sortBy != 'newest';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Container(
          height: 40,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            controller: _searchCtrl,
            autofocus: widget.initialQuery == null,
            onSubmitted: (val) {
              _saveSearchQuery(val);
              setState(() {});
            },
            onChanged: (val) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search parts, brands, OEM numbers...',
              hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
              prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF0075FF)),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() {});
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.tune,
              color: hasFilterApplied ? const Color(0xFF0075FF) : const Color(0xFF0F172A),
            ),
            onPressed: _showFilterModal,
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Horizontal Quick Filters Bar
          Container(
            height: 44,
            color: Colors.white,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              children: [
                // Filter Modal Trigger Pill
                GestureDetector(
                  onTap: _showFilterModal,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: hasFilterApplied ? const Color(0xFF0075FF).withOpacity(0.12) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: hasFilterApplied ? const Color(0xFF0075FF) : const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.tune, size: 14, color: hasFilterApplied ? const Color(0xFF0075FF) : const Color(0xFF64748B)),
                        const SizedBox(width: 4),
                        Text(
                          'Filters',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: hasFilterApplied ? const Color(0xFF0075FF) : const Color(0xFF334155),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Popular Brands Pills
                ..._popularBrands.map((b) {
                  final isSelected = _selectedBrand == b;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedBrand = isSelected && b != 'All Brands' ? 'All Brands' : b;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF0075FF) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isSelected ? const Color(0xFF0075FF) : const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        b,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.white : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),

          // 2. Results Stream OR Search History Suggestions
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _db.collection('spareParts').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF0075FF)));
                }

                final allDocs = snapshot.data?.docs ?? [];

                // Filter logic matching React Native searchHelper
                var matched = allDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  if (data['isDeleted'] == true || data['status'] == 'deleted') return false;

                  final title = (data['title'] ?? '').toString().toLowerCase();
                  final brand = (data['carBrand'] ?? '').toString().toLowerCase();
                  final model = (data['carModel'] ?? '').toString().toLowerCase();
                  final category = (data['category'] ?? '').toString().toLowerCase();
                  final subcategory = (data['subcategory'] ?? '').toString().toLowerCase();
                  final oem = (data['oemNumber'] ?? '').toString().toLowerCase();
                  final desc = (data['description'] ?? '').toString().toLowerCase();
                  final condition = (data['condition'] ?? '').toString().toLowerCase();

                  // Query search matching
                  if (queryText.isNotEmpty) {
                    final terms = queryText.split(' ').where((t) => t.isNotEmpty);
                    final fullText = '$title $brand $model $category $subcategory $oem $desc';
                    for (var term in terms) {
                      if (!fullText.contains(term)) return false;
                    }
                  }

                  // Brand filter
                  if (_selectedBrand != 'All Brands' && !brand.contains(_selectedBrand.toLowerCase())) {
                    return false;
                  }

                  // Category filter
                  if (_selectedCategory != 'All Categories' && !category.contains(_selectedCategory.toLowerCase())) {
                    return false;
                  }

                  // Condition filter
                  if (_selectedCondition == 'Brand New' && !condition.contains('new')) {
                    return false;
                  } else if (_selectedCondition == 'Used' && condition.contains('new')) {
                    return false;
                  }

                  return true;
                }).toList();

                // Sort logic
                matched.sort((a, b) {
                  final dataA = a.data() as Map<String, dynamic>;
                  final dataB = b.data() as Map<String, dynamic>;

                  if (_sortBy == 'price_low') {
                    final priceA = (dataA['price'] is num ? dataA['price'] : 0) as num;
                    final priceB = (dataB['price'] is num ? dataB['price'] : 0) as num;
                    return priceA.compareTo(priceB);
                  } else if (_sortBy == 'price_high') {
                    final priceA = (dataA['price'] is num ? dataA['price'] : 0) as num;
                    final priceB = (dataB['price'] is num ? dataB['price'] : 0) as num;
                    return priceB.compareTo(priceA);
                  } else {
                    // Newest first
                    final timeA = dataA['createdAt'] ?? 0;
                    final timeB = dataB['createdAt'] ?? 0;
                    return (timeB is num ? timeB : 0).compareTo(timeA is num ? timeA : 0);
                  }
                });

                // If user hasn't typed anything and no filter applied, show recent searches & trending
                if (queryText.isEmpty && !hasFilterApplied) {
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Recent Searches
                      if (_recentSearches.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Recent Searches', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
                            GestureDetector(
                              onTap: _clearRecentSearches,
                              child: const Text('Clear All', style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _recentSearches.map((s) {
                            return ActionChip(
                              avatar: const Icon(Icons.history, size: 16, color: Color(0xFF64748B)),
                              label: Text(s),
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: Color(0xFFE2E8F0)),
                              onPressed: () {
                                _searchCtrl.text = s;
                                setState(() {});
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Trending Searches
                      const Text('Trending Spares & Components', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _trendingSuggestions.map((t) {
                          return ActionChip(
                            avatar: const Icon(Icons.trending_up, size: 16, color: Color(0xFF0075FF)),
                            label: Text(t),
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                            onPressed: () {
                              _searchCtrl.text = t;
                              _saveSearchQuery(t);
                              setState(() {});
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  );
                }

                // If no results match
                if (matched.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                            child: const Icon(Icons.search_off, size: 48, color: Colors.grey),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            queryText.isNotEmpty ? 'No spare parts found for "$queryText"' : 'No parts match filters',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Try checking spelling or removing filters to see more results.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Results Grid
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                      child: Text(
                        'Found ${matched.length} spare parts',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                      ),
                    ),
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.70,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: matched.length,
                        itemBuilder: (context, index) {
                          return ProductCard(part: SparePart.fromFirestore(matched[index]));
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
