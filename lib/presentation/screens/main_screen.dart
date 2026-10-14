import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../services/notification_service.dart';
import 'home/home_screen.dart';
import 'news/news_screen.dart';
import 'fixtures/fixtures_screen.dart';
import 'favourites/favourites_screen.dart';
import 'more/more_screen.dart';

final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  DateTime? _lastBackPressTime;

  @override
  void initState() {
    super.initState();
    // Process any deep link if launched via notification tap
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService().checkPendingPayload();
    });
  }

  void _handleBackPress() {
    final currentIndex = ref.read(bottomNavIndexProvider);

    // 1. If on any secondary tab (News, Fixtures, My Teams, More), return to Scores (Tab 0)
    if (currentIndex != 0) {
      ref.read(bottomNavIndexProvider.notifier).state = 0;
      return;
    }

    // 2. If already on Scores tab, require double press within 2 seconds to exit
    final now = DateTime.now();
    if (_lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.touch_app, color: AppColors.primary, size: 18),
              SizedBox(width: 8),
              Text(
                'Press back again to exit LiveScore',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: AppColors.secondary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    // Double-press confirmed: smoothly exit to home screen
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(bottomNavIndexProvider);

    final screens = [
      const HomeScreen(),
      const NewsScreen(),
      const FixturesScreen(),
      const FavouritesScreen(),
      const MoreScreen(),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackPress();
      },
      child: Scaffold(
        body: IndexedStack(
          index: currentIndex,
          children: screens,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) => ref.read(bottomNavIndexProvider.notifier).state = index,
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.secondary,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.sports_soccer), label: 'Scores'),
            BottomNavigationBarItem(icon: Icon(Icons.newspaper), label: 'News'),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Fixtures'),
            BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'My Teams'),
            BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'More'),
          ],
        ),
      ),
    );
  }
}
