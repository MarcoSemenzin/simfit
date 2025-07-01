import 'package:intl/intl.dart';

/// Represents a heart rate (HR) measurement at a specific timestamp.
class HR {
  /// The timestamp when the heart rate was recorded.
  final DateTime timestamp;

  /// The heart rate value in beats per minute (BPM).
  final int value;

  /// Creates an [HR] instance with the given [timestamp] and [value].
  HR({
    required this.timestamp,
    required this.value,
  });

  /// Constructs an [HR] object from JSON data.
  ///
  /// [date] is expected in yyyy-MM-dd format, and [json] must contain:
  /// - "time" in HH:mm:ss format,
  /// - "value" as an integer.
  HR.fromJson(String date, Map<String, dynamic> json)
      : timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').parse('$date ${json["time"]}'),
        value = (json["value"] ?? 0).toInt();
}

/// Computes basic statistics (average, min, max) for a list of HR values.
///
/// Returns a map with keys 'avg', 'min', and 'max', or an empty map if [dataHR] is empty.
Map<String, dynamic> getHRStatisticsFromDay(List<HR> dataHR) {
  if (dataHR.isEmpty) return {};

  final values = dataHR.map((hr) => hr.value);
  final avg = values.reduce((a, b) => a + b) / dataHR.length;
  final min = values.reduce((a, b) => a < b ? a : b);
  final max = values.reduce((a, b) => a > b ? a : b);

  return {
    'avg': avg,
    'min': min,
    'max': max,
  };
}