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
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();

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
    {'brand': 'Royal Enfield', 'models': 'Classic 350, Hunter 350, Bullet, Meteor, Himalayan'},
    {'brand': 'Hero MotoCorp', 'models': 'Splendor, HF Deluxe, Glamour, Passion, Xpulse'},
    {'brand': 'Bajaj Auto', 'models': 'Pulsar, Platina, Avenger, Dominar'},
    {'brand': 'TVS', 'models': 'Apache, Jupiter, Raider, Ntorq, XL100'},
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
    _brandController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  void _showAddCategoryDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Spare Part Category'),
        content: TextField(
          controller: _categoryController,
          decoration: const InputDecoration(
            hintText: 'e.g. Turbochargers & Intercoolers',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final cat = _categoryController.text.trim();
              if (cat.isEmpty) return;
              try {
                await FirebaseFirestore.instance.collection('cms_categories').add({
                  'name': cat,
                  'createdAt': FieldValue.serverTimestamp(),
                });
                Navigator.pop(ctx);
                _categoryController.clear();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Category added!'), backgroundColor: Colors.green),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddBrandDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Vehicle Brand & Models'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _brandController,
              decoration: const InputDecoration(
                labelText: 'Brand Name',
                hintText: 'e.g. Kia, Yamaha, Ashok Leyland',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _modelController,
              decoration: const InputDecoration(
                labelText: 'Supported Models (Comma separated)',
                hintText: 'e.g. Seltos, Sonet, Carens',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final brand = _brandController.text.trim();
              final models = _modelController.text.trim();
              if (brand.isEmpty) return;
              try {
                await FirebaseFirestore.instance.collection('cms_brands').add({
                  'brand': brand,
                  'models': models,
                  'createdAt': FieldValue.serverTimestamp(),
                });
                Navigator.pop(ctx);
                _brandController.clear();
                _modelController.clear();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Brand added!'), backgroundColor: Colors.green),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Taxonomy & CMS', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Categories'),
            Tab(text: 'Vehicle Brands'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Categories CMS
          Scaffold(
            floatingActionButton: FloatingActionButton.extended(
              onPressed: _showAddCategoryDialog,
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Add Category', style: TextStyle(color: Colors.white)),
            ),
            body: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('cms_categories').snapshots(),
              builder: (context, snapshot) {
                final customDocs = snapshot.data?.docs ?? [];
                final allCats = [
                  ...customDocs.map((d) => (d.data() as Map<String, dynamic>)['name']?.toString() ?? ''),
                  ..._defaultCategories,
                ];

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: allCats.length,
                  itemBuilder: (context, index) {
                    final cat = allCats[index];
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.car_repair, color: AppColors.primary),
                        title: Text(cat, style: const TextStyle(fontWeight: FontWeight.w600)),
                        trailing: const Icon(Icons.check_circle, color: Colors.green, size: 18),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Brands CMS
          Scaffold(
            floatingActionButton: FloatingActionButton.extended(
              onPressed: _showAddBrandDialog,
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Add Brand', style: TextStyle(color: Colors.white)),
            ),
            body: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('cms_brands').snapshots(),
              builder: (context, snapshot) {
                final customDocs = snapshot.data?.docs ?? [];
                final customBrands = customDocs.map((d) => d.data() as Map<String, dynamic>).toList();
                final allBrands = [...customBrands, ..._defaultBrands];

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: allBrands.length,
                  itemBuilder: (context, index) {
                    final item = allBrands[index];
                    final brand = item['brand'] ?? '';
                    final models = item['models'] ?? '';

                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primaryLight,
                          child: Text(
                            brand.isNotEmpty ? brand[0] : 'V',
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(brand, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          models,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
