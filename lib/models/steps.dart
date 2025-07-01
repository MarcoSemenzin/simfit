import 'package:intl/intl.dart';

/// Represents a single steps count entry at a specific time.
class Steps {
  /// The timestamp of the step measurement.
  final DateTime timestamp;

  /// The number of steps recorded at [timestamp].
  final int value;

  /// Creates a [Steps] instance with the given [timestamp] and [value].
  Steps({
    required this.timestamp,
    required this.value,
  });

  /// Constructs a [Steps] object from JSON data.
  ///
  /// The [date] is a string in yyyy-MM-dd format, and [json] must contain:
  /// - "time" in HH:mm:ss format,
  /// - "value" as a stringified integer.
  Steps.fromJson(String date, Map<String, dynamic> json)
      : timestamp = DateFormat('yyyy-MM-dd HH:mm:ss')
            .parse('$date ${json["time"]}'),
        value = int.tryParse(json["value"] ?? '0') ?? 0;
}

/// Returns the total number of steps from a list of [Steps] entries.
///
/// If [dataSteps] is empty, returns 0.
int getTotalStepsFromDay(List<Steps> dataSteps) {
  if (dataSteps.isEmpty) return 0;
  return dataSteps.map((step) => step.value).reduce((a, b) => a + b);
}