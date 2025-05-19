class EventData {
  final Map<EventName, Map<SwimClass, Map<Gender, BCValues>>> events;

  EventData(this.events);

  factory EventData.fromJson(Map<String, dynamic> json) {
    final Map<EventName, Map<SwimClass, Map<Gender, BCValues>>> data = <EventName, Map<SwimClass, Map<Gender, BCValues>>>{};
    final Map<String, dynamic> eventData = json['event_data'] as Map<String, dynamic>;

    for (final MapEntry<String, dynamic> eventEntry in eventData.entries) {
      final EventName eventEnum = stringToEventEnum(eventEntry.key);
      final Map<SwimClass, Map<Gender, BCValues>> classMap = <SwimClass, Map<Gender, BCValues>>{};

      for (final MapEntry<String, dynamic> classEntry in (eventEntry.value as Map<String, dynamic>).entries) {
        final SwimClass classEnum = stringToSwimClass(classEntry.key);
        final Map<Gender, BCValues> genderMap = <Gender, BCValues>{};

        for (final MapEntry<String, dynamic> genderEntry in (classEntry.value as Map<String, dynamic>).entries) {
          final Gender genderEnum = stringToGender(genderEntry.key);
          genderMap[genderEnum] = BCValues.fromJson(genderEntry.value);
        }

        classMap[classEnum] = genderMap;
      }

      data[eventEnum] = classMap;
    }

    return EventData(data);
  }

  BCValues? getBC(EventName event, SwimClass sClass, Gender gender) {
    return events[event]?[sClass]?[gender];
  }
}

enum EventName {
  freestyle50m('50 m Freestyle'),
  freestyle100m('100 m Freestyle'),
  freestyle200m('200 m Freestyle'),
  freestyle400m('400 m Freestyle'),
  freestyle800m('800 m Freestyle'),
  freestyle1500m('1500 m Freestyle'),

  backstroke50m('50 m Backstroke'),
  backstroke100m('100 m Backstroke'),
  backstroke200m('200 m Backstroke'),

  breaststroke50m('50 m Breaststroke'),
  breaststroke100m('100 m Breaststroke'),
  breaststroke200m('200 m Breaststroke'),

  butterfly50m('50 m Butterfly'),
  butterfly100m('100 m Butterfly'),
  butterfly200m('200 m Butterfly'),

  im150m('150 m IM'),
  im200m('200 m IM'),
  im400m('400 m IM');

  final String label;

  const EventName(this.label);

  @override
  String toString() => label;

  static EventName? fromLabel(String label) {
    return EventName.values.firstWhere(
      (EventName e) => e.label == label,
      orElse: () => throw ArgumentError('Unknown label: $label'),
    );
  }
}


enum SwimClass {
  S1, S2, S3, S4, S5, S6, S7, S8, S9, S10, S11, S12, S13, S14,
  SB1, SB2, SB3, SB4, SB5, SB6, SB7, SB8, SB9, SB11, SB12, SB13, SB14,
  SM1, SM2, SM3, SM4, SM5, SM6, SM7, SM8, SM9, SM10, SM11, SM12, SM13, SM14,
}

enum Gender { male, female }

class BCValues {
  final double b;
  final double c;

  BCValues({required this.b, required this.c});

