import 'package:intl/intl.dart';

/// Represents a calorie burn entry at a specific timestamp.
class Calories {
  /// The time at which the calories were recorded.
  final DateTime timestamp;

  /// The number of calories burned at [timestamp].
  final double value;

  /// Creates a [Calories] object with the given [timestamp] and [value].
  Calories({
    required this.timestamp,
    required this.value,
  });

  /// Constructs a [Calories] instance from JSON data.
  ///
  /// [date] is expected in yyyy-MM-dd format.
  /// [json] must contain:
  /// - "time" in HH:mm:ss format,
  /// - "value" as a number (int or double, string is also accepted).
  Calories.fromJson(String date, Map<String, dynamic> json)
      : timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').parse('$date ${json["time"]}'),
        value = double.tryParse(json["value"].toString()) ?? 0.0;
}

/// Returns the total calories burned from a list of [Calories] entries.
///
/// If the list is empty, returns 0.0.
double getTotalCaloriesFromDay(List<Calories> dataCals) {
  if (dataCals.isEmpty) return 0.0;
  return dataCals.map((cals) => cals.value).reduce((a, b) => a + b);
}