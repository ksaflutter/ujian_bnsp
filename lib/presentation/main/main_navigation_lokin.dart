import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors_lokin.dart';
import '../history/history_screen_lokin.dart';
import '../home/home_screen_lokin.dart';
import '../permission/permission_screen_lokin.dart';
import '../profile/profile_screen_lokin.dart';

class MainNavigation extends StatefulWidget {
  final int initialIndex;

  const MainNavigation({super.key, this.initialIndex = 0});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation>
    with TickerProviderStateMixin {
  late int _currentIndex;
  late PageController _pageController;
  late List<AnimationController> _iconControllers;
  late List<Animation<double>> _iconAnimations;

  final List<Widget> _screens = [
    const HomeScreen(),
    const HistoryScreen(),
    const PermissionScreen(),
    const ProfileScreen(),
  ];

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Home',
    ),
    NavigationItem(
      icon: Icons.history_outlined,
      activeIcon: Icons.history,
      label: 'Riwayat',
    ),
    NavigationItem(
      icon: Icons.assignment_outlined,
      activeIcon: Icons.assignment,
      label: 'Izin',
    ),
    NavigationItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profil',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);

    // Initialize animation controllers with fixed durations
    _iconControllers = List.generate(
      _navigationItems.length,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 200),
        vsync: this,
      ),
    );

    _iconAnimations = _iconControllers
        .map((controller) => Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(parent: controller, curve: Curves.easeInOut),
            ))
        .toList();

    // Set initial selected animation
    _iconControllers[_currentIndex].value = 1.0;
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (var controller in _iconControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_currentIndex != index && mounted) {
      // Reset previous animation
      _iconControllers[_currentIndex].reverse();

      setState(() {
        _currentIndex = index;
      });

      // Animate new selection
      _iconControllers[index].forward();

      // Add haptic feedback
      HapticFeedback.lightImpact();

      // Animate to page with error handling
      try {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } catch (e) {
        // Fallback to jump if animate fails
        _pageController.jumpToPage(index);
      }
    }
  }

  void _onPageChanged(int index) {
    if (mounted && _currentIndex != index) {
      // Reset previous animation
      _iconControllers[_currentIndex].reverse();

      setState(() {
        _currentIndex = index;
      });

      // Animate new selection
      _iconControllers[index].forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const ClampingScrollPhysics(), // Better scrolling physics
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            height: 70, // Fixed height to prevent overflow
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _navigationItems.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isSelected = _currentIndex == index;

                return Expanded(
                  child: GestureDetector(
                    onTap: () => _onItemTapped(index),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      height: 54, // Fixed height for consistency
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColorsLokin.primary.withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Fixed icon size to prevent scaling issues
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Icon(
                              isSelected ? item.activeIcon : item.icon,
                              size: 24, // Fixed size
                              color: isSelected
                                  ? AppColorsLokin.primary
                                  : AppColorsLokin.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Fixed text size and overflow handling
                          SizedBox(
                            height: 14,
                            child: Text(
                              item.label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: isSelected
                                    ? AppColorsLokin.primary
                                    : AppColorsLokin.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

// Global navigation helper
class NavigationHelper {
  static void navigateToTab(BuildContext context, int index) {
    final mainNavigation =
        context.findAncestorStateOfType<_MainNavigationState>();
    if (mainNavigation != null) {
      mainNavigation._onItemTapped(index);
    }
  }

  static void navigateToHome(BuildContext context) {
    navigateToTab(context, 0);
  }

  static void navigateToHistory(BuildContext context) {
    navigateToTab(context, 1);
  }

  static void navigateToPermission(BuildContext context) {
    navigateToTab(context, 2);
  }

  static void navigateToProfile(BuildContext context) {
    navigateToTab(context, 3);
  }
}
