import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../domain/entities/news_article.dart';
import '../domain/entities/fixture.dart';
import '../domain/entities/team.dart';
import '../domain/entities/league.dart';
import '../presentation/screens/common/in_app_article_screen.dart';
import '../presentation/screens/match_detail/match_detail_screen.dart';

/// Global notification service supporting:
/// 1. Instant Goal Alerts
/// 2. Match Kickoff Reminders (scheduled before match start)
/// 3. Favorite Team & Match Notifications
/// 4. Breaking Football News Alerts with Deep Linking
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// Global navigator key for deep linking when notifications are tapped
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  String? _pendingPayload;

  // Channels
  static const String _goalChannelId = 'live_goal_alerts';
  static const String _goalChannelName = 'Live Goal Alerts';
  static const String _goalChannelDesc = 'Instant notifications when goals are scored';

  static const String _kickoffChannelId = 'match_kickoff_alerts';
  static const String _kickoffChannelName = 'Match Kickoff Reminders';
  static const String _kickoffChannelDesc = 'Reminders 15 minutes before your matches kick off';

  static const String _newsChannelId = 'football_news_alerts';
  static const String _newsChannelName = 'Football News & Breaking Updates';
  static const String _newsChannelDesc = 'Breaking football news and updates about your favourite teams';

  /// Track active subscribed team / match topics
  final Set<String> _subscribedTopics = {};

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();

      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      );

      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification clicked with payload: ${response.payload}');
          handlePayload(response.payload);
        },
      );

      // Check if launched from a notification tap
      final launchDetails = await _notificationsPlugin.getNotificationAppLaunchDetails();
      if (launchDetails?.didNotificationLaunchApp ?? false) {
        _pendingPayload = launchDetails?.notificationResponse?.payload;
        debugPrint('App launched with pending notification payload: $_pendingPayload');
      }

      // Request permissions (Android 13+)
      await requestPermissions();

      _isInitialized = true;
      debugPrint('NotificationService initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize NotificationService: $e');
    }
  }

  /// Check and process any pending payload after UI mounts
  void checkPendingPayload() {
    if (_pendingPayload != null) {
      final payload = _pendingPayload;
      _pendingPayload = null;
      Future.delayed(const Duration(milliseconds: 600), () {
        handlePayload(payload);
      });
    }
  }

  /// Handle notification payload and deep link directly into the app
  static void handlePayload(String? payload) {
    if (payload == null || payload.isEmpty) return;
    debugPrint('Executing deep link for payload: $payload');

    final navState = navigatorKey.currentState;
    if (navState == null) {
      debugPrint('Navigator state not ready yet for deep link');
      return;
    }

    if (payload.startsWith('news|')) {
      final parts = payload.split('|');
      if (parts.length >= 4) {
        final url = parts[1];
        final title = parts[2];
        final source = parts[3];
        navState.push(
          MaterialPageRoute(
            builder: (_) => InAppArticleScreen(
              article: NewsArticle(
                title: title,
                description: '',
                url: url,
                image: '',
                source: source,
                publishedAt: DateTime.now().toIso8601String(),
              ),
            ),
          ),
        );
      }
    } else if (payload.startsWith('match_') || payload.startsWith('match|')) {
      final parts = payload.contains('|') ? payload.split('|') : [payload];
      final id = parts.length > 1
          ? (int.tryParse(parts[1]) ?? 0)
          : (int.tryParse(payload.replaceFirst('match_', '')) ?? 0);
      final home = parts.length > 2 ? parts[2] : 'Home';
      final away = parts.length > 3 ? parts[3] : 'Away';
      final homeScore = parts.length > 4 ? int.tryParse(parts[4]) : null;
      final awayScore = parts.length > 5 ? int.tryParse(parts[5]) : null;
      final status = parts.length > 6 ? parts[6] : 'LIVE';

      navState.push(
        MaterialPageRoute(
          builder: (_) => MatchDetailScreen(
            fixture: Fixture(
              id: id,
              referee: '',
              timezone: 'UTC',
              date: DateTime.now(),
              timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
              statusLong: status,
              statusShort: status,
              elapsed: 45,
              league: const League(id: 0, name: 'Live Match', country: '', logoUrl: ''),
              homeTeam: Team(id: 0, name: home, logoUrl: ''),
              awayTeam: Team(id: 0, name: away, logoUrl: ''),
              goalsHome: homeScore,
              goalsAway: awayScore,
            ),
          ),
        ),
      );
    }
  }

  /// Request runtime notification permissions
  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;

    if (Platform.isAndroid) {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final granted =
          await androidImplementation?.requestNotificationsPermission();
      return granted ?? false;
    } else if (Platform.isIOS) {
      final iosImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      final granted = await iosImplementation?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    return false;
  }

  /// Show an instant goal notification banner on the lock screen
  Future<void> showGoalAlert({
    required int matchId,
    required String homeTeam,
    required String awayTeam,
    required String scorerName,
    required int minute,
    required int homeScore,
    required int awayScore,
  }) async {
    final title = 'GOAL! $homeTeam $homeScore - $awayScore $awayTeam';
    final body = '$scorerName ($minute\') scores for ${homeScore > awayScore ? homeTeam : awayTeam}!';

    const androidDetails = AndroidNotificationDetails(
      _goalChannelId,
      _goalChannelName,
      channelDescription: _goalChannelDesc,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      styleInformation: BigTextStyleInformation(''),
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _notificationsPlugin.show(
      matchId,
      title,
      body,
      notificationDetails,
      payload: 'match|$matchId|$homeTeam|$awayTeam|$homeScore|$awayScore|1H',
    );
  }

  /// Show a general instant notification (e.g. Red Card, Full Time)
  Future<void> showInstantAlert({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _goalChannelId,
      _goalChannelName,
      channelDescription: _goalChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// Schedule a match kickoff reminder 15 minutes before the match begins
  Future<void> scheduleMatchKickoffReminder({
    required int matchId,
    required String homeTeam,
    required String awayTeam,
    required DateTime kickoffTime,
  }) async {
    final reminderTime = kickoffTime.subtract(const Duration(minutes: 15));
    if (reminderTime.isBefore(DateTime.now())) {
      debugPrint('Kickoff reminder time is in the past, skipping schedule');
      return;
    }

    final scheduledDate = tz.TZDateTime.from(reminderTime, tz.local);

    const androidDetails = AndroidNotificationDetails(
      _kickoffChannelId,
      _kickoffChannelName,
      channelDescription: _kickoffChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _notificationsPlugin.zonedSchedule(
      matchId,
      'Match Kickoff Soon!',
      '$homeTeam vs $awayTeam kicks off in 15 minutes.',
      scheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'match|$matchId|$homeTeam|$awayTeam|0|0|NS',
    );

    debugPrint('Scheduled kickoff reminder for match $matchId at $reminderTime');
  }

  /// Cancel a scheduled reminder for a match
  Future<void> cancelMatchReminder(int matchId) async {
    await _notificationsPlugin.cancel(matchId);
    debugPrint('Cancelled reminder for match $matchId');
  }

  /// Show a Breaking Football News notification alert
  Future<void> showNewsAlert({
    required int id,
    required String title,
    required String body,
    required String url,
    required String source,
  }) async {
    final payload = 'news|$url|$title|$source';

    final androidDetails = AndroidNotificationDetails(
      _newsChannelId,
      _newsChannelName,
      channelDescription: _newsChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: '📰 $title',
        summaryText: source,
      ),
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _notificationsPlugin.show(
      id,
      '📰 $title',
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// Trigger a live test Goal notification to verify sound, vibration & match deep link
  Future<void> testSendGoalNotification() async {
    await showGoalAlert(
      matchId: 1205934,
      homeTeam: 'Arsenal',
      awayTeam: 'Chelsea',
      scorerName: 'Bukayo Saka',
      minute: 23,
      homeScore: 1,
      awayScore: 0,
    );
  }

  /// Trigger a live test News notification to verify news deep linking & re-engagement
  Future<void> testSendNewsNotification([NewsArticle? article]) async {
    final title = article?.title ?? 'Breaking Transfer News: Star Winger Finalizes €80M Deal';
    final source = article?.source ?? 'Sky Sports';
    final desc = article?.description.isNotEmpty == true
        ? article!.description
        : 'Full terms agreed on long-term contract ahead of upcoming derby match.';
    final url = article?.url ?? 'https://www.skysports.com/football/news';

    await showNewsAlert(
      id: 999901,
      title: title,
      body: desc,
      url: url,
      source: source,
    );
  }

  /// Subscribe to a team or match topic
  Future<void> subscribeToTopic(String topic) async {
    _subscribedTopics.add(topic);
    debugPrint('Subscribed to topic: $topic');
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    _subscribedTopics.remove(topic);
    debugPrint('Unsubscribed from topic: $topic');
  }

  /// Check if user is subscribed to topic
  bool isSubscribed(String topic) => _subscribedTopics.contains(topic);
}
