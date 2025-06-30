import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'dart:async';

class AlarmService {
  static final AlarmService _instance = AlarmService._internal();
  factory AlarmService() => _instance;
  AlarmService._internal();

  static FlutterLocalNotificationsPlugin? _notificationsPlugin;
  static AudioPlayer? _audioPlayer;
  static Timer? _alarmTimer;
  static int? _currentAlarmId;
  static bool _isAlarmPlaying = false;

  static const String _channelId = 'alarm_channel';
  static const String _channelName = 'Alarm Notifications';
  static const String _channelDescription = 'Notifications for alarm clock';

  static Future<void> initialize() async {
    try {
      // Ensure Flutter binding is initialized (important for background tasks)
      WidgetsFlutterBinding.ensureInitialized();
      if (kDebugMode) {
        print('DEBUG: Flutter binding ensured in AlarmService');
      }

      _notificationsPlugin = FlutterLocalNotificationsPlugin();
      _audioPlayer = AudioPlayer();

      // Android initialization
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );

      const InitializationSettings initializationSettings =
          InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS,
          );

      await _notificationsPlugin!.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTap,
      );

      // Create notification channel for Android
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      await _notificationsPlugin!
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);

      // Request permissions (might fail in background)
      await _requestPermissions();
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: AlarmService initialization failed: $e');
      }
      // Re-throw the error so caller knows initialization failed
      rethrow;
    }
  }

  static Future<void> _requestPermissions() async {
    final androidPlugin = _notificationsPlugin!
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
      await androidPlugin.requestExactAlarmsPermission();
    }

    final iosPlugin = _notificationsPlugin!
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();

    if (iosPlugin != null) {
      await iosPlugin.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  static Future<void> triggerAlarm(int alarmId) async {
    if (kDebugMode) {
      print('DEBUG: triggerAlarm called for ID: $alarmId');
    }

    if (_isAlarmPlaying) {
      await stopAlarm();
    }

    _currentAlarmId = alarmId;
    _isAlarmPlaying = true;

    try {
      // Show notification
      await _showAlarmNotification(alarmId);
      if (kDebugMode) {
        print('DEBUG: Notification shown successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: Error showing notification: $e');
      }
    }

    try {
      // Play alarm sound
      await _playAlarmSound();
      if (kDebugMode) {
        print('DEBUG: Alarm sound played successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: Error playing alarm sound: $e');
      }
    }

    try {
      // Start vibration
      await _startVibration();
      if (kDebugMode) {
        print('DEBUG: Vibration started successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: Error starting vibration: $e');
      }
    }

    // Set timer to stop alarm after 5 minutes if not stopped manually
    _alarmTimer = Timer(const Duration(minutes: 5), () {
      stopAlarm();
    });

    if (kDebugMode) {
      print('Alarm triggered successfully for ID: $alarmId');
    }
  }

  static Future<void> _showAlarmNotification(int alarmId) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          ongoing: true,
          autoCancel: false,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
          playSound: true,
          enableVibration: true,
          actions: [
            AndroidNotificationAction(
              'stop_alarm',
              'Stop Alarm',
              cancelNotification: true,
            ),
          ],
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.critical,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin!.show(
      alarmId,
      'Alarm',
      'Your alarm is ringing! Tap to stop.',
      notificationDetails,
    );
  }

  static Future<void> _playAlarmSound() async {
    try {
      // Use a system sound - we'll rely on notification sound for now
      // You can add a custom alarm.mp3 file to assets/sounds/ if you want a custom sound
      await _audioPlayer!.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer!.setVolume(1.0);

      // Try to play custom sound, otherwise just let notification handle sound
      try {
        await _audioPlayer!.setSource(AssetSource('sounds/alarm.mp3'));
        await _audioPlayer!.resume();
      } catch (e) {
        // Custom sound not found, that's okay - notification will handle sound
        if (kDebugMode) {
          print('Custom alarm sound not found, using notification sound: $e');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Could not initialize audio player: $e');
      }
    }
  }

  static Future<void> _startVibration() async {
    try {
      if (await Vibration.hasVibrator() == true) {
        // Vibrate in a pattern: vibrate for 1 second, pause for 0.5 seconds, repeat
        Vibration.vibrate(pattern: [0, 1000, 500], repeat: 0);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Could not start vibration: $e');
      }
    }
  }

  static Future<void> stopAlarm() async {
    if (!_isAlarmPlaying) return;

    _isAlarmPlaying = false;
    _alarmTimer?.cancel();

    // Stop audio
    try {
      await _audioPlayer!.stop();
    } catch (e) {
      if (kDebugMode) {
        print('Error stopping audio: $e');
      }
    }

    // Stop vibration
    try {
      await Vibration.cancel();
    } catch (e) {
      if (kDebugMode) {
        print('Error stopping vibration: $e');
      }
    }

    // Cancel notification
    if (_currentAlarmId != null) {
      await _notificationsPlugin!.cancel(_currentAlarmId!);
    }

    _currentAlarmId = null;

    if (kDebugMode) {
      print('Alarm stopped');
    }
  }

  static void _onNotificationTap(NotificationResponse response) {
    if (response.actionId == 'stop_alarm' || response.actionId == null) {
      stopAlarm();
    }
  }

  static bool get isAlarmPlaying => _isAlarmPlaying;
  static int? get currentAlarmId => _currentAlarmId;

  // Background-friendly alarm with sound + vibration (no notifications)
  static Future<void> triggerBackgroundAlarm(int alarmId) async {
    if (kDebugMode) {
      print('🚨🚨🚨 BACKGROUND ALARM TRIGGERED FOR ID: $alarmId 🚨🚨🚨');
      print('DEBUG: Time: ${DateTime.now()}');
    }

    _currentAlarmId = alarmId;
    _isAlarmPlaying = true;

    try {
      // Initialize audio player (doesn't need context)
      _audioPlayer = AudioPlayer();

      // Play alarm sound in background
      await _playBackgroundAlarmSound();
      if (kDebugMode) {
        print('DEBUG: ✅ Background alarm sound started');
      }
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ Error starting background alarm sound: $e');
      }
    }

    try {
      // Start vibration (works in background)
      if (await Vibration.hasVibrator() == true) {
        Vibration.vibrate(pattern: [0, 1000, 500], repeat: 0);
        if (kDebugMode) {
          print('DEBUG: ✅ Background alarm vibration started');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ Error starting vibration: $e');
      }
    }

    // Set timer to stop after 5 minutes
    _alarmTimer = Timer(const Duration(minutes: 5), () {
      stopBackgroundAlarm();
    });

    if (kDebugMode) {
      print('DEBUG: ✅ Background alarm is now active (sound + vibration)');
    }
  }

  // Background-friendly audio player (no notification dependencies)
  static Future<void> _playBackgroundAlarmSound() async {
    try {
      await _audioPlayer!.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer!.setVolume(1.0);

      // Try to play custom sound from assets
      try {
        await _audioPlayer!.setSource(AssetSource('sounds/alarm.mp3'));
        await _audioPlayer!.resume();
        if (kDebugMode) {
          print('DEBUG: ✅ Playing custom alarm sound');
        }
      } catch (e) {
        if (kDebugMode) {
          print('DEBUG: Custom alarm sound not found, trying fallback: $e');
        }

        // Try a system beep sound as fallback
        try {
          await _audioPlayer!.setSource(
            DeviceFileSource('/system/media/audio/alarms/Alarm_Classic.ogg'),
          );
          await _audioPlayer!.resume();
          if (kDebugMode) {
            print('DEBUG: ✅ Playing system alarm sound');
          }
        } catch (e2) {
          if (kDebugMode) {
            print('DEBUG: System alarm sound also failed: $e2');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: Could not initialize background audio player: $e');
      }
    }
  }

  // Stop background alarm
  static Future<void> stopBackgroundAlarm() async {
    if (!_isAlarmPlaying) return;

    _isAlarmPlaying = false;
    _alarmTimer?.cancel();

    // Stop audio
    try {
      await _audioPlayer?.stop();
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: Error stopping background audio: $e');
      }
    }

    // Stop vibration
    try {
      await Vibration.cancel();
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: Error stopping vibration: $e');
      }
    }

    _currentAlarmId = null;

    if (kDebugMode) {
      print('DEBUG: Background alarm stopped');
    }
  }

  // Simple alarm for background contexts (no notifications, just vibration + logs)
  static Future<void> triggerSimpleAlarm(int alarmId) async {
    if (kDebugMode) {
      print('🚨🚨🚨 SIMPLE ALARM TRIGGERED FOR ID: $alarmId 🚨🚨🚨');
      print('DEBUG: Time: ${DateTime.now()}');
    }

    _currentAlarmId = alarmId;
    _isAlarmPlaying = true;

    try {
      // Try vibration (works in background)
      if (await Vibration.hasVibrator() == true) {
        Vibration.vibrate(pattern: [0, 1000, 500], repeat: 0);
        if (kDebugMode) {
          print('DEBUG: ✅ Simple alarm vibration started');
        }
      }

      // Set timer to stop after 2 minutes
      _alarmTimer = Timer(const Duration(minutes: 2), () {
        stopSimpleAlarm();
      });

      if (kDebugMode) {
        print('DEBUG: ✅ Simple alarm is now active (vibration only)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: ❌ Error in simple alarm: $e');
      }
    }
  }

  static Future<void> stopSimpleAlarm() async {
    _isAlarmPlaying = false;
    _alarmTimer?.cancel();

    try {
      await Vibration.cancel();
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: Error stopping simple alarm vibration: $e');
      }
    }

    _currentAlarmId = null;

    if (kDebugMode) {
      print('DEBUG: Simple alarm stopped');
    }
  }
}
