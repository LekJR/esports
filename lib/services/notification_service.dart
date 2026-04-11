import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'notification_service_stub.dart'
    if (dart.library.html) 'notification_service_web.dart';

class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Initialize mobile notifications
    final androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    final iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    await _plugin.initialize(
      InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    await _configureLocalTimeZone();
    await _requestPermissions();
  }

  Future<void> _configureLocalTimeZone() async {
    tz.initializeTimeZones();
    final String timeZoneName = await FlutterNativeTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));
  }

  Future<void> _requestPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> scheduleMatchNotification(
    int id,
    String teamA,
    String teamB,
    DateTime scheduledDate,
  ) async {
    // For web, use native browser notifications
    if (kIsWeb && webNotificationSupported) {
      scheduleWebNotification(id, teamA, teamB, scheduledDate);
      return;
    }

    // For mobile, use flutter_local_notifications
    final scheduleDate = _nextInstance(scheduledDate);
    const androidDetails = AndroidNotificationDetails(
      'match_reminder_channel',
      'Match reminders',
      channelDescription: 'Reminds you before an esports match starts',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );
    const iosDetails = DarwinNotificationDetails();

    await _plugin.zonedSchedule(
      id,
      'Match Reminder',
      '$teamA vs $teamB is scheduled for ${_formattedTime(scheduledDate)}',
      scheduleDate,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidAllowWhileIdle: true,
    );
  }

  String _formattedTime(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  tz.TZDateTime _nextInstance(DateTime dateTime) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime.from(dateTime, tz.local);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  Future<bool> requestWebNotificationPermission() async {
    if (kIsWeb) {
      return await requestBrowserPermission();
    }
    return false;
  }

  Future<void> cancelNotification(int id) async {
    // Cancel mobile notification
    await _plugin.cancel(id);
    // Note: Web notifications scheduled with Future.delayed cannot be cancelled
  }
}
