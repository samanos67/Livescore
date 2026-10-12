import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/fixture.dart';
import '../../providers/fixture_provider.dart';
import '../../widgets/match_card.dart';
import '../../widgets/banner_ad_widget.dart';

class FixturesScreen extends ConsumerStatefulWidget {
  const FixturesScreen({super.key});

  @override
  ConsumerState<FixturesScreen> createState() => _FixturesScreenState();
}

class _FixturesScreenState extends ConsumerState<FixturesScreen>
    with AutomaticKeepAliveClientMixin {
  late DateTime _selectedDate;

  @override
  bool get wantKeepAlive => true; // Keep state when navigating away

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  String get _selectedDateString => DateFormat('yyyy-MM-dd').format(_selectedDate);

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020), // Allow viewing far back
      lastDate: DateTime(2030), // Allow viewing far ahead
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.secondary,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = DateTime(picked.year, picked.month, picked.day);
      });
      ref.invalidate(fixturesByDateProvider(_selectedDateString));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final fixturesAsync = ref.watch(fixturesByDateProvider(_selectedDateString));

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/app_logo.png',
                width: 28,
                height: 28,
              ),
            ),
            const SizedBox(width: 10),
            const Text('Fixtures', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(fixturesByDateProvider(_selectedDateString));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const BannerAdWidget(),
          _buildDateHeader(),
          Expanded(
            child: fixturesAsync.when(
              data: (fixtures) {
                if (fixtures.isEmpty) {
                  return Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.asset(
                              'assets/images/no_matches.png',
                              width: 140,
                              height: 140,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No fixtures scheduled for ${DateFormat('EEE, MMM d, yyyy').format(_selectedDate)}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 12,
                            runSpacing: 10,
                            alignment: WrapAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                icon: const Icon(Icons.today, size: 18),
                                label: const Text('Jump to Today'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.black,
                                ),
                                onPressed: () {
                                  final now = DateTime.now();
                                  setState(() => _selectedDate = DateTime(now.year, now.month, now.day));
                                  ref.invalidate(fixturesByDateProvider(_selectedDateString));
                                },
                              ),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.calendar_month, size: 18),
                                label: const Text('Pick Date'),
                                onPressed: () => _selectDate(context),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }
                // Group fixtures by league
                final groupedFixtures = _groupFixturesByLeague(fixtures);
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(fixturesByDateProvider(_selectedDateString));
                  },
                  child: ListView.builder(
                    itemCount: groupedFixtures.length,
                    itemBuilder: (context, index) {
                      final entry = groupedFixtures.entries.elementAt(index);
                      final leagueName = entry.key;
                      final leagueFixtures = entry.value;
                      
                      return _buildLeagueSection(leagueName, leagueFixtures);
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: $err'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ref.invalidate(fixturesByDateProvider(_selectedDateString));
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, List<Fixture>> _groupFixturesByLeague(List<Fixture> fixtures) {
    final Map<String, List<Fixture>> grouped = {};
    
    // Define league priority for sorting
    final leaguePriority = {
      'Premier League (England)': 1,
      'UEFA Champions League': 2,
      'La Liga': 3,
      'Serie A': 4,
      'Bundesliga': 5,
      'Ligue 1': 6,
      'UEFA Europa League': 7,
      'Premier League (Scotland)': 20,
      'Premiership (Scotland)': 20,
    };
    
    for (var fixture in fixtures) {
      String leagueName = fixture.league.name;
      final country = fixture.league.country;
      
      // Differentiate Premier Leagues by country
      if (leagueName == 'Premier League' || leagueName == 'Premiership') {
        if (country == 'England') {
          leagueName = 'Premier League (England)';
        } else if (country == 'Scotland') {
          leagueName = 'Premiership (Scotland)';
        } else if (country.isNotEmpty) {
          leagueName = '$leagueName ($country)';
        }
      }
      
      if (!grouped.containsKey(leagueName)) {
        grouped[leagueName] = [];
      }
      grouped[leagueName]!.add(fixture);
    }
    
    // Sort leagues by priority
    final sortedEntries = grouped.entries.toList()
      ..sort((a, b) {
        final aPriority = leaguePriority[a.key] ?? 999;
        final bPriority = leaguePriority[b.key] ?? 999;
        return aPriority.compareTo(bPriority);
      });
    
    return Map.fromEntries(sortedEntries);
  }

  Widget _buildLeagueSection(String leagueName, List<Fixture> fixtures) {
    return ExpansionTile(
      initiallyExpanded: true,
      leading: const Icon(Icons.sports_soccer, color: AppColors.primary),
      title: Text(
        leagueName,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text('${fixtures.length} matches'),
      children: [
        ...fixtures.asMap().entries.map((entry) {
          final index = entry.key;
          final fixture = entry.value;
          
          return Column(
            children: [
              MatchCard(fixture: fixture),
              // Add ad every 5 fixtures
              if ((index + 1) % 5 == 0 && index != fixtures.length - 1)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: BannerAdWidget(),
                ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildDateHeader() {
    final isToday = DateUtils.isSameDay(_selectedDate, DateTime.now());
    final isTomorrow = DateUtils.isSameDay(
      _selectedDate,
      DateTime.now().add(const Duration(days: 1)),
    );
    final isYesterday = DateUtils.isSameDay(
      _selectedDate,
      DateTime.now().subtract(const Duration(days: 1)),
    );

    String dateLabel;
    if (isToday) {
      dateLabel = 'Today';
    } else if (isTomorrow) {
      dateLabel = 'Tomorrow';
    } else if (isYesterday) {
      dateLabel = 'Yesterday';
    } else {
      dateLabel = DateFormat('EEEE, MMM d').format(_selectedDate);
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: AppColors.secondary,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _selectedDate = _selectedDate.subtract(const Duration(days: 1));
              });
              ref.invalidate(fixturesByDateProvider(_selectedDateString));
            },
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _selectDate(context),
              child: Center(
                child: Text(
                  dateLabel,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                _selectedDate = _selectedDate.add(const Duration(days: 1));
              });
              ref.invalidate(fixturesByDateProvider(_selectedDateString));
            },
          ),
        ],
      ),
    );
  }
}
