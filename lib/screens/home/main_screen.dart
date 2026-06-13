import 'package:flutter/material.dart';
import '../../utils/theme.dart';
import '../home/home_screen.dart';
import '../pets/pets_screen.dart';
import '../pengingat/pengingat_screen.dart';
import '../chatbot/chatbot_screen.dart';
import '../profile/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  int _homeRefreshKey = 0;
  int _profileRefreshKey = 0;

  Widget _getCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return HomeScreen(key: ValueKey('home_$_homeRefreshKey'));
      case 1:
        return const PetsScreen();
      case 2:
        return const ChatbotScreen();
      case 3:
        return const PengingatScreen();
      case 4:
        return ProfileScreen(key: ValueKey('profile_$_profileRefreshKey'));
      default:
        return HomeScreen(key: ValueKey('home_$_homeRefreshKey'));
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;

      // Saat balik ke Home, HomeScreen dibuat ulang supaya foto profil terbaru kebaca
      if (index == 0) {
        _homeRefreshKey++;
      }

      // Saat buka Profil lagi, Profil juga refresh
      if (index == 4) {
        _profileRefreshKey++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getCurrentScreen(),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          border: Border(
            top: BorderSide(color: AppColors.primaryLighter, width: 1.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x149F86C0),
              blurRadius: 12,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.pets_outlined),
              activeIcon: Icon(Icons.pets),
              label: 'Hewan',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.primary],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x409F86C0),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.chat_bubble_outline,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              label: 'AI Chat',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.notifications_outlined),
              activeIcon: Icon(Icons.notifications),
              label: 'Pengingat',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}