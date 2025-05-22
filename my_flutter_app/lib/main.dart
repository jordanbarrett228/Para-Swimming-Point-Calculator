import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'EventData.dart';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:keyboard_actions/keyboard_actions.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load the JSON file as a string
  final String jsonString = await rootBundle.loadString('lib/event_data_compact.json');
  // Decode the string into a Map
  final Map<String, dynamic> jsonData = json.decode(jsonString) as Map<String, dynamic>;
  // Parse into your EventData class
  final EventData eventData = EventData.fromJson(jsonData);

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
  String? selectedGender = 'Male'; // Set default to 'Male'

  List<String> allEvents = eventToClasses.keys.toList();
  List<String> genderOptions = <String>['Male', 'Female'];

  String calculationMode = 'Points'; // or 'Time'
  final TextEditingController inputController = TextEditingController();
  String resultText = '';

  // 1. Add state variables for the pickers:
  int minutes = 0;
  int seconds = 0;
  int milliseconds = 0;

  final FocusNode _minutesFocusNode = FocusNode();
  final FocusNode _secondsFocusNode = FocusNode();
  final FocusNode _millisecondsFocusNode = FocusNode();
  final FocusNode _pointsFocusNode = FocusNode();

  // Add controllers for time fields
  final TextEditingController minutesController = TextEditingController();
  final TextEditingController secondsController = TextEditingController();
  final TextEditingController millisecondsController = TextEditingController();

  List<String> getAvailableClasses(String? event) {
    if (event == null) return <String>[];
    return eventToClasses[event]!;
  }

  BCValues? getSelectedBCValues() {
    if (selectedEvent == null || selectedClass == null || selectedGender == null) return null;
    try {
      final EventName eventEnum = stringToEventEnum(selectedEvent!);
      final SwimClass classEnum = stringToSwimClass(selectedClass!);
      final Gender genderEnum = stringToGender(selectedGender!.toLowerCase());
      return widget.eventData.getBC(eventEnum, classEnum, genderEnum);
    } catch (e) {
      return null;
    }
  }

  void calculate() {
    final BCValues? bc = getSelectedBCValues();
    if (bc == null) {
      setState(() {
        resultText = 'Please select all options.';
      });
      return;
    }
    final double b = bc.b;
    final double c = bc.c;
    final double a = 1200.0;

    try {
      if (calculationMode == 'Points') {
        final double totalSeconds = minutes * 60 + seconds + milliseconds / 1000.0;

        if (totalSeconds <= 0) {
          setState(() {
            resultText = 'Enter a valid time.';
          });
          return;
        }
        final int points = calculatePoints(time: totalSeconds, b: b, c: c, a: a);
        setState(() {
          resultText = 'Points: $points';
        });
      } else {
        final String pointsStr = inputController.text;
        final double? points = double.tryParse(pointsStr);
        if (points == null || points <= 0 || points >= a) {
          setState(() {
            resultText = 'Enter a valid points value (0 < points < $a).';
          });
          return;
        }
        final double time = calculateTime(points: points, b: b, c: c, a: a);
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

    // Initialize controllers with default values
    minutesController.text = minutes.toString();
    secondsController.text = seconds.toString();
    millisecondsController.text = milliseconds.toString();

    // Add listeners to update state and recalculate
    minutesController.addListener(() {
      final int intValue = int.tryParse(minutesController.text) ?? 0;
      final int clamped = intValue.clamp(0, 59);
      if (intValue != clamped) {
        minutesController.text = clamped.toString();
        minutesController.selection = TextSelection.fromPosition(TextPosition(offset: minutesController.text.length));
      }
      setState(() {
        minutes = clamped;
      });
      calculate();
    });
    secondsController.addListener(() {
      final int intValue = int.tryParse(secondsController.text) ?? 0;
      final int clamped = intValue.clamp(0, 59);
      if (intValue != clamped) {
        secondsController.text = clamped.toString();
        secondsController.selection = TextSelection.fromPosition(TextPosition(offset: secondsController.text.length));
      }
      setState(() {
        seconds = clamped;
      });
      calculate();
    });
    millisecondsController.addListener(() {
      final int intValue = int.tryParse(millisecondsController.text) ?? 0;
      // Clamp to 0-99 for two digits only
      final int clamped = intValue.clamp(0, 99);
      if (intValue != clamped) {
        millisecondsController.text = clamped.toString();
        millisecondsController.selection = TextSelection.fromPosition(TextPosition(offset: millisecondsController.text.length));
      }
      setState(() {
        milliseconds = clamped;
      });
      calculate();
    });
  }

  void _onInputChanged() {
  calculate();
}

  @override
  void dispose() {
    inputController.dispose();
    minutesController.dispose();
    secondsController.dispose();
    millisecondsController.dispose();
    _minutesFocusNode.dispose();
    _secondsFocusNode.dispose();
    _millisecondsFocusNode.dispose();
    _pointsFocusNode.dispose();
    super.dispose();
  }

  // Helper to build number input with done button
  Widget buildNumberInput({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    double width = 60,
  }) {
    return Column(
      children: <Widget>[
        Text(label),
        SizedBox(
          width: width,
          child: TextField(
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              border: OutlineInputBorder(),
            ),
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
            ],
            controller: controller,
            focusNode: focusNode,
            onTap: () {
              controller.selection = TextSelection(
                baseOffset: 0,
                extentOffset: controller.text.length,
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final BCValues? bcValues = getSelectedBCValues();

    // KeyboardActions config for all fields
    final keyboardConfig = KeyboardActionsConfig(
      actions: [
        KeyboardActionsItem(
          focusNode: _minutesFocusNode,
          toolbarButtons: [
            (node) => TextButton(
              onPressed: () => node.unfocus(),
              child: const Text('Done'),
            ),
          ],
        ),
        KeyboardActionsItem(
          focusNode: _secondsFocusNode,
          toolbarButtons: [
            (node) => TextButton(
              onPressed: () => node.unfocus(),
              child: const Text('Done'),
            ),
          ],
        ),
        KeyboardActionsItem(
          focusNode: _millisecondsFocusNode,
          toolbarButtons: [
            (node) => TextButton(
              onPressed: () => node.unfocus(),
              child: const Text('Done'),
            ),
          ],
        ),
        KeyboardActionsItem(
          focusNode: _pointsFocusNode,
          toolbarButtons: [
            (node) => TextButton(
              onPressed: () => node.unfocus(),
              child: const Text('Done'),
            ),
          ],
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Point Calculator')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: <Widget>[
            DropdownButtonFormField<String>(
              value: selectedEvent,
              hint: const Text('Select Event'),
              items: allEvents
                  .map((String e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (String? value) {
                setState(() {
                  selectedEvent = value;
                  final List<String> classes = getAvailableClasses(selectedEvent);
                  selectedClass = classes.isNotEmpty ? classes.first : null;
                  calculate();
                });
              },
            ),
            if (selectedEvent != null) ...<Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text('Select Class:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: getAvailableClasses(selectedEvent)
                          .map((String cls) => ChoiceChip(
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
              children: <Widget>[
                ToggleButtons(
                  isSelected: <bool>[
                    selectedGender == 'Male',
                    selectedGender == 'Female',
                  ],
                  onPressed: (int index) {
                    setState(() {
                      selectedGender = index == 0 ? 'Male' : 'Female';
                      calculate();
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  children: const <Widget>[
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
            if (bcValues != null) ...<Widget>[
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
              children: <Widget>[
                ToggleButtons(
                  isSelected: <bool>[
                    calculationMode == 'Points',
                    calculationMode == 'Time',
                  ],
                  onPressed: (int index) {
                    setState(() {
                      calculationMode = index == 0 ? 'Points' : 'Time';
                    });
                    calculate();
                  },
                  borderRadius: BorderRadius.circular(8),
                  children: const <Widget>[
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
            if (calculationMode == 'Points') ...<Widget>[
              SizedBox(
                height: 90, // or whatever fits your design
                child: KeyboardActions(
                  config: keyboardConfig,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      buildNumberInput(
                        label: 'Minutes',
                        controller: minutesController,
                        focusNode: _minutesFocusNode,
                      ),
                      const SizedBox(width: 8),
                      buildNumberInput(
                        label: 'Seconds',
                        controller: secondsController,
                        focusNode: _secondsFocusNode,
                      ),
                      const SizedBox(width: 8),
                      buildNumberInput(
                        label: 'Milliseconds',
                        controller: millisecondsController,
                        focusNode: _millisecondsFocusNode,
                        width: 70,
                      ),
                    ],
                  ),
                ),
              ),
              if (calculationMode == 'Points' && bcValues != null) ...<Widget>[
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
            ] else ...<Widget>[
              SizedBox(
                height: 70,
                child: KeyboardActions(
                  config: keyboardConfig,
                  child: TextField(
                    key: const ValueKey('pointsField'),
                    controller: inputController,
                    focusNode: _pointsFocusNode,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Enter Desired Points',
                      border: OutlineInputBorder(),
                    ),
                    onTap: () {
                      inputController.selection = TextSelection(
                        baseOffset: 0,
                        extentOffset: inputController.text.length,
                      );
                    },
                  ),
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
int calculatePoints({required double time, required double b, required double c, double a = 1200}) {
  return (a * math.exp(-math.exp(b - (c / time)))).truncate();
}

// Calculate time from points (inverse Gompertz)
double calculateTime({required double points, required double b, required double c, double a = 1200}) {
  double rawTime = c / (b - math.log(math.log(a / points)));
  // Truncate to 2 decimal places
  return (rawTime * 100).truncateToDouble() / 100;
}

String formatTimeVerbose(double seconds) {
  final int mins = seconds ~/ 60;
  final int secs = (seconds % 60).floor();
  final int millis = ((seconds - seconds.floor()) * 100).round();
  List<String> parts = <String>[];
  if (mins > 0) parts.add('$mins m');
  if (secs > 0) parts.add('$secs s');
  if (millis > 0) parts.add('$millis ms');
  if (parts.isEmpty) return '0';
  return parts.join(' ');
}

String getRecommendedTimeRange(double b, double c, {double a = 1200}) {
  final int minPoints = 1; 
  final int maxPoints = 1199;

  final double minTime = c / (b - math.log(math.log(a / minPoints)));
  final double maxTime = c / (b - math.log(math.log(a / maxPoints)));

  return 'Recommended time range: ${formatTimeVerbose(maxTime)} to ${formatTimeVerbose(minTime)}';
}
