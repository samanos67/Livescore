import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/favorites_provider.dart';
import '../../../data/datasources/local/favorites_service.dart';
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
    // La Liga
    {'id': 86, 'name': 'Real Madrid', 'logo': 'https://crests.football-data.org/86.png', 'league': 'La Liga'},
    {'id': 81, 'name': 'FC Barcelona', 'logo': 'https://crests.football-data.org/81.png', 'league': 'La Liga'},
    {'id': 78, 'name': 'Atletico Madrid', 'logo': 'https://crests.football-data.org/78.png', 'league': 'La Liga'},
    // Serie A
    {'id': 109, 'name': 'Juventus', 'logo': 'https://crests.football-data.org/109.png', 'league': 'Serie A'},
    {'id': 108, 'name': 'Inter Milan', 'logo': 'https://crests.football-data.org/108.png', 'league': 'Serie A'},
    {'id': 98, 'name': 'AC Milan', 'logo': 'https://crests.football-data.org/98.png', 'league': 'Serie A'},
    {'id': 113, 'name': 'Napoli', 'logo': 'https://crests.football-data.org/113.png', 'league': 'Serie A'},
    {'id': 100, 'name': 'AS Roma', 'logo': 'https://crests.football-data.org/100.png', 'league': 'Serie A'},
    // Bundesliga
    {'id': 5, 'name': 'Bayern Munich', 'logo': 'https://crests.football-data.org/5.png', 'league': 'Bundesliga'},
    {'id': 4, 'name': 'Borussia Dortmund', 'logo': 'https://crests.football-data.org/4.png', 'league': 'Bundesliga'},
    {'id': 3, 'name': 'Bayer Leverkusen', 'logo': 'https://crests.football-data.org/3.png', 'league': 'Bundesliga'},
    // Ligue 1
    {'id': 524, 'name': 'Paris Saint-Germain', 'logo': 'https://crests.football-data.org/524.png', 'league': 'Ligue 1'},
    {'id': 516, 'name': 'Marseille', 'logo': 'https://crests.football-data.org/516.png', 'league': 'Ligue 1'},
    {'id': 548, 'name': 'Monaco', 'logo': 'https://crests.football-data.org/548.png', 'league': 'Ligue 1'},
  ];

  static const List<String> _leagues = [
    'All',
    'Premier League',
    'La Liga',
    'Serie A',
    'Bundesliga',
    'Ligue 1',
  ];

  @override
  void initState() {
    super.initState();
    final existing = ref.read(favoritesProvider);
    _selectedIds.addAll(existing);
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

  Future<void> _finishOnboarding() async {
    if (_selectedIds.isNotEmpty) {
      await ref.read(favoritesProvider.notifier).addMultiple(_selectedIds.toList());
    }
    await FavoritesService().setCompletedOnboarding(true);

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
    final filteredClubs = _selectedLeague == 'All'
        ? _topClubs
        : _topClubs.where((c) => c['league'] == _selectedLeague).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: !widget.isInitialLaunch,
        actions: [
          if (widget.isInitialLaunch)
            TextButton(
              onPressed: _finishOnboarding,
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.35),
                          blurRadius: 18,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: Image.asset(
                        'assets/images/app_logo.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Pick Your Teams',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Select your favourite European clubs to personalize your live feed and match alerts.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            // ── League Filter Chips ──────────────────────────────────────────
            SizedBox(
              height: 44,
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
                      fontSize: 12,
                    ),
                    onSelected: (_) {
                      setState(() => _selectedLeague = league);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // ── Teams Grid ───────────────────────────────────────────────────
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.85,
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
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withOpacity(0.15)
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
                                const SizedBox(height: 8),
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
                                  size: 14,
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
                  onPressed: _finishOnboarding,
                  child: Text(
                    _selectedIds.isEmpty
                        ? 'CONTINUE'
                        : 'FOLLOW (${_selectedIds.length}) TEAMS',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
