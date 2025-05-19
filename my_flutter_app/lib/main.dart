import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'EventData.dart';
import 'dart:math' as math;
import 'package:numberpicker/numberpicker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load the JSON file as a string
  final jsonString = await rootBundle.loadString('lib/event_data_compact.json');
  // Decode the string into a Map
  final jsonData = json.decode(jsonString) as Map<String, dynamic>;
  // Parse into your EventData class
  final eventData = EventData.fromJson(jsonData);

  runApp(MyApp(eventData: eventData));
}

class MyApp extends StatelessWidget {
  final EventData eventData;
  const MyApp({Key? key, required this.eventData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Flutter App',
      home: SelectionScreen(eventData: eventData),
    );
  }
}

class SelectionScreen extends StatefulWidget {
  final EventData eventData;
  const SelectionScreen({Key? key, required this.eventData}) : super(key: key);

  @override
  State<SelectionScreen> createState() => _SelectionScreenState();
}

class _SelectionScreenState extends State<SelectionScreen> {
  String? selectedEvent;
  String? selectedClass;
  String? selectedGender;

  List<String> allEvents = eventToClasses.keys.toList();
  List<String> genderOptions = ['Male', 'Female'];

  String calculationMode = 'Points'; // or 'Time'
  final TextEditingController inputController = TextEditingController();
  String resultText = '';

  // 1. Add state variables for the pickers:
  int minutes = 0;
  int seconds = 0;
  int milliseconds = 0;

  List<String> getAvailableClasses(String? event) {
    if (event == null) return [];
    return eventToClasses[event]!;
  }

  BCValues? getSelectedBCValues() {
    if (selectedEvent == null || selectedClass == null || selectedGender == null) return null;
    try {
      final eventEnum = stringToEventEnum(selectedEvent!);
      final classEnum = stringToSwimClass(selectedClass!);
      final genderEnum = stringToGender(selectedGender!.toLowerCase());
      return widget.eventData.getBC(eventEnum, classEnum, genderEnum);
    } catch (e) {
      return null;
    }
  }

