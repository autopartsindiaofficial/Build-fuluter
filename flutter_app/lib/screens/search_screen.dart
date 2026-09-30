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
    _loadDynamicFilters();
  }

  Future<void> _loadDynamicFilters() async {
    try {
      final catSnap = await _db.collection('topCategories').where('active', isEqualTo: true).get();
      if (catSnap.docs.isNotEmpty) {
        for (var doc in catSnap.docs) {
          final name = (doc.data()['name'] as String? ?? '').trim();
          if (name.isNotEmpty && !_categories.contains(name)) {
            _categories.add(name);
          }
        }
      }

      final brandSnap = await _db.collection('carBrands').where('active', isEqualTo: true).get();
      if (brandSnap.docs.isNotEmpty) {
        for (var doc in brandSnap.docs) {
          final name = (doc.data()['name'] as String? ?? '').trim();
          if (name.isNotEmpty && !_popularBrands.contains(name)) {
            _popularBrands.add(name);
          }
        }
      }

      if (mounted) setState(() {});
    } catch (_) {}
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

  int get _activeFilterCount {
    int count = 0;
    if (_selectedCategory != 'All Categories') count++;
    if (_selectedBrand != 'All Brands') count++;
    if (_selectedCondition != 'All Conditions') count++;
    if (_sortBy != 'newest') count++;
    return count;
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.tune_rounded, color: Color(0xFF0075FF), size: 22),
                      const SizedBox(width: 8),
                      const Text(
                        'Filters & Sorting',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
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
                    child: const Text('Reset All', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const Divider(color: Color(0xFFF1F5F9)),
              Expanded(
                child: ListView(
                  children: [
                    // Sort By
                    const Text('Sort By', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A))),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildModalChip('newest', '✨ Newest First', _sortBy, (val) => setModalState(() => _sortBy = val)),
                        _buildModalChip('price_low', '₹ Price: Low to High', _sortBy, (val) => setModalState(() => _sortBy = val)),
                        _buildModalChip('price_high', '₹ Price: High to Low', _sortBy, (val) => setModalState(() => _sortBy = val)),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Condition
                    const Text('Part Condition', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A))),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildModalChip('All Conditions', 'All', _selectedCondition, (val) => setModalState(() => _selectedCondition = val)),
                        _buildModalChip('Brand New', '✨ Brand New', _selectedCondition, (val) => setModalState(() => _selectedCondition = val)),
                        _buildModalChip('Used', '🔧 Used / Pre-owned', _selectedCondition, (val) => setModalState(() => _selectedCondition = val)),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Brand Filter
                    const Text('Car Brand', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A))),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _popularBrands.map((b) {
                        return _buildModalChip(b, b, _selectedBrand, (val) => setModalState(() => _selectedBrand = val));
                      }).toList(),
                    ),
                    const SizedBox(height: 18),

                    // Category
                    const Text('Category', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A))),
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
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0075FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
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

  Widget _buildModalChip(String value, String label, String currentSelected, Function(String) onSelect) {
    final isSelected = currentSelected == value;
    return GestureDetector(
      onTap: () => onSelect(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0075FF) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFF0075FF) : const Color(0xFFE2E8F0)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF334155),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Container(
          height: 42,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _searchCtrl,
            autofocus: false,
            textInputAction: TextInputAction.search,
            onSubmitted: (val) {
              _saveSearchQuery(val);
              setState(() {});
            },
            decoration: InputDecoration(
              hintText: lang.t('searchPlaceholder'),
              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF0075FF), size: 20),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.cancel_rounded, color: Color(0xFF94A3B8), size: 18),
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
          // Filter Trigger with active count badge
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.tune_rounded, color: Color(0xFF0F172A), size: 22),
                onPressed: _showFilterModal,
              ),
              if (_activeFilterCount > 0)
                Positioned(
                  top: 10,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF0075FF),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '$_activeFilterCount',
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFF1F5F9), height: 1),
        ),
      ),
      body: Column(
        children: [
          // Trending / Quick Suggestions Rail
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: SizedBox(
              height: 30,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _trendingSuggestions.length,
                itemBuilder: (context, i) {
                  final s = _trendingSuggestions[i];
                  return GestureDetector(
                    onTap: () {
                      _searchCtrl.text = s;
                      _saveSearchQuery(s);
                      setState(() {});
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.trending_up_rounded, size: 13, color: Color(0xFF0075FF)),
                          const SizedBox(width: 4),
                          Text(s, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Recent Searches Bar (If search input is empty)
          if (_searchCtrl.text.isEmpty && _recentSearches.isNotEmpty)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Searches',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF64748B)),
                      ),
                      GestureDetector(
                        onTap: _clearRecentSearches,
                        child: const Text('Clear All', style: TextStyle(color: Color(0xFFEF4444), fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _recentSearches.map((q) {
                      return GestureDetector(
                        onTap: () {
                          _searchCtrl.text = q;
                          setState(() {});
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.history_rounded, size: 13, color: Color(0xFF0075FF)),
                              const SizedBox(width: 4),
                              Text(q, style: const TextStyle(fontSize: 11, color: Color(0xFF1D4ED8), fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

          // Live Filter Chips Row
          if (_selectedCategory != 'All Categories' || _selectedBrand != 'All Brands' || _selectedCondition != 'All Conditions')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFFF8FAFC),
              child: Row(
                children: [
                  const Text('Applied: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                  if (_selectedCategory != 'All Categories')
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(8)),
                      child: Text(_selectedCategory, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                    ),
                  if (_selectedBrand != 'All Brands')
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(8)),
                      child: Text(_selectedBrand, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                    ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = 'All Categories';
                        _selectedBrand = 'All Brands';
                        _selectedCondition = 'All Conditions';
                      });
                    },
                    child: const Text('Reset', style: TextStyle(color: Color(0xFFEF4444), fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

          // Results Grid Stream
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _db.collection('spareParts').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF0075FF)));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                var parts = snapshot.data!.docs.map((d) => SparePart.fromFirestore(d)).toList();

                // 1. Text Query Filter
                final query = _searchCtrl.text.trim().toLowerCase();
                if (query.isNotEmpty) {
                  parts = parts.where((p) {
                    final t = p.title.toLowerCase();
                    final c = p.category.toLowerCase();
                    final b = p.carBrand.toLowerCase();
                    final m = p.carModel.toLowerCase();
                    final o = (p.oemNumber ?? '').toLowerCase();
                    return t.contains(query) || c.contains(query) || b.contains(query) || m.contains(query) || o.contains(query);
                  }).toList();
                }

                // 2. Category Filter
                if (_selectedCategory != 'All Categories') {
                  parts = parts.where((p) => p.category.toLowerCase() == _selectedCategory.toLowerCase()).toList();
                }

                // 3. Brand Filter
                if (_selectedBrand != 'All Brands') {
                  parts = parts.where((p) => p.carBrand.toLowerCase() == _selectedBrand.toLowerCase()).toList();
                }

                // 4. Condition Filter
                if (_selectedCondition != 'All Conditions') {
                  parts = parts.where((p) {
                    if (_selectedCondition == 'Brand New') {
                      return p.condition.toLowerCase().contains('new');
                    } else {
                      return !p.condition.toLowerCase().contains('new');
                    }
                  }).toList();
                }

                // 5. Sorting
                if (_sortBy == 'price_low') {
                  parts.sort((a, b) => a.price.compareTo(b.price));
                } else if (_sortBy == 'price_high') {
                  parts.sort((a, b) => b.price.compareTo(a.price));
                }

                if (parts.isEmpty) {
                  return _buildEmptyState();
                }

                final screenWidth = MediaQuery.of(context).size.width;
                final crossAxisCount = screenWidth >= 900 ? 4 : (screenWidth >= 600 ? 3 : 2);
                final childAspectRatio = screenWidth < 360 ? 0.65 : 0.70;

                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                        child: Text(
                          '${parts.length} Spare ${parts.length == 1 ? 'Part' : 'Parts'} Found',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF64748B)),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: childAspectRatio,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => ProductCard(part: parts[index]),
                          childCount: parts.length,
                        ),
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search_off_rounded, size: 48, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Matching Spare Parts',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 6),
            const Text(
              'Check your spelling or reset filters to see all available auto parts across India.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
