import 'package:flutter/material.dart';

class CustomTimePicker extends StatefulWidget {
  final void Function(int hour, int minute)? onTimeSelected;
  const CustomTimePicker({super.key, this.onTimeSelected});

  @override
  State<CustomTimePicker> createState() => _CustomTimePickerState();
}

class _CustomTimePickerState extends State<CustomTimePicker> {
  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;

  int selectedHour = 0;
  int selectedMinute = 0;
  bool isAM = true;

  @override
  void initState() {
    _hourController = FixedExtentScrollController(initialItem: 0);
    _minuteController = FixedExtentScrollController(initialItem: 0);
    super.initState();
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    child: Container(
                      alignment: Alignment.center,
                      width: 300,
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xff36402b),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildWheelList(
                          controller: _hourController,
                          items: List.generate(12, (index) => index + 1),
                          onChanged: (value) {
                            setState(() {
                              selectedHour = value + 1;
                            });
                            widget.onTimeSelected?.call(
                              selectedHour,
                              selectedMinute,
                            );
                          },
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            ':',
                            style: TextStyle(
                              color: Color(0xffa8c889),
                              fontSize: 60,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        _buildWheelList(
                          controller: _minuteController,
                          items: List.generate(60, (index) => index),
                          onChanged: (value) {
                            setState(() {
                              selectedMinute = value;
                            });
                            widget.onTimeSelected?.call(
                              selectedHour,
                              selectedMinute,
                            );
                          },
                        ),
                        const SizedBox(width: 20),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () => setState(() => isAM = true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 15,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isAM
                                      ? const Color(0xffa8c889)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'AM',
                                  style: TextStyle(
                                    color: isAM
                                        ? Colors.black
                                        : const Color(0xffa8c889),
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            GestureDetector(
                              onTap: () => setState(() => isAM = false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 15,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: !isAM
                                      ? const Color(0xffa8c889)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'PM',
                                  style: TextStyle(
                                    color: !isAM
                                        ? Colors.black
                                        : const Color(0xffa8c889),
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildBottomButtom(Icons.music_note, 'SOUND\nWAKEUP'),
                  _buildBottomButtom(
                    Icons.notifications,
                    'SNOOZE\nEVERY 10 MIN',
                  ),
                  _buildBottomButtom(Icons.repeat, 'REPEAT\nNO'),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  style: IconButton.styleFrom(
                    fixedSize: const Size(80, 80),
                    backgroundColor: const Color(0xff10130d),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: Icon(Icons.close, color: Colors.green[200]),
                ),
                Text(
                  'CHOOSE TIME',
                  style: TextStyle(
                    color: Colors.green[200],
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  style: IconButton.styleFrom(
                    fixedSize: const Size(80, 80),
                    backgroundColor: const Color(0xff98ac84),
                  ),
                  onPressed: () {
                    // Convert 12-hour format to 24-hour format
                    int hour24 = selectedHour;
                    if (!isAM && selectedHour != 12) {
                      hour24 = selectedHour + 12;
                    } else if (isAM && selectedHour == 12) {
                      hour24 = 0;
                    }

                    int totalSeconds = selectedMinute * 60 + hour24 * 3600;
                    Navigator.pop(context, {
                      'seconds': totalSeconds,
                      'isAM': isAM,
                    });
                  },
                  icon: const Icon(Icons.check, color: Colors.black),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildWheelList({
  required FixedExtentScrollController controller,
  required List<int> items,
  required Function(int) onChanged,
}) {
  return SizedBox(
    width: 70,
    child: ListWheelScrollView.useDelegate(
      itemExtent: 80,
      physics: const FixedExtentScrollPhysics(),
      perspective: 0.005,
      diameterRatio: 2.0,
      onSelectedItemChanged: onChanged,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: items.length,
        builder: (context, index) {
          return Center(
            child: Text(
              items[index].toString().padLeft(2, '0'),
              style: const TextStyle(
                color: Color(0xffa8c889),
                fontSize: 60,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        },
      ),
    ),
  );
}

Widget _buildBottomButtom(IconData icon, String label) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: Colors.green[200], size: 24),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(color: Colors.green[200], fontSize: 18)),
    ],
  );
}