  void calculate() {
    final bc = getSelectedBCValues();
    if (bc == null) {
      setState(() {
        resultText = 'Please select all options.';
      });
      return;
    }
    final b = bc.b;
    final c = bc.c;
    final a = 1200.0;

    try {
      if (calculationMode == 'Points') {
        final totalSeconds = minutes * 60 + seconds + milliseconds / 1000.0;

        if (totalSeconds <= 0) {
          setState(() {
            resultText = 'Enter a valid time.';
          });
          return;
        }
        final points = a * math.exp(-math.exp(b - (c / totalSeconds)));
        setState(() {
          resultText = 'Points: ${points.toStringAsFixed(2)}';
        });
      } else {
        final pointsStr = inputController.text;
        final points = double.tryParse(pointsStr);
        if (points == null || points <= 0 || points >= a) {
          setState(() {
            resultText = 'Enter a valid points value (0 < points < $a).';
          });
          return;
        }
        final time = c / (b - math.log(math.log(a / points)));
        setState(() {
          resultText = 'Required Time: ${formatTimeVerbose(time)}';
        });
      }
    } catch (e) {
      setState(() {
        resultText = 'Calculation error: $e';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    inputController.addListener(_onInputChanged);
  }

  void _onInputChanged() {
  calculate();
}

  @override
  void dispose() {
    inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bcValues = getSelectedBCValues();

    return Scaffold(
      appBar: AppBar(title: const Text('Para Swimming Point Calculator')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            DropdownButtonFormField<String>(
              value: selectedEvent,
              hint: const Text("Select Event"),
              items: allEvents
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedEvent = value;
                  final classes = getAvailableClasses(selectedEvent);
                  selectedClass = classes.isNotEmpty ? classes.first : null;
                  calculate();
                });
              },
            ),
            if (selectedEvent != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Select Class:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: getAvailableClasses(selectedEvent)
                          .map((cls) => ChoiceChip(
                                label: Text(cls),
                                selected: selectedClass == cls,
                                onSelected: (_) {
                                  setState(() {
                                    selectedClass = cls;
                                    calculate();
                                  });
                                },
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ToggleButtons(
                  isSelected: [
                    selectedGender == 'Male',
                    selectedGender == 'Female',
                  ],
                  onPressed: (index) {
                    setState(() {
                      selectedGender = index == 0 ? 'Male' : 'Female';
                      calculate();
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  children: const [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Male'),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Female'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (bcValues != null) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Center(
                  child: Text(
                    'b: ${bcValues.b}, c: ${bcValues.c}',
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ToggleButtons(
                  isSelected: [
                    calculationMode == 'Points',
                    calculationMode == 'Time',
                  ],
                  onPressed: (index) {
                    setState(() {
                      calculationMode = index == 0 ? 'Points' : 'Time';
                      if (calculationMode == 'Points') {
                        inputController.clear();
                        minutes = 0;
                        seconds = 0;
                        milliseconds = 0;
                      } else {
                        // No need to clear pickers when switching to Time mode
                      }
                      resultText = '';
                    });
                    calculate();
                  },
                  borderRadius: BorderRadius.circular(8),
                  children: const [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Points from Time'),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Time from Points'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (calculationMode == 'Points') ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      const Text('Minutes'),
                      NumberPicker(
                        value: minutes,
                        minValue: 0,
                        maxValue: 59,
                        onChanged: (value) {
                          setState(() {
                            minutes = value;
                            calculate();
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Column(
                    children: [
                      const Text('Seconds'),
                      NumberPicker(
                        value: seconds,
                        minValue: 0,
                        maxValue: 59,
                        onChanged: (value) {
                          setState(() {
                            seconds = value;
                            calculate();
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Column(
                    children: [
                      const Text('Milliseconds'),
                      NumberPicker(
                        value: milliseconds,
                        minValue: 0,
                        maxValue: 999,
                        step: 10,
                        zeroPad: true,
                        onChanged: (value) {
                          setState(() {
                            milliseconds = value;
                            calculate();
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
              if (calculationMode == 'Points' && bcValues != null) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                  child: Center(
                    child: Text(
                      getRecommendedTimeRange(bcValues.b, bcValues.c),
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ] else ...[
              TextField(
  key: const ValueKey('pointsField'),
  controller: inputController,
  keyboardType: TextInputType.numberWithOptions(decimal: true),
  decoration: const InputDecoration(
    labelText: 'Enter Desired Points',
    border: OutlineInputBorder(),
  ),
),
            ],
            const SizedBox(height: 24),
            Text(
              resultText,
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}


// Calculate points from time (performance)
double calculatePoints({required double time, required double b, required double c, double a = 1200}) {
  return a * math.exp(-math.exp(b - (c / time)));
}

// Calculate time from points (inverse Gompertz)
double calculateTime({required double points, required double b, required double c, double a = 1200}) {
  return c / (b - math.log(math.log(a / points)));
}

String formatTimeVerbose(double seconds) {
  final mins = seconds ~/ 60;
  final secs = (seconds % 60).floor();
  final millis = ((seconds - seconds.floor()) * 1000).round();
  List<String> parts = [];
  if (mins > 0) parts.add('$mins m');
  if (secs > 0) parts.add('$secs s');
  if (millis > 0) parts.add('$millis ms');
  if (parts.isEmpty) return '0';
  return parts.join(' ');
}

String getRecommendedTimeRange(double b, double c, {double a = 1200}) {
  final minPoints = 1; 
  final maxPoints = 1199;

  final minTime = c / (b - math.log(math.log(a / minPoints)));
  final maxTime = c / (b - math.log(math.log(a / maxPoints)));

  return 'Recommended time range: ${formatTimeVerbose(maxTime)} to ${formatTimeVerbose(minTime)}';
}
