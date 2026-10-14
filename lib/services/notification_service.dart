import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Global notification service supporting:
/// 1. Instant Goal Alerts
/// 2. Match Kickoff Reminders (scheduled before match start)
/// 3. Favorite Team & Match Notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // Channels
  static const String _goalChannelId = 'live_goal_alerts';
  static const String _goalChannelName = 'Live Goal Alerts';
  static const String _goalChannelDesc = 'Instant notifications when goals are scored';

  static const String _kickoffChannelId = 'match_kickoff_alerts';
  static const String _kickoffChannelName = 'Match Kickoff Reminders';
  static const String _kickoffChannelDesc = 'Reminders 15 minutes before your matches kick off';

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
        },
      );

      // Request permissions (Android 13+)
      await requestPermissions();

      _isInitialized = true;
      debugPrint('NotificationService initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize NotificationService: $e');
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
      payload: 'match_$matchId',
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
      payload: 'match_$matchId',
    );

    debugPrint('Scheduled kickoff reminder for match $matchId at $reminderTime');
  }

  /// Cancel a scheduled reminder for a match
  Future<void> cancelMatchReminder(int matchId) async {
    await _notificationsPlugin.cancel(matchId);
    debugPrint('Cancelled reminder for match $matchId');
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
