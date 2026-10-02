import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_colors.dart';

class AdminTaxonomyScreen extends StatefulWidget {
  const AdminTaxonomyScreen({Key? key}) : super(key: key);

  @override
  State<AdminTaxonomyScreen> createState() => _AdminTaxonomyScreenState();
}

class _AdminTaxonomyScreenState extends State<AdminTaxonomyScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _categoryController = TextEditingController();
  final _subcategoriesController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _brandLogoController = TextEditingController();

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

  final List<String> _defaultCategories = [
    'Engine & Drivetrain',
    'Brakes & Suspension',
    'Electricals & Lights',
    'Body & Panels',
    'Tyres & Wheels',
    'Steering & Transmission',
    'Exhaust & Silencer',
    'Interior & Seats',
    'Mirrors & Glasses',
    'Oils & Fluids',
    'Accessories & GPS',
  ];

  final List<Map<String, dynamic>> _defaultBrands = [
    {'brand': 'Maruti Suzuki', 'models': 'Swift, Dzire, Baleno, Brezza, Alto, WagonR, Ertiga'},
    {'brand': 'Hyundai', 'models': 'i20, Creta, Venue, Verna, Santro, Grand i10'},
    {'brand': 'Tata', 'models': 'Nexon, Punch, Harrier, Safari, Altroz, Tiago'},
    {'brand': 'Mahindra', 'models': 'Thar, Scorpio, XUV700, Bolero, XUV300'},
    {'brand': 'Toyota', 'models': 'Innova, Fortuner, Glanza, Urban Cruiser, Hyryder'},
    {'brand': 'Honda', 'models': 'City, Amaze, Civic, Jazz, WR-V'},
    {'brand': 'Kia', 'models': 'Seltos, Sonet, Carens, Carnival, EV6'},
    {'brand': 'Volkswagen', 'models': 'Virtus, Taigun, Polo, Vento, Tiguan'},
    {'brand': 'Skoda', 'models': 'Slavia, Kushaq, Kodiaq, Octavia, Superb'},
    {'brand': 'Ford', 'models': 'EcoSport, Endeavour, Figo, Aspire'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _categoryController.dispose();
    _subcategoriesController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  void _showAddCategoryDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.category_rounded, color: Color(0xFF0075FF), size: 22),
            SizedBox(width: 8),
            Text('Add Part Category', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _categoryController,
              decoration: InputDecoration(
                labelText: 'Category Name',
                hintText: 'e.g. Turbochargers & Intercoolers',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _subcategoriesController,
              decoration: InputDecoration(
                labelText: 'Sub-Components / Parts',
                hintText: 'Comma separated: e.g. Turbo, Wastegate, Intercooler',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
            onPressed: () async {
              final cat = _categoryController.text.trim();
              final subcats = _subcategoriesController.text.trim();
              if (cat.isEmpty) return;
              try {
                await _db.collection('topCategories').add({
                  'name': cat,
                  'subcategories': subcats,
                  'active': true,
                  'order': 0,
                  'createdAt': FieldValue.serverTimestamp(),
                  'updatedAt': FieldValue.serverTimestamp(),
                });
                Navigator.pop(ctx);
                _categoryController.clear();
                _subcategoriesController.clear();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Category added!'), backgroundColor: Color(0xFF10B981)),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Unable to add category. Please try again.'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0075FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Add Category', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAddBrandDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.directions_car_rounded, color: Color(0xFF0075FF), size: 22),
            SizedBox(width: 8),
            Text('Add Vehicle Brand', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _brandController,
              decoration: InputDecoration(
                labelText: 'Brand Name',
                hintText: 'e.g. Kia, Yamaha, BYD',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _modelController,
              decoration: InputDecoration(
                labelText: 'Supported Models',
                hintText: 'Comma separated: e.g. Seltos, Sonet, Carens',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _brandLogoController,
              decoration: InputDecoration(
                labelText: 'Brand Logo URL (Optional)',
                hintText: 'https://example.com/logo.png',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
            onPressed: () async {
              final brand = _brandController.text.trim();
              final models = _modelController.text.trim();
              final logoUrl = _brandLogoController.text.trim();
              if (brand.isEmpty) return;
              try {
                await _db.collection('carBrands').add({
                  'name': brand,
                  'models': models,
                  'logoUrl': logoUrl,
                  'imageUrl': logoUrl,
                  'active': true,
                  'order': 0,
                  'createdAt': FieldValue.serverTimestamp(),
                  'updatedAt': FieldValue.serverTimestamp(),
                });
                Navigator.pop(ctx);
                _brandController.clear();
                _modelController.clear();
                _brandLogoController.clear();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vehicle Brand & Models Added!'), backgroundColor: Color(0xFF10B981)),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Unable to add brand. Please try again.'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0075FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Save Brand', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Manage Categories & Brands', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A), fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF0075FF),
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: const Color(0xFF0075FF),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          tabs: const [
            Tab(text: 'Categories'),
            Tab(text: 'Vehicle Brands'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_tabController.index == 0) {
            _showAddCategoryDialog();
          } else {
            _showAddBrandDialog();
          }
        },
        backgroundColor: const Color(0xFF0075FF),
        elevation: 4,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Entry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Categories Tab
          StreamBuilder<QuerySnapshot>(
            stream: _db.collection('topCategories').snapshots(),
            builder: (context, snapshot) {
              final customCats = snapshot.data?.docs.map((d) => (d.data() as Map<String, dynamic>)['name']?.toString() ?? '').where((n) => n.isNotEmpty).toList() ?? [];
              final allCats = [...customCats, ..._defaultCategories];

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: allCats.length,
                itemBuilder: (context, index) {
                  final cat = allCats[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: const Color(0xFF0075FF).withOpacity(0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.category_rounded, color: Color(0xFF0075FF), size: 18),
                      ),
                      title: Text(cat, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
                      trailing: index < customCats.length
                          ? IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
                              onPressed: () {
                                snapshot.data!.docs[index].reference.delete();
                              },
                            )
                          : Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                              child: const Text('STANDARD', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                            ),
                    ),
                  );
                },
              );
            },
          ),

          // 2. Brands Tab
          StreamBuilder<QuerySnapshot>(
            stream: _db.collection('carBrands').snapshots(),
            builder: (context, snapshot) {
              final customBrands = snapshot.data?.docs.map((d) {
                final data = d.data() as Map<String, dynamic>;
                return {'brand': data['name'] ?? data['brand'] ?? '', 'models': data['models'] ?? ''};
              }).toList() ?? [];

              final allBrands = [...customBrands, ..._defaultBrands];

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: allBrands.length,
                itemBuilder: (context, index) {
                  final item = allBrands[index];
                  final brandName = item['brand'] ?? '';
                  final modelsStr = item['models'] ?? '';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.1), shape: BoxShape.circle),
                                  child: const Icon(Icons.directions_car_rounded, color: Color(0xFF10B981), size: 18),
                                ),
                                const SizedBox(width: 10),
                                Text(brandName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF0F172A))),
                              ],
                            ),
                            if (index < customBrands.length)
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
                                onPressed: () {
                                  snapshot.data!.docs[index].reference.delete();
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Supported Models:',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          modelsStr,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF334155), height: 1.4),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
