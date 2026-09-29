import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class LocationSelectScreen extends StatefulWidget {
  final String selectedLocation;

  const LocationSelectScreen({Key? key, this.selectedLocation = 'All India'}) : super(key: key);

  @override
  State<LocationSelectScreen> createState() => _LocationSelectScreenState();
}

class _LocationSelectScreenState extends State<LocationSelectScreen> {
  late String _currentLocation;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _popularCities = [
    'All India',
    'Chennai',
    'Coimbatore',
    'Madurai',
    'Bangalore',
    'Hyderabad',
    'Mumbai',
    'Delhi NCR',
    'Kolkata',
    'Pune',
    'Ahmedabad',
    'Kochi',
    'Trichy',
    'Salem',
  ];

  final Map<String, List<String>> _statesAndCities = {
    'Tamil Nadu': ['Chennai', 'Coimbatore', 'Madurai', 'Trichy', 'Salem', 'Tirunelveli', 'Erode', 'Vellore', 'Thanjavur'],
    'Karnataka': ['Bangalore', 'Mysore', 'Hubli', 'Mangalore', 'Belgaum'],
    'Kerala': ['Kochi', 'Thiruvananthapuram', 'Kozhikode', 'Thrissur', 'Kannur'],
    'Maharashtra': ['Mumbai', 'Pune', 'Nagpur', 'Nashik', 'Aurangabad'],
    'Telangana & AP': ['Hyderabad', 'Visakhapatnam', 'Vijayawada', 'Warangal', 'Guntur'],
    'Delhi & NCR': ['New Delhi', 'Noida', 'Gurugram', 'Faridabad', 'Ghaziabad'],
  };

  @override
  void initState() {
    super.initState();
    _currentLocation = widget.selectedLocation;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Select Location', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search city, state or district...',
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                suffixIcon: query.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _searchController.clear()))
                    : null,
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Current / All India Option
                ListTile(
                  tileColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  leading: const Icon(Icons.public, color: AppColors.primary),
                  title: const Text('All India (All Locations)', style: TextStyle(fontWeight: FontWeight.bold)),
                  trailing: _currentLocation == 'All India'
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : null,
                  onTap: () {
                    Navigator.pop(context, 'All India');
                  },
                ),
                const SizedBox(height: 16),

                // Popular Cities
                const Text('Popular Cities', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _popularCities.map((city) {
                    final isSelected = _currentLocation.toLowerCase() == city.toLowerCase();
                    return ChoiceChip(
                      label: Text(city),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (_) {
                        Navigator.pop(context, city);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // States & Districts
                const Text('Browse by State', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                ..._statesAndCities.entries.map((entry) {
                  final state = entry.key;
                  final cities = entry.value;

                  // Filter if search query exists
                  final filteredCities = query.isEmpty
                      ? cities
                      : cities.where((c) => c.toLowerCase().contains(query) || state.toLowerCase().contains(query)).toList();

                  if (query.isNotEmpty && filteredCities.isEmpty && !state.toLowerCase().contains(query)) {
                    return const SizedBox.shrink();
                  }

                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: ExpansionTile(
                      leading: const Icon(Icons.location_city, color: AppColors.primary),
                      title: Text(state, style: const TextStyle(fontWeight: FontWeight.bold)),
                      initiallyExpanded: query.isNotEmpty,
                      children: filteredCities.map((city) {
                        return ListTile(
                          title: Text(city),
                          trailing: const Icon(Icons.chevron_right, size: 18),
                          onTap: () {
                            Navigator.pop(context, '$city, $state');
                          },
                        );
                      }).toList(),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