  factory BCValues.fromJson(Map<String, dynamic> json) {
    return BCValues(
      b: (json['b'] as num).toDouble(),
      c: (json['c'] as num).toDouble(),
    );
  }
}
final Map<String, List<String>> eventToClasses = <String, List<String>>{
  '50 m Freestyle': <String>['S1', 'S2', 'S3', 'S4', 'S5', 'S6', 'S7', 'S8', 'S9', 'S10', 'S11', 'S12', 'S13'],
  '100 m Freestyle': <String>['S1', 'S2', 'S3', 'S4', 'S5', 'S6', 'S7', 'S8', 'S9', 'S10', 'S11', 'S12', 'S13', 'S14'],
  '200 m Freestyle': <String>['S1', 'S2', 'S3', 'S4', 'S5', 'S6', 'S7', 'S8', 'S9', 'S10', 'S11', 'S12', 'S13', 'S14'],
  '400 m Freestyle': <String>['S6', 'S7', 'S8', 'S9', 'S10', 'S11', 'S12', 'S13', 'S14'],
  '800 m Freestyle': <String>['S6', 'S7', 'S8', 'S9', 'S10', 'S11', 'S12', 'S13', 'S14'],
  '1500 m Freestyle': <String>['S6', 'S7', 'S8', 'S9', 'S10', 'S11', 'S12', 'S13', 'S14'],

  '50 m Backstroke': <String>['S1', 'S2', 'S3', 'S4', 'S5', 'S6', 'S7', 'S8', 'S9', 'S10', 'S11', 'S12', 'S13'],
  '100 m Backstroke': <String>['S1', 'S2', 'S3', 'S4', 'S5', 'S6', 'S7', 'S8', 'S9', 'S10', 'S11', 'S12', 'S13', 'S14'],
  '200 m Backstroke': <String>['S6', 'S7', 'S8', 'S9', 'S10', 'S11', 'S12', 'S13', 'S14'],

  '50 m Breaststroke': <String>['SB1', 'SB2', 'SB3', 'SB4', 'SB5', 'SB6', 'SB7', 'SB8', 'SB9', 'SB11', 'SB12', 'SB13'],
  '100 m Breaststroke': <String>['SB1', 'SB2', 'SB3', 'SB4', 'SB5', 'SB6', 'SB7', 'SB8', 'SB9', 'SB11', 'SB12', 'SB13', 'SB14'],
  '200 m Breaststroke': <String>['SB4', 'SB5', 'SB6', 'SB7', 'SB8', 'SB9', 'SB11', 'SB12', 'SB13', 'SB14'],

  '50 m Butterfly': <String>['S1', 'S2', 'S3', 'S4', 'S5', 'S6', 'S7', 'S8', 'S9', 'S10', 'S11', 'S12', 'S13'],
  '100 m Butterfly': <String>['S5', 'S6', 'S7', 'S8', 'S9', 'S10', 'S11', 'S12', 'S13', 'S14'],
  '200 m Butterfly': <String>['S8', 'S9', 'S10', 'S11', 'S12', 'S13', 'S14'],

  '150 m IM': <String>['SM1', 'SM2', 'SM3', 'SM4'],
  '200 m IM': <String>['SM3', 'SM4', 'SM5', 'SM6', 'SM7', 'SM8', 'SM9', 'SM10', 'SM11', 'SM12', 'SM13', 'SM14'],
  '400 m IM': <String>['SM8', 'SM9', 'SM10', 'SM11', 'SM12', 'SM13', 'SM14'],
};


EventName stringToEventEnum(String str) {
  switch (str) {
    case '50 m Freestyle': return EventName.freestyle50m;
    case '100 m Freestyle': return EventName.freestyle100m;
    case '200 m Freestyle': return EventName.freestyle200m;
    case '400 m Freestyle': return EventName.freestyle400m;
    case '800 m Freestyle': return EventName.freestyle800m;
    case '1500 m Freestyle': return EventName.freestyle1500m;

    case '50 m Backstroke': return EventName.backstroke50m;
    case '100 m Backstroke': return EventName.backstroke100m;
    case '200 m Backstroke': return EventName.backstroke200m;

    case '50 m Breaststroke': return EventName.breaststroke50m;
    case '100 m Breaststroke': return EventName.breaststroke100m;
    case '200 m Breaststroke': return EventName.breaststroke200m;

    case '50 m Butterfly': return EventName.butterfly50m;
    case '100 m Butterfly': return EventName.butterfly100m;
    case '200 m Butterfly': return EventName.butterfly200m;

    case '150 m IM': return EventName.im150m;
    case '200 m IM': return EventName.im200m;
    case '400 m IM': return EventName.im400m;

    default: throw Exception('Unknown event name: $str');
  }
}

String swimClassToString(SwimClass sClass) => sClass.name;
SwimClass stringToSwimClass(String str) {
  try {
    return SwimClass.values.firstWhere((SwimClass e) => e.name == str);
  } catch (e) {
    throw Exception('Unknown swim class: $str');
  }
}

String genderToString(Gender g) => g.name;
Gender stringToGender(String str) => Gender.values.firstWhere((Gender e) => e.name == str.toLowerCase());