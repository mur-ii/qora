import 'package:flutter/material.dart';

import '../../features/booking/presentation/pages/booking_list_page.dart';
import '../../features/home/pages/home_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../theme/app_colors.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;

  List<Widget> _buildScreens() {
    return const [
      RepaintBoundary(child: HomePage()),
      RepaintBoundary(child: BookingListPage()),
      RepaintBoundary(child: ProfilePage()),
    ];
  }

  List<BottomNavigationBarItem> _navBarItems() {
    return [
      const BottomNavigationBarItem(
        icon: Icon(Icons.home),
        activeIcon: Icon(Icons.home_filled),
        label: 'Home',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.book_online),
        activeIcon: Icon(Icons.book_online_outlined),
        label: 'Booking',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person),
        activeIcon: Icon(Icons.person_rounded),
        label: 'Akun Saya',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final screens = _buildScreens();

    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: List.generate(
            screens.length,
            (index) => TickerMode(
              enabled: index == _currentIndex,
              child: screens[index],
            ),
          ),
        ),
        bottomNavigationBar: RepaintBoundary(
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              if (_currentIndex == index) return;
              setState(() => _currentIndex = index);
            },
            items: _navBarItems(),
            type: BottomNavigationBarType.fixed,
            backgroundColor: AppColors.surfaceWhite,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.textTertiary,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
            showUnselectedLabels: true,
            elevation: 0,
          ),
        ),
      ),
    );
  }
}
