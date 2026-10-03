import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import 'home/home_screen.dart';
import 'fixtures/fixtures_screen.dart';
import 'leagues/leagues_screen.dart';
import 'live_tv/live_tv_screen.dart';
import 'more/more_screen.dart';

final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(bottomNavIndexProvider);

    final screens = [
      const HomeScreen(),
      const FixturesScreen(),
      const LeaguesScreen(),
      const LiveTvScreen(),
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
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Fixtures'),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: 'Leagues'),
          BottomNavigationBarItem(icon: Icon(Icons.live_tv), label: 'Live TV'),
          BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'More'),
        ],
      ),
    );
  }
}
