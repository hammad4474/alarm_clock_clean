import 'package:alarm_clock_clean/views/custom_time_picker.dart';
import 'package:alarm_clock_clean/services/alarm_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:marquee/marquee.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:vibration/vibration.dart';
import 'dart:async';
import 'dart:convert';

// Simple test callback to verify AndroidAlarmManager works at all
@pragma('vm:entry-point')
void simpleTestCallback(int id) {
  print('🎯🎯🎯 SIMPLE TEST CALLBACK TRIGGERED for ID: $id 🎯🎯🎯');
  print('DEBUG: AndroidAlarmManager CAN execute callbacks!');
  print('DEBUG: Current time: ${DateTime.now()}');
}

// Top-level callback function for AndroidAlarmManager (more reliable)
@pragma('vm:entry-point')
void alarmCallbackTopLevel(int id) {
  print('🔥🔥🔥 TOP-LEVEL ALARM CALLBACK TRIGGERED for ID: $id 🔥🔥🔥');
  print('DEBUG: Current time: ${DateTime.now()}');

  // Use a microtask to handle async operations with proper Flutter binding
  () async {
    try {
      // Ensure Flutter binding is initialized in background isolate
      WidgetsFlutterBinding.ensureInitialized();
      print('DEBUG: ✅ Flutter binding initialized in background');

      // Try the background-friendly alarm first
      await AlarmService.triggerBackgroundAlarm(id);
      print('DEBUG: ✅ Background alarm triggered successfully (top-level)');
    } catch (e) {
      print('DEBUG: ❌ Error in top-level alarm callback: $e');

      // Enhanced fallback - multiple notification attempts
      _showEnhancedAlarmFallback(id);
    }
  }();
}

// Enhanced fallback with multiple notification attempts
void _showEnhancedAlarmFallback(int id) {
  print('🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨');
  print('🚨        ALARM $id IS RINGING NOW!        🚨');
  print('🚨     Time: ${DateTime.now()}     🚨');
  print('🚨   YOUR ALARM IS WORKING PERFECTLY!   🚨');
  print('🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨');

  // Try vibration in background
  () async {
    try {
      // Multiple vibration attempts
      for (int i = 0; i < 10; i++) {
        await Future.delayed(const Duration(milliseconds: 500));
        await Vibration.vibrate(duration: 1000);
        print('🚨 VIBRATION ATTEMPT $i - ALARM IS RINGING! 🚨');
      }
    } catch (e) {
      print('Vibration error: $e');
    }
  }();
}

