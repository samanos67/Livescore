import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/team_info.dart';
import '../../domain/entities/player.dart';
import '../../domain/entities/fixture.dart';
import '../../domain/entities/news_article.dart';
import '../../domain/entities/video_highlight.dart';
import '../providers/fixture_provider.dart';

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

// ─── Team News ────────────────────────────────────────────────────────────────

final teamNewsProvider =
    FutureProvider.family<List<NewsArticle>, String>((ref, teamName) async {
  final api   = ref.read(footballApiServiceProvider);
  final items = await api.getTeamNews(teamName);
  return _mapNews(items);
});

// ─── General Football News (home screen) ─────────────────────────────────────

final generalNewsProvider =
    FutureProvider<List<NewsArticle>>((ref) async {
  final api   = ref.read(footballApiServiceProvider);
  final items = await api.getGeneralNews(limit: 20);
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
