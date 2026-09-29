import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/language_provider.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'sell_part_screen.dart';
import 'chats_screen.dart';
import 'profile_screen.dart';

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({Key? key}) : super(key: key);

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const SearchScreen(),
    const SizedBox(), // Placeholder for Sell Tab trigger
    const ChatsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey.shade500,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        onTap: (index) {
          if (index == 2) {
            // Open Sell Part modal screen
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SellPartScreen()),
            );
          } else {
            setState(() => _currentIndex = index);
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: lang.t('home'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.search),
            activeIcon: const Icon(Icons.search, color: AppColors.primary),
            label: lang.t('search'),
          ),
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 20),
            ),
            label: lang.t('sell'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.chat_bubble_outline),
            activeIcon: const Icon(Icons.chat_bubble),
            label: lang.t('chats'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            activeIcon: const Icon(Icons.person),
            label: lang.t('profile'),
          ),
        ],
      ),
    );
  }
}
