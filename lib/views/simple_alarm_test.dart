import 'package:flutter/material.dart';
import 'package:alarm_clock_clean/services/alarm_service.dart';
import 'dart:async';

class SimpleAlarmTest extends StatefulWidget {
  const SimpleAlarmTest({super.key});

  @override
  State<SimpleAlarmTest> createState() => _SimpleAlarmTestState();
}

class _SimpleAlarmTestState extends State<SimpleAlarmTest> {
  Timer? _testTimer;
  int _countdown = 0;
  bool _isRunning = false;

  void _startSimpleAlarm(int seconds) {
    setState(() {
      _countdown = seconds;
      _isRunning = true;
    });

    _testTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_countdown > 0) {
          _countdown--;
        } else {
          timer.cancel();
          _isRunning = false;
          _triggerAlarm();
        }
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Alarm set for $seconds seconds!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _triggerAlarm() async {
    print('🚨🚨🚨 ALARM IS RINGING! 🚨🚨🚨');

    try {
      await AlarmService.initialize();
      await AlarmService.triggerAlarm(123);

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.red,
            title: const Text(
              '🚨 ALARM!',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'Your alarm is ringing!',
              style: TextStyle(color: Colors.white),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  AlarmService.stopAlarm();
                  Navigator.pop(context);
                },
                child: const Text('STOP ALARM'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  void dispose() {
    _testTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffa8c889),
      appBar: AppBar(
        title: const Text('Simple Alarm Test'),
        backgroundColor: Colors.black,
        foregroundColor: const Color(0xffa8c889),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isRunning) ...[
              Text(
                'Alarm in: $_countdown',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  _testTimer?.cancel();
                  setState(() {
                    _isRunning = false;
                    _countdown = 0;
                  });
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Cancel'),
              ),
            ] else ...[
              const Text(
                'Quick Alarm Tests',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => _startSimpleAlarm(5),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  minimumSize: const Size(200, 60),
                ),
                child: const Text(
                  '5 Second Alarm',
                  style: TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _startSimpleAlarm(10),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: const Size(200, 60),
                ),
                child: const Text(
                  '10 Second Alarm',
                  style: TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _startSimpleAlarm(30),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(200, 60),
                ),
                child: const Text(
                  '30 Second Alarm',
                  style: TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _triggerAlarm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  minimumSize: const Size(200, 60),
                ),
                child: const Text(
                  'Test Alarm NOW',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