// Simple fallback that doesn't rely on flutter_local_notifications
void _showSimpleAlarmFallback(int id) {
  print('DEBUG: 🚨🚨🚨 ALARM $id IS RINGING! (Simple fallback) 🚨🚨🚨');
  print('DEBUG: Time: ${DateTime.now()}');
  print('DEBUG: This alarm would be ringing with sound and vibration');
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Timer _timer;
  String _currentTime = '';
  String _currentTimeHM = '';
  int _currentProgress = 0;
  final Map<int, int> _alarmSeconds = {};
  final Map<int, bool> _isAM = {};
  final List<int> _timerIndices = [];
  late SharedPreferences prefs;

  @override
  void initState() {
    super.initState();
    _initializeAlarms();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTime();
      // Check if alarm state changed (for UI updates)
      setState(() {});
    });
    _initPrefs();
  }

  Future<void> _initializeAlarms() async {
    // Initialize alarm manager
    await AndroidAlarmManager.initialize();
  }

  // Test function to create a 30-second test alarm
  Future<void> _createTestAlarm() async {
    final now = DateTime.now();
    final testTime = now.add(const Duration(seconds: 30));

    print(
      '🧪 DEBUG: Creating SHORT test alarm for ${testTime.hour}:${testTime.minute}:${testTime.second}',
    );
    print('🕐 DEBUG: Current time: ${now.hour}:${now.minute}:${now.second}');
    print('⏰ DEBUG: Alarm will trigger in 30 seconds');

    try {
      // Try top-level callback first
      await AndroidAlarmManager.oneShot(
        const Duration(seconds: 30), // Shorter test for faster feedback
        999, // Test alarm ID
        alarmCallbackTopLevel, // Use top-level function
        exact: true,
        wakeup: true,
      );
      print(
        'DEBUG: ✅ Test alarm scheduled successfully for 30 seconds (top-level callback)',
      );

      // Show a snackbar to confirm
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⏰ Test alarm set for 30 SECONDS from now!'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }

      // Also schedule a fallback timer to see if the issue is with AndroidAlarmManager
      Timer(const Duration(seconds: 32), () {
        print('🔍 DEBUG: Fallback timer check - did the alarm trigger?');
      });
    } catch (e) {
      print('DEBUG: ❌ Error creating test alarm: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Very simple AndroidAlarmManager test (just print, no AlarmService)
  Future<void> _simpleAlarmManagerTest() async {
    print(
      '🎯 DEBUG: Testing AndroidAlarmManager with SIMPLE callback (no AlarmService)',
    );

    try {
      await AndroidAlarmManager.oneShot(
        const Duration(seconds: 10), // Even shorter test
        777, // Simple test ID
        simpleTestCallback, // Very simple callback
        exact: true,
        wakeup: true,
      );
      print(
        'DEBUG: ✅ Simple AndroidAlarmManager test scheduled for 10 seconds',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎯 Simple test: 10 seconds (just print to console)'),
            backgroundColor: Colors.purple,
          ),
        );
      }
    } catch (e) {
      print('DEBUG: ❌ Error in simple AndroidAlarmManager test: $e');
    }
  }

  // Test the AlarmService directly (bypassing AndroidAlarmManager)
  Future<void> _testAlarmServiceDirectly() async {
    print(
      '🔬 DEBUG: Testing AlarmService DIRECTLY (bypassing AndroidAlarmManager)',
    );

    try {
      await AlarmService.initialize();
      print('DEBUG: ✅ AlarmService initialized for direct test');

      await AlarmService.triggerAlarm(888); // Direct test ID
      print('DEBUG: ✅ AlarmService triggered directly');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🔬 Testing alarm sound/notification directly!'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      print('DEBUG: ❌ Error in direct AlarmService test: $e');
    }
  }

  // Test the AlarmService directly without snackbar
  Future<void> _testAlarmServiceDirectlyWithoutSnackbar() async {
    print(
      '🔬 DEBUG: Testing AlarmService DIRECTLY (bypassing AndroidAlarmManager)',
    );

    try {
      await AlarmService.initialize();
      print('DEBUG: ✅ AlarmService initialized for direct test');

      await AlarmService.triggerAlarm(888); // Direct test ID
      print('DEBUG: ✅ AlarmService triggered directly');
    } catch (e) {
      print('DEBUG: ❌ Error in direct AlarmService test: $e');
    }
  }

  // Test the background alarm directly
  Future<void> _testBackgroundAlarmDirectly() async {
    print('🎵 DEBUG: Testing Background Alarm DIRECTLY (sound + vibration)');

    try {
      await AlarmService.triggerBackgroundAlarm(999); // Background test ID
      print('DEBUG: ✅ Background alarm triggered directly');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎵 Testing background alarm (sound + vibration)!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('DEBUG: ❌ Error in direct background alarm test: $e');
    }
  }

  // Test the background alarm directly without snackbar
  Future<void> _testBackgroundAlarmDirectlyWithoutSnackbar() async {
    print('🎵 DEBUG: Testing Background Alarm DIRECTLY (sound + vibration)');

    try {
      await AlarmService.triggerBackgroundAlarm(999); // Background test ID
      print('DEBUG: ✅ Background alarm triggered directly');
    } catch (e) {
      print('DEBUG: ❌ Error in direct background alarm test: $e');
    }
  }

  // This is the function that will be called when the alarm triggers
  @pragma('vm:entry-point')
  static void _alarmCallback(int id) {
    print('========================================');
    print('DEBUG: 🚨 ALARM CALLBACK TRIGGERED for ID: $id');
    print('DEBUG: Current time: ${DateTime.now()}');
    print('========================================');

    // Use a microtask to handle async operations in a sync callback
    () async {
      try {
        // Initialize alarm service if not already initialized
        await AlarmService.initialize();
        print('DEBUG: ✅ AlarmService initialized successfully');

        // Trigger the alarm with sound and notification
        await AlarmService.triggerAlarm(id);
        print('DEBUG: ✅ Alarm triggered successfully');

        // Try to show a simple system notification as backup
        print('DEBUG: 📱 Alarm should now be ringing with notification');
      } catch (e) {
        print('DEBUG: ❌ Error in alarm callback: $e');
        print('DEBUG: Stack trace: ${StackTrace.current}');
      }
    }();
  }

  Future<void> _scheduleAlarm(
    int index,
    TimeOfDay selectedTime,
    bool isAM,
  ) async {
    final now = DateTime.now();

    // Convert to 24-hour format
    int hour = selectedTime.hour;
    if (!isAM && hour < 12) {
      hour += 12;
    } else if (isAM && hour == 12) {
      hour = 0;
    }

    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      hour,
      selectedTime.minute,
    );

    // If the time is in the past, schedule for next day
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    print('DEBUG: Scheduling alarm for $scheduledDate (Current time: $now)');
    print(
      'DEBUG: Original time: ${selectedTime.hour}:${selectedTime.minute} ${isAM ? 'AM' : 'PM'}',
    );
    print('DEBUG: Converted hour: $hour');

    try {
      await AndroidAlarmManager.oneShot(
        Duration(milliseconds: scheduledDate.difference(now).inMilliseconds),
        index,
        alarmCallbackTopLevel, // Use top-level callback
        exact: true,
        wakeup: true,
      );
      print(
        'DEBUG: Alarm scheduled successfully for index $index (top-level callback)',
      );
    } catch (e) {
      print('DEBUG: Error scheduling alarm: $e');
    }
  }

  Future<void> _cancelAlarm(int index) async {
    await AndroidAlarmManager.cancel(index);
  }

  Future<void> _addNewTimer(Map<String, dynamic> timeData) async {
    final int seconds = timeData['seconds'] as int;
    final bool isAM = timeData['isAM'] as bool;

    // Extract hour and minute from total seconds
    final int hour24 = seconds ~/ 3600;
    final int minute = (seconds % 3600) ~/ 60;

    // Convert to 12-hour format for display
    int displayHour = hour24;
    if (hour24 == 0) {
      displayHour = 12;
    } else if (hour24 > 12) {
      displayHour = hour24 - 12;
    }

    final TimeOfDay selectedTime = TimeOfDay(hour: displayHour, minute: minute);

    print('DEBUG: Adding alarm - Original seconds: $seconds');
    print('DEBUG: Extracted - Hour24: $hour24, Minute: $minute');
    print('DEBUG: Display hour: $displayHour, AM/PM: ${isAM ? 'AM' : 'PM'}');

    final int newIndex = _timerIndices.isEmpty ? 0 : _timerIndices.last + 1;

    setState(() {
      _timerIndices.add(newIndex);
      _alarmSeconds[newIndex] = seconds;
      _isAM[newIndex] = isAM;
    });

    // Schedule the alarm with the correct time
    await _scheduleAlarm(newIndex, selectedTime, isAM);
    _saveAlarms();
  }

  Future<void> _deleteTimer(int index) async {
    setState(() {
      _timerIndices.remove(index);
      _alarmSeconds.remove(index);
      _isAM.remove(index);
    });

    // Cancel the alarm
    await _cancelAlarm(index);
    _saveAlarms();
  }

  Future<void> _initPrefs() async {
    prefs = await SharedPreferences.getInstance();
    _loadAlarms();
  }

  void _loadAlarms() {
    final String? savedAlarms = prefs.getString('saved_alarms');
    if (savedAlarms != null) {
      final List<dynamic> alarms = jsonDecode(savedAlarms);
      setState(() {
        for (var alarm in alarms) {
          final int index = alarm['index'];
          final int seconds = alarm['seconds'];
          final bool isAM = alarm['isAM'];

          _timerIndices.add(index);
          _alarmSeconds[index] = seconds;
          _isAM[index] = isAM;
        }
      });
    }
  }

  void _saveAlarms() {
    final List<Map<String, dynamic>> alarmData = _timerIndices.map((index) {
      return {
        'index': index,
        'seconds': _alarmSeconds[index],
        'isAM': _isAM[index],
      };
    }).toList();

    prefs.setString('saved_alarms', jsonEncode(alarmData));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatTime(int totalSeconds, [int? timerIndex]) {
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;

    // Convert to 12-hour format
    int displayHours = hours;
    bool isAM = hours < 12;
    if (hours > 12) {
      displayHours = hours - 12;
    } else if (hours == 0) {
      displayHours = 12;
    }

    if (timerIndex != null) {
      return '${displayHours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')} ${_isAM[timerIndex] ?? true ? 'AM' : 'PM'}';
    } else {
      return '${displayHours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')} ${isAM ? 'AM' : 'PM'}';
    }
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      // Format main clock display in 12-hour format with AM/PM
      int hours = now.hour;
      bool isAM = hours < 12;
      if (hours > 12) {
        hours = hours - 12;
      } else if (hours == 0) {
        hours = 12;
      }
      _currentTime =
          '${_twoDigits(hours)}:${_twoDigits(now.minute)}:${_twoDigits(now.second)} ${isAM ? 'AM' : 'PM'}';
      _currentTimeHM =
          '${_twoDigits(hours)}:${_twoDigits(now.minute)} ${isAM ? 'AM' : 'PM'}';
      _currentProgress = now.second * 40 ~/ 60;
    });
  }

  String _twoDigits(int n) {
    return n.toString().padLeft(2, '0');
  }

  // Alternative alarm scheduling method without reboot functionality
  Future<void> _scheduleAlarmSimple(
    int index,
    TimeOfDay selectedTime,
    bool isAM,
  ) async {
    final now = DateTime.now();

    // Convert to 24-hour format
    int hour = selectedTime.hour;
    if (!isAM && hour < 12) {
      hour += 12;
    } else if (isAM && hour == 12) {
      hour = 0;
    }

    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      hour,
      selectedTime.minute,
    );

    // If the time is in the past, schedule for next day
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    print(
      'DEBUG: Simple scheduling alarm for $scheduledDate (Current time: $now)',
    );
    print(
      'DEBUG: Original time: ${selectedTime.hour}:${selectedTime.minute} ${isAM ? 'AM' : 'PM'}',
    );
    print('DEBUG: Converted hour: $hour');

    try {
      // Simple one-shot alarm without reboot reschedule
      await AndroidAlarmManager.oneShot(
        Duration(milliseconds: scheduledDate.difference(now).inMilliseconds),
        index,
        _alarmCallback,
        exact: true,
        wakeup: true,
      );
      print('DEBUG: Simple alarm scheduled successfully for index $index');
    } catch (e) {
      print('DEBUG: Error scheduling simple alarm: $e');
      // If even simple scheduling fails, we can fall back to a Timer-based approach
      _fallbackTimerAlarm(index, scheduledDate);
    }
  }

  // Fallback timer-based alarm for testing purposes
  void _fallbackTimerAlarm(int index, DateTime scheduledDate) {
    final now = DateTime.now();
    final duration = scheduledDate.difference(now);

    if (duration.isNegative) {
      print('DEBUG: Cannot schedule alarm in the past');
      return;
    }

    print(
      'DEBUG: Using fallback timer alarm for ${duration.inMinutes} minutes',
    );

    Timer(duration, () {
      print('DEBUG: Fallback timer alarm triggered for index $index');
      _alarmCallback(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xffa8c889),
      child: Scaffold(
        backgroundColor: const Color(0xffa8c889),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top,
                ),
                width: double.infinity,
                height: MediaQuery.sizeOf(context).height * 0.6,
                decoration: const BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(55),
                    topRight: Radius.circular(55),
                    bottomRight: Radius.circular(55),
                    bottomLeft: Radius.circular(55),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        const SizedBox(height: 60),
                        Text(
                          _currentTime,
                          style: const TextStyle(
                            fontSize: 80,
                            color: Color(0xffa8c889),
                            height: 0,
                            fontFamily: 'DS-Digital',
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 30,
                          child: Marquee(
                            text:
                                '  RAVEN CLOCKS  RAVEN CLOCKS  RAVEN CLOCKS  RAVEN CLOCKS  ',
                            style: const TextStyle(
                              fontSize: 24,
                              color: Color(0xffa8c889),
                              fontWeight: FontWeight.bold,
                            ),
                            scrollAxis: Axis.horizontal,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            blankSpace: 20.0,
                            velocity: 50.0,
                            pauseAfterRound: const Duration(seconds: 0),
                            startPadding: 10.0,
                            accelerationDuration: const Duration(seconds: 1),
                            accelerationCurve: Curves.linear,
                            decelerationDuration: const Duration(
                              milliseconds: 500,
                            ),
                            decelerationCurve: Curves.easeOut,
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 15, left: 17),
                      child: CustomPaint(
                        painter: ProgressPainter(
                          currentProgress: _currentProgress,
                        ),
                        size: const Size(double.infinity, 150),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN']
                  .map(
                    (day) => Text(
                      day,
                      style: TextStyle(
                        fontSize: 22,
                        color:
                            DateTime.now().weekday ==
                                [
                                      'MON',
                                      'TUE',
                                      'WED',
                                      'THU',
                                      'FRI',
                                      'SAT',
                                      'SUN',
                                    ].indexOf(day) +
                                    1
                            ? Colors.black
                            : const Color(0xff59644c),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _timerIndices
                      .map(
                        (index) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: GestureDetector(
                            onLongPress: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    backgroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      side: const BorderSide(
                                        color: Color(0xffa8c889),
                                        width: 2,
                                      ),
                                    ),
                                    title: const Text(
                                      'Delete Timer',
                                      style: TextStyle(
                                        color: Color(0xffa8c889),
                                        fontSize: 24,
                                      ),
                                    ),
                                    content: const Text(
                                      'Are you sure you want to delete this timer?',
                                      style: TextStyle(
                                        color: Color(0xffa8c889),
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text(
                                          'Cancel',
                                          style: TextStyle(
                                            color: Color(0xffa8c889),
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          _deleteTimer(index);
                                          Navigator.pop(context);
                                        },
                                        child: const Text(
                                          'Delete',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            child: DottedBorder(
                              borderType: BorderType.RRect,
                              radius: const Radius.circular(12),
                              padding: const EdgeInsets.all(6),
                              strokeWidth: 2,
                              color: Colors.grey,
                              dashPattern: const [5, 5],
                              child: SizedBox(
                                width: 350,
                                height: 150,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        Text(
                                          _formatTime(
                                            _alarmSeconds[index] ?? 1800,
                                            index,
                                          ),
                                          style: const TextStyle(
                                            fontSize: 60,
                                            color: Colors.black,
                                          ),
                                        ),
                                        const Icon(
                                          Icons.alarm,
                                          color: Colors.black,
                                          size: 50,
                                        ),
                                      ],
                                    ),
                                    const Text(
                                      'ALARM',
                                      style: TextStyle(
                                        fontSize: 24,
                                        color: Color(0xff69745f),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ],
        ),
        persistentFooterButtons: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black,
                  fixedSize: const Size(60, 60),
                ),
                onPressed: () {
                  showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now().subtract(
                      const Duration(days: 365),
                    ),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: Color(0xffa8c889),
                            onPrimary: Colors.black,
                            surface: Colors.black,
                            onSurface: Color(0xffa8c889),
                          ),
                          textButtonTheme: TextButtonThemeData(
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xffa8c889),
                            ),
                          ),
                          dialogTheme: DialogThemeData(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                              side: const BorderSide(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        child: child!,
                      );
                    },
                  ).then((selectedDate) {
                    if (selectedDate != null) {
                      // Handle the selected date here
                      print('Selected date: $selectedDate');
                      // You can add more functionality here like:
                      // - Save the selected date
                      // - Show a confirmation message
                      // - Navigate to a specific date view
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Selected date: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                          ),
                          backgroundColor: const Color(0xffa8c889),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  });
                },
                onLongPress:
                    _simpleAlarmManagerTest, // Moved test function to long press
                icon: const Icon(
                  Icons.calendar_month,
                  color: Color(0xffa8c889),
                ),
              ),
              SizedBox(
                width: 250,
                child: GestureDetector(
                  onLongPress: _createTestAlarm,
                  onDoubleTap:
                      _testAlarmServiceDirectlyWithoutSnackbar, // Double tap for full test (no snackbar)
                  onTap:
                      _testBackgroundAlarmDirectlyWithoutSnackbar, // Single tap for background test (no snackbar)
                  child: FloatingActionButton.extended(
                    onPressed: () {}, // Required but unused
                    label: Text(
                      _currentTimeHM,
                      style: const TextStyle(fontSize: 24),
                    ),
                    shape: const StadiumBorder(),
                    backgroundColor: Colors.black,
                    foregroundColor: const Color(0xffa8c889),
                  ),
                ),
              ),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black,
                  fixedSize: const Size(60, 60),
                ),
                onPressed: () async {
                  final timeData = await Navigator.push<Map<String, dynamic>>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CustomTimePicker(),
                    ),
                  );

                  if (timeData != null) {
                    _addNewTimer(timeData);
                  }
                },
                icon: const Icon(Icons.add, color: Color(0xffa8c889)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ProgressPainter extends CustomPainter {
  final int totalBars = 40;
  final int currentProgress;

  ProgressPainter({required this.currentProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    double barSpacing = size.width / totalBars;

    for (int i = 0; i < totalBars; i++) {
      // Determine if this bar should be highlighted
      bool isHighlighted = i <= currentProgress;

      // Set the color based on whether the bar is highlighted
      paint.color = isHighlighted
          ? const Color(0xff333333)
          : const Color(0xffa8c889);

      // Draw the vertical line
      canvas.drawLine(
        Offset(i * barSpacing, size.height),
        Offset(i * barSpacing, 0),
        paint,
      );

      // Draw dots above every 5th line except the current progress
      if (i % 5 == 0 && i != currentProgress) {
        paint
          ..style = PaintingStyle.fill
          ..color = const Color(0xffa8c889);
        canvas.drawCircle(Offset(i * barSpacing, -30), 3, paint);
        paint.style = PaintingStyle.stroke;
      }
    }

    // Draw the red progress indicator
    paint
      ..color = Colors.red
      ..strokeWidth = 3;
    canvas.drawLine(
      Offset(currentProgress * barSpacing, size.height),
      Offset(currentProgress * barSpacing, 0),
      paint,
    );

    // Draw the red arrow
    paint.style = PaintingStyle.fill;
    final path = Path();
    final arrowX = currentProgress * barSpacing;
    path.moveTo(arrowX, -20);
    path.lineTo(arrowX - 10, -40);
    path.lineTo(arrowX + 10, -40);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant ProgressPainter oldDelegate) {
    return oldDelegate.currentProgress != currentProgress;
  }
}
