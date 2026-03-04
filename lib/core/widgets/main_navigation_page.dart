import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';

import '../../features/booking/presentation/pages/booking_list_page.dart';
import '../../features/home/pages/home_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../theme/app_colors.dart';

class MainNavigationPage extends StatelessWidget {
  const MainNavigationPage({super.key});

  List<Widget> _buildScreens() {
    return const [HomePage(), BookingListPage(), ProfilePage()];
  }

  List<PersistentBottomNavBarItem> _navBarsItems() {
    return [
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.home),
        title: 'Home',
        activeColorPrimary: AppColors.primary,
        inactiveColorPrimary: AppColors.textTertiary,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.book_online),
        title: 'Booking',
        activeColorPrimary: AppColors.primary,
        inactiveColorPrimary: AppColors.textTertiary,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.person),
        title: 'Akun Saya',
        activeColorPrimary: AppColors.primary,
        inactiveColorPrimary: AppColors.textTertiary,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return PersistentTabView(
      context,
      screens: _buildScreens(),
      items: _navBarsItems(),
      navBarStyle: NavBarStyle.style3,
      backgroundColor: Colors.white,
      decoration: NavBarDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      isVisible: true,
      confineToSafeArea: true,
      handleAndroidBackButtonPress: true,
      resizeToAvoidBottomInset: true,
      stateManagement: true,
      popBehaviorOnSelectedNavBarItemPress: PopBehavior.all,
    );
  }
}
