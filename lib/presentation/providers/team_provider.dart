import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/team_info.dart';
import '../../domain/entities/player.dart';
import '../../domain/entities/fixture.dart';
import '../../domain/entities/news_article.dart';
import '../../domain/entities/video_highlight.dart';
import '../providers/fixture_provider.dart';
import 'favorites_provider.dart';

// ─── Team Info ────────────────────────────────────────────────────────────────

final teamInfoProvider =
    FutureProvider.family<TeamInfo?, int>((ref, teamId) async {
  final api  = ref.read(footballApiServiceProvider);
  final data = await api.getTeamInfo(teamId);
  if (data == null) return null;

  return TeamInfo(
    id:              teamId,
    name:            data['name']?.toString() ?? '',
    shortName:       data['shortName']?.toString() ?? '',
    logo:            data['logo']?.toString() ?? '',
    banner:          data['banner']?.toString() ?? '',
    jersey:          data['jersey']?.toString() ?? '',
    stadium:         data['stadium']?.toString() ?? '',
    stadiumCapacity: data['stadiumCapacity']?.toString() ?? '',
    stadiumLocation: data['stadiumLocation']?.toString() ?? '',
    stadiumImage:    data['stadiumImage']?.toString() ?? '',
    city:            data['city']?.toString() ?? '',
    country:         data['country']?.toString() ?? '',
    founded:         data['founded']?.toString() ?? '',
    manager:         data['manager']?.toString() ?? '',
    description:     data['description']?.toString() ?? '',
    website:         data['website']?.toString() ?? '',
    twitter:         data['twitter']?.toString() ?? '',
    instagram:       data['instagram']?.toString() ?? '',
    youtube:         data['youtube']?.toString() ?? '',
    colours:         List<String>.from(data['colours'] ?? []),
  );
});

// ─── Team Squad ───────────────────────────────────────────────────────────────

final teamSquadProvider =
    FutureProvider.family<List<Player>, int>((ref, teamId) async {
  final api   = ref.read(footballApiServiceProvider);
  final items = await api.getTeamSquad(teamId);
  return items.map((p) => Player(
    id:          (p['id'] as num?)?.toInt() ?? 0,
    name:        p['name']?.toString() ?? '',
    photo:       p['photo']?.toString() ?? '',
    position:    p['position']?.toString() ?? '',
    nationality: p['nationality']?.toString() ?? '',
    birthDate:   p['birthDate']?.toString() ?? '',
    number:      p['number']?.toString() ?? '',
    height:      p['height']?.toString() ?? '',
    weight:      p['weight']?.toString() ?? '',
    description: p['description']?.toString() ?? '',
  )).toList();
});

// ─── Team Season Fixtures ─────────────────────────────────────────────────────

final teamFixturesProvider =
    FutureProvider.family<List<Fixture>, int>((ref, teamId) async {
  final api   = ref.read(footballApiServiceProvider);
  final items = await api.getTeamFixtures(teamId);
  return items; // FixtureModel extends Fixture
});

// ─── Team Season Stats ────────────────────────────────────────────────────────

final teamStatsProvider =
    FutureProvider.family<Map<String, dynamic>?, int>((ref, teamId) async {
  final api = ref.read(footballApiServiceProvider);
  return await api.getTeamStats(teamId);
});

// ─── Team News ────────────────────────────────────────────────────────────────

final teamNewsProvider =
    FutureProvider.family<List<NewsArticle>, String>((ref, teamName) async {
  final api   = ref.read(footballApiServiceProvider);
  final items = await api.getTeamNews(teamName);
  return _mapNews(items);
});

// ─── General Football News (world headlines) ─────────────────────────────────

final generalNewsProvider =
    FutureProvider<List<NewsArticle>>((ref) async {
  final api   = ref.read(footballApiServiceProvider);
  final items = await api.getGeneralNews(limit: 30);
  return _mapNews(items);
});

// ─── Favorite Teams News ──────────────────────────────────────────────────────

const Map<int, String> _topClubNames = {
  57: 'Arsenal',
  65: 'Manchester City',
  64: 'Liverpool',
  61: 'Chelsea',
  66: 'Manchester United',
  73: 'Tottenham',
  58: 'Aston Villa',
  67: 'Newcastle',
  563: 'West Ham',
  397: 'Brighton',
  62: 'Everton',
  86: 'Real Madrid',
  81: 'Barcelona',
  78: 'Atletico Madrid',
  559: 'Sevilla',
  77: 'Athletic Club',
  92: 'Real Sociedad',
  90: 'Real Betis',
  109: 'Juventus',
  108: 'Inter',
  98: 'AC Milan',
  113: 'Napoli',
  100: 'Roma',
  110: 'Lazio',
  102: 'Atalanta',
  5: 'Bayern Munich',
  4: 'Dortmund',
  3: 'Leverkusen',
  721: 'RB Leipzig',
  18: 'Stuttgart',
  524: 'PSG',
  516: 'Marseille',
  548: 'Monaco',
  523: 'Lyon',
  521: 'Lille',
  678: 'Ajax',
  1903: 'Benfica',
  503: 'Porto',
  498: 'Sporting',
  732: 'Celtic',
};

final favoriteTeamsNewsProvider = FutureProvider<List<NewsArticle>>((ref) async {
  final favIds = ref.watch(favoritesProvider);
  if (favIds.isEmpty) return [];

  final api = ref.read(footballApiServiceProvider);
  final List<String> names = [];

  for (final id in favIds) {
    if (_topClubNames.containsKey(id)) {
      names.add(_topClubNames[id]!);
    } else {
      final info = await api.getTeamInfo(id);
      if (info != null && (info['name'] as String?)?.isNotEmpty == true) {
        names.add(info['name'] as String);
      }
    }
  }

  if (names.isEmpty) return [];
  final items = await api.getTeamNews(names.join(','), limit: 25);
  return _mapNews(items);
});

// ─── Transfers & Rumours News ────────────────────────────────────────────────

final transferNewsProvider = FutureProvider<List<NewsArticle>>((ref) async {
  final api = ref.read(footballApiServiceProvider);
  final items = await api.getTeamNews('transfer,signing,deal,contract', limit: 25);
  return _mapNews(items);
});

// ─── Team Highlights ──────────────────────────────────────────────────────────

final teamHighlightsProvider =
    FutureProvider.family<List<VideoHighlight>, String>((ref, teamName) async {
  final api   = ref.read(footballApiServiceProvider);
  final items = await api.getTeamHighlights(teamName);
  return items.map((v) => VideoHighlight(
    videoId:     v['videoId']?.toString() ?? '',
    title:       v['title']?.toString() ?? '',
    thumbnail:   v['thumbnail']?.toString() ?? '',
    channel:     v['channel']?.toString() ?? '',
    publishedAt: v['publishedAt']?.toString() ?? '',
    url:         v['url']?.toString() ?? '',
  )).toList();
});

// ─── Helper ───────────────────────────────────────────────────────────────────

List<NewsArticle> _mapNews(List<Map<String, dynamic>> items) {
  return items.map((n) => NewsArticle(
    title:       n['title']?.toString() ?? '',
    description: n['description']?.toString() ?? '',
    url:         n['url']?.toString() ?? '',
    image:       n['image']?.toString() ?? '',
    source:      n['source']?.toString() ?? '',
    publishedAt: n['publishedAt']?.toString() ?? '',
  )).toList();
}
