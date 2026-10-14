import 'package:flutter/material.dart';
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
  @override
  void initState() {
    super.initState();
    // Process any deep link if launched via notification tap
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService().checkPendingPayload();
    });
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

    return Scaffold(
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
    );
  }
}
