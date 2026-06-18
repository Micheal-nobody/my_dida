import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:my_dida/config/locator.dart';
import 'package:my_dida/core/ui/app_message_service.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'task_notification_navigation_service.dart';

class NotificationService {
  NotificationService({
    FlutterLocalNotificationsPlugin? plugin,
    TaskNotificationNavigationService? navigationService,
    AppMessageService? messageService,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       _navigationService =
           navigationService ?? getIt<TaskNotificationNavigationService>(),
       _messageService = messageService ?? getIt<AppMessageService>();

  static const String taskReminderChannelId = 'task_reminders';
  static const String taskReminderChannelName = '任务提醒';
  static const String taskReminderChannelDescription = '根据任务时间触发的提醒通知';

  final FlutterLocalNotificationsPlugin _plugin;
  final TaskNotificationNavigationService _navigationService;
  final AppMessageService _messageService;

  bool _initialized = false;

  FlutterLocalNotificationsPlugin get plugin => _plugin;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    tz_data.initializeTimeZones();
    await _configureLocalTimeZone();

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );

    await _plugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );

    await _createAndroidChannel();
    await _consumeLaunchNotification();
    _initialized = true;
  }

  Future<bool> ensureNotificationPermission() async {
    final androidPlugin = _androidPlugin;
    if (androidPlugin == null) {
      return true;
    }

    final isEnabled = await androidPlugin.areNotificationsEnabled() ?? true;
    if (isEnabled) {
      return true;
    }

    final granted = await requestNotificationPermission();
    if (!granted) {
      _messageService.showWarning('通知权限未开启，任务提醒不会发送');
    }
    return granted;
  }

  Future<bool> requestNotificationPermission() async {
    final androidPlugin = _androidPlugin;
    if (androidPlugin == null) {
      return true;
    }

    return await androidPlugin.requestNotificationsPermission() ?? false;
  }

  Future<bool> canScheduleExactAlarms() async {
    final androidPlugin = _androidPlugin;
    if (androidPlugin == null) {
      return false;
    }

    return await androidPlugin.canScheduleExactNotifications() ?? false;
  }

  Future<bool> requestExactAlarmPermission() async {
    final androidPlugin = _androidPlugin;
    if (androidPlugin == null) {
      return false;
    }

    return await androidPlugin.requestExactAlarmsPermission() ?? false;
  }

  Future<AndroidScheduleMode> resolveScheduleMode() async {
    if (await canScheduleExactAlarms()) {
      return AndroidScheduleMode.exactAllowWhileIdle;
    }

    final granted = await requestExactAlarmPermission();
    if (granted) {
      return AndroidScheduleMode.exactAllowWhileIdle;
    }

    _messageService.showInfo('未授予精确闹钟权限，提醒将以非精确方式发送');
    return AndroidScheduleMode.inexactAllowWhileIdle;
  }

  NotificationDetails buildTaskReminderNotificationDetails() =>
      const NotificationDetails(
        android: AndroidNotificationDetails(
          taskReminderChannelId,
          taskReminderChannelName,
          channelDescription: taskReminderChannelDescription,
          importance: Importance.max,
          priority: Priority.high,
          category: AndroidNotificationCategory.reminder,
          visibility: NotificationVisibility.public,
          icon: '@mipmap/ic_launcher',
        ),
      );

  tz.TZDateTime toTzDateTime(DateTime dateTime) =>
      tz.TZDateTime.from(dateTime, tz.local);

  Future<void> _createAndroidChannel() async {
    await _androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        taskReminderChannelId,
        taskReminderChannelName,
        description: taskReminderChannelDescription,
        importance: Importance.max,
      ),
    );
  }

  Future<void> _consumeLaunchNotification() async {
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    final response = launchDetails?.notificationResponse;
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      _handleNotificationPayload(response?.payload);
    }
  }

  Future<void> _configureLocalTimeZone() async {
    try {
      final localTimeZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTimeZone));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }
  }

  void _onDidReceiveNotificationResponse(NotificationResponse response) {
    _handleNotificationPayload(response.payload);
  }

  void _handleNotificationPayload(String? payload) {
    final taskId = int.tryParse(payload ?? '');
    if (taskId == null) {
      return;
    }

    _navigationService.openTask(taskId);
  }

  AndroidFlutterLocalNotificationsPlugin? get _androidPlugin => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();
}
