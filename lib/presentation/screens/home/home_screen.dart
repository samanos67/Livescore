import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/fixture_provider.dart';
import '../../widgets/match_card.dart';
import '../../../core/constants/app_colors.dart';
import '../../widgets/banner_ad_widget.dart';
import '../../../domain/entities/fixture.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  int _selectedDateIndex = 3; // Today is at index 3
  late final DateTime _baseDate;
  bool _showLiveOnly = false;

  @override
  bool get wantKeepAlive => true; // Keep state when switching tabs

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _baseDate = DateTime(now.year, now.month, now.day);
  }

  DateTime _getDateForIndex(int index) => _baseDate.add(Duration(days: index - 3));
  DateTime get _selectedDate => _getDateForIndex(_selectedDateIndex);
  String get _selectedDateString => DateFormat('yyyy-MM-dd').format(_selectedDate);

  void _refresh() {
    ref.read(liveFixturesProvider.notifier).fetchLiveFixtures();
    ref.invalidate(fixturesByDateProvider(_selectedDateString));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final liveAsync = ref.watch(liveFixturesProvider);
    final fixturesAsync = ref.watch(fixturesByDateProvider(_selectedDateString));

    final liveCount = liveAsync.value?.length ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/app_logo.png',
                width: 30,
                height: 30,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'LiveScore',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: Column(
        children: [
          const BannerAdWidget(),
          _buildFilterAndDateBar(liveCount),
          Expanded(
            child: _showLiveOnly
                ? _buildLiveSection(liveAsync)
                : _buildDateSection(fixturesAsync, liveAsync),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterAndDateBar(int liveCount) {
    return Column(
      children: [
        // Mode toggle: All vs Live
        Container(
          color: AppColors.secondary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (_showLiveOnly) {
                      setState(() => _showLiveOnly = false);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: !_showLiveOnly ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'All Matches',
                      style: TextStyle(
                        color: !_showLiveOnly ? Colors.black : Colors.white70,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (!_showLiveOnly) {
                      setState(() => _showLiveOnly = true);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _showLiveOnly ? Colors.redAccent : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _showLiveOnly ? Colors.redAccent : Colors.grey.withOpacity(0.3),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _showLiveOnly ? Colors.white : Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          liveCount > 0 ? 'Live ($liveCount)' : 'Live',
                          style: TextStyle(
                            color: _showLiveOnly ? Colors.white : Colors.white70,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Date selector (shown only in All Matches mode)
        if (!_showLiveOnly) _buildDateSelector(),
      ],
    );
  }

  Widget _buildDateSelector() {
    return Container(
      height: 60,
      color: AppColors.secondary,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 10,
        itemBuilder: (context, index) {
          final date = _getDateForIndex(index);
          final isSelected = index == _selectedDateIndex;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDateIndex = index;
              });
            },
            child: Container(
              width: 60,
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.grey.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E').format(date),
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    DateFormat('d').format(date),
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLiveSection(AsyncValue<List<Fixture>> liveAsync) {
    return liveAsync.when(
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
                  const Text(
                    'No live matches at the moment',
                    style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => setState(() => _showLiveOnly = false),
                    child: const Text('View All Matches'),
                  ),
                ],
              ),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.read(liveFixturesProvider.notifier).fetchLiveFixtures(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: fixtures.length,
            itemBuilder: (context, index) {
              return Column(
                children: [
                  MatchCard(fixture: fixtures[index]),
                  if ((index + 1) % 5 == 0 && index != fixtures.length - 1)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: BannerAdWidget(),
                    ),
                ],
              );
            },
          ),
        );
      },
      error: (err, stack) => _buildErrorState(err.toString(), () {
        ref.read(liveFixturesProvider.notifier).fetchLiveFixtures();
      }),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildDateSection(
    AsyncValue<List<Fixture>> fixturesAsync,
    AsyncValue<List<Fixture>> liveAsync,
  ) {
    return fixturesAsync.when(
      data: (fixtures) {
        final isToday = _selectedDateIndex == 3;
        final liveMatches = isToday ? (liveAsync.value ?? []) : <Fixture>[];

        if (fixtures.isEmpty && liveMatches.isEmpty) {
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
                    'No matches scheduled for ${DateFormat('MMM d').format(_selectedDate)}',
                    style: const TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _refresh,
                    child: const Text('Refresh'),
                  ),
                ],
              ),
            ),
          );
        }

        // Combine live matches at top if today
        final List<Widget> listItems = [];

        if (liveMatches.isNotEmpty) {
          listItems.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'LIVE MATCHES NOW',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          );

          for (var liveFixture in liveMatches) {
            listItems.add(MatchCard(fixture: liveFixture));
          }

          if (fixtures.isNotEmpty) {
            listItems.add(
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(),
              ),
            );
          }
        }

        for (int i = 0; i < fixtures.length; i++) {
          listItems.add(MatchCard(fixture: fixtures[i]));
          if ((i + 1) % 5 == 0 && i != fixtures.length - 1) {
            listItems.add(
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: BannerAdWidget(),
              ),
            );
          }
        }

        return RefreshIndicator(
          onRefresh: () async => _refresh(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: listItems,
          ),
        );
      },
      error: (err, stack) => _buildErrorState(err.toString(), _refresh),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorState(String message, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Could not load matches: $message',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
