import 'package:intl/intl.dart';

/// Represents a sleep session for a specific day.
class Sleep {
  /// The calendar day associated with this sleep entry.
  final DateTime day;

  /// The total duration of the sleep.
  final Duration duration;

  /// The sleep efficiency (usually 0–100%).
  final int efficiency;

  /// Whether this entry represents the main sleep session of the day.
  final bool mainSleep;

  /// Creates a [Sleep] object with all required properties.
  Sleep({
    required this.day,
    required this.duration,
    required this.efficiency,
    required this.mainSleep,
  });

  /// Constructs a [Sleep] instance from JSON data.
  ///
  /// [date] is expected in yyyy-MM-dd format.
  /// [json] must contain:
  /// - "duration" in milliseconds,
  /// - "efficiency" as an integer,
  /// - "mainSleep" as a boolean.
  Sleep.fromJson(String date, Map<String, dynamic> json)
      : day = DateFormat('yyyy-MM-dd').parse(date),
        duration = Duration(milliseconds: (json["duration"] ?? 0).toInt()),
        efficiency = (json["efficiency"] ?? 0).toInt(),
        mainSleep = json["mainSleep"] ?? false;
}

/// Returns the [Duration] of the main sleep session from the given list.
///
/// If no main sleep is found or the list is empty, returns zero-Duration object.
Duration getMainSleepFromDay(List<Sleep> dataSleep) {
  for (var sleep in dataSleep) {
    if (sleep.mainSleep) {
      return sleep.duration;
    }
  }
  return Duration.zero;
}