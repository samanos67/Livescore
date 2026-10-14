import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/favorites_provider.dart';
import '../../../data/datasources/local/favorites_service.dart';
import '../../../services/notification_service.dart';
import '../main_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  final bool isInitialLaunch;

  const OnboardingScreen({super.key, this.isInitialLaunch = true});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final Set<int> _selectedIds = {};
  String _selectedLeague = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  DateTime? _lastBackPressTime;

  void _handleBackPress() {
    if (!widget.isInitialLaunch) {
      Navigator.pop(context);
      return;
    }

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

    SystemNavigator.pop();
  }

  static const List<Map<String, dynamic>> _topClubs = [
    // Premier League
    {'id': 57, 'name': 'Arsenal', 'logo': 'https://crests.football-data.org/57.png', 'league': 'Premier League'},
    {'id': 65, 'name': 'Manchester City', 'logo': 'https://crests.football-data.org/65.png', 'league': 'Premier League'},
    {'id': 64, 'name': 'Liverpool', 'logo': 'https://crests.football-data.org/64.png', 'league': 'Premier League'},
    {'id': 61, 'name': 'Chelsea', 'logo': 'https://crests.football-data.org/61.png', 'league': 'Premier League'},
    {'id': 66, 'name': 'Manchester United', 'logo': 'https://crests.football-data.org/66.png', 'league': 'Premier League'},
    {'id': 73, 'name': 'Tottenham Hotspur', 'logo': 'https://crests.football-data.org/73.png', 'league': 'Premier League'},
    {'id': 58, 'name': 'Aston Villa', 'logo': 'https://crests.football-data.org/58.png', 'league': 'Premier League'},
    {'id': 67, 'name': 'Newcastle United', 'logo': 'https://crests.football-data.org/67.png', 'league': 'Premier League'},
    {'id': 563, 'name': 'West Ham United', 'logo': 'https://crests.football-data.org/563.png', 'league': 'Premier League'},
    {'id': 397, 'name': 'Brighton', 'logo': 'https://crests.football-data.org/397.png', 'league': 'Premier League'},
    {'id': 62, 'name': 'Everton', 'logo': 'https://crests.football-data.org/62.png', 'league': 'Premier League'},

    // La Liga
    {'id': 86, 'name': 'Real Madrid', 'logo': 'https://crests.football-data.org/86.png', 'league': 'La Liga'},
    {'id': 81, 'name': 'FC Barcelona', 'logo': 'https://crests.football-data.org/81.png', 'league': 'La Liga'},
    {'id': 78, 'name': 'Atletico Madrid', 'logo': 'https://crests.football-data.org/78.png', 'league': 'La Liga'},
    {'id': 559, 'name': 'Sevilla', 'logo': 'https://crests.football-data.org/559.png', 'league': 'La Liga'},
    {'id': 77, 'name': 'Athletic Club', 'logo': 'https://crests.football-data.org/77.png', 'league': 'La Liga'},
    {'id': 92, 'name': 'Real Sociedad', 'logo': 'https://crests.football-data.org/92.png', 'league': 'La Liga'},
    {'id': 90, 'name': 'Real Betis', 'logo': 'https://crests.football-data.org/90.png', 'league': 'La Liga'},

    // Serie A
    {'id': 109, 'name': 'Juventus', 'logo': 'https://crests.football-data.org/109.png', 'league': 'Serie A'},
    {'id': 108, 'name': 'Inter Milan', 'logo': 'https://crests.football-data.org/108.png', 'league': 'Serie A'},
    {'id': 98, 'name': 'AC Milan', 'logo': 'https://crests.football-data.org/98.png', 'league': 'Serie A'},
    {'id': 113, 'name': 'Napoli', 'logo': 'https://crests.football-data.org/113.png', 'league': 'Serie A'},
    {'id': 100, 'name': 'AS Roma', 'logo': 'https://crests.football-data.org/100.png', 'league': 'Serie A'},
    {'id': 110, 'name': 'Lazio', 'logo': 'https://crests.football-data.org/110.png', 'league': 'Serie A'},
    {'id': 102, 'name': 'Atalanta', 'logo': 'https://crests.football-data.org/102.png', 'league': 'Serie A'},

    // Bundesliga
    {'id': 5, 'name': 'Bayern Munich', 'logo': 'https://crests.football-data.org/5.png', 'league': 'Bundesliga'},
    {'id': 4, 'name': 'Borussia Dortmund', 'logo': 'https://crests.football-data.org/4.png', 'league': 'Bundesliga'},
    {'id': 3, 'name': 'Bayer Leverkusen', 'logo': 'https://crests.football-data.org/3.png', 'league': 'Bundesliga'},
    {'id': 721, 'name': 'RB Leipzig', 'logo': 'https://crests.football-data.org/721.png', 'league': 'Bundesliga'},
    {'id': 18, 'name': 'VfB Stuttgart', 'logo': 'https://crests.football-data.org/18.png', 'league': 'Bundesliga'},

    // Ligue 1
    {'id': 524, 'name': 'Paris Saint-Germain', 'logo': 'https://crests.football-data.org/524.png', 'league': 'Ligue 1'},
    {'id': 516, 'name': 'Marseille', 'logo': 'https://crests.football-data.org/516.png', 'league': 'Ligue 1'},
    {'id': 548, 'name': 'Monaco', 'logo': 'https://crests.football-data.org/548.png', 'league': 'Ligue 1'},
    {'id': 523, 'name': 'Lyon', 'logo': 'https://crests.football-data.org/523.png', 'league': 'Ligue 1'},
    {'id': 521, 'name': 'Lille', 'logo': 'https://crests.football-data.org/521.png', 'league': 'Ligue 1'},

    // European Giants
    {'id': 678, 'name': 'Ajax', 'logo': 'https://crests.football-data.org/678.png', 'league': 'European Giants'},
    {'id': 1903, 'name': 'Benfica', 'logo': 'https://crests.football-data.org/1903.png', 'league': 'European Giants'},
    {'id': 503, 'name': 'FC Porto', 'logo': 'https://crests.football-data.org/503.png', 'league': 'European Giants'},
    {'id': 498, 'name': 'Sporting CP', 'logo': 'https://crests.football-data.org/498.png', 'league': 'European Giants'},
    {'id': 732, 'name': 'Celtic', 'logo': 'https://crests.football-data.org/732.png', 'league': 'European Giants'},
  ];

  static const List<String> _leagues = [
    'All',
    'Premier League',
    'La Liga',
    'Serie A',
    'Bundesliga',
    'Ligue 1',
    'European Giants',
  ];

  @override
  void initState() {
    super.initState();
    final existing = ref.read(favoritesProvider);
    _selectedIds.addAll(existing);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleTeam(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _finishOnboarding({bool allowEmpty = false}) async {
    if (_selectedIds.isEmpty && !allowEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least 1 club to follow for live scores & news!'),
          backgroundColor: AppColors.secondary,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Save exact user selections
    await ref.read(favoritesProvider.notifier).setFavorites(_selectedIds.toList());
    await FavoritesService().setCompletedOnboarding(true);

    // Register notification topics for selected clubs
    final notif = NotificationService();
    for (final id in _selectedIds) {
      await notif.subscribeToTopic('team_$id');
    }

    if (!mounted) return;

    if (widget.isInitialLaunch) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredClubs = _topClubs.where((c) {
      final matchesLeague = _selectedLeague == 'All' || c['league'] == _selectedLeague;
      final name = (c['name'] as String).toLowerCase();
      final matchesSearch = _searchQuery.isEmpty || name.contains(_searchQuery.toLowerCase());
      return matchesLeague && matchesSearch;
    }).toList();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackPress();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: !widget.isInitialLaunch,
        actions: [
          if (widget.isInitialLaunch)
            TextButton(
              onPressed: () => _finishOnboarding(allowEmpty: true),
              child: const Text(
                'Skip',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Column(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.35),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(27),
                      child: Image.asset(
                        'assets/images/app_logo.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Pick Your Favourite Clubs',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Select clubs to receive real-time goal notifications, kickoff reminders & breaking news.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Search Bar
                  Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(fontSize: 13, color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search club (e.g. Arsenal, Real Madrid, Bayern)...',
                        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                        prefixIcon: const Icon(Icons.search, size: 18, color: Colors.grey),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 16, color: Colors.grey),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onChanged: (val) {
                        setState(() => _searchQuery = val.trim());
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ── League Filter Chips ──────────────────────────────────────────
            SizedBox(
              height: 38,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _leagues.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final league = _leagues[i];
                  final isSelected = _selectedLeague == league;
                  return ChoiceChip(
                    label: Text(league),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.secondary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.black : Colors.white70,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 11,
                    ),
                    onSelected: (_) {
                      setState(() => _selectedLeague = league);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            // ── Teams Grid ───────────────────────────────────────────────────
            Expanded(
              child: filteredClubs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.sports_soccer, size: 48, color: Colors.grey.shade600),
                          const SizedBox(height: 8),
                          Text(
                            'No clubs found matching "$_searchQuery"',
                            style: const TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.88,
                      ),
                      itemCount: filteredClubs.length,
                      itemBuilder: (context, index) {
                        final club = filteredClubs[index];
                        final id = club['id'] as int;
                        final name = club['name'] as String;
                        final logo = club['logo'] as String;
                        final isSelected = _selectedIds.contains(id);

                        return GestureDetector(
                          onTap: () => _toggleTeam(id),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary.withOpacity(0.18)
                                  : AppColors.cardBackground,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : Colors.white10,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            padding: const EdgeInsets.all(8),
                            child: Stack(
                              children: [
                                Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CachedNetworkImage(
                                        imageUrl: logo,
                                        width: 44,
                                        height: 44,
                                        placeholder: (_, __) => const CircleAvatar(
                                          backgroundColor: Colors.white10,
                                          radius: 22,
                                        ),
                                        errorWidget: (_, __, ___) => const Icon(
                                          Icons.shield,
                                          size: 44,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        name,
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.w600,
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: AnimatedOpacity(
                                    opacity: isSelected ? 1.0 : 0.0,
                                    duration: const Duration(milliseconds: 150),
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        size: 13,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // ── Bottom Action Button ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.secondary,
                border: Border(top: BorderSide(color: Colors.white10)),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 2,
                  ),
                  onPressed: () => _finishOnboarding(),
                  child: Text(
                    _selectedIds.isEmpty
                        ? 'SELECT CLUBS TO CONTINUE'
                        : 'CONTINUE TO APP (${_selectedIds.length} CLUBS)',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  }
}
