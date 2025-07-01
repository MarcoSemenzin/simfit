import 'package:intl/intl.dart';

/// Represents a physical activity session with various metrics.
class Activity {
  /// Name of the activity (e.g., "Running", "Cycling").
  final String activityName;

  /// Average heart rate during the activity (in BPM).
  final int avgHR;

  /// Total calories burned during the activity.
  final int calories;

  /// Distance covered in kilometers (or the unit used by the source).
  final double distance;

  /// Duration of the activity.
  final Duration duration;

  /// Total number of steps taken during the activity.
  final int steps;

  /// List of heart rate zones and minutes spent in each.
  final List<HRZone> zonesHR;

  /// Average speed during the activity.
  final double avgSpeed;

  /// Estimated VO2 max during the activity.
  final double vo2Max;

  /// Total elevation gain during the activity (in meters).
  final double elevationGain;

  /// Start time of the activity.
  final DateTime startingTime;

  /// Creates an [Activity] instance with all required fields.
  Activity({
    required this.activityName,
    required this.avgHR,
    required this.calories,
    required this.distance,
    required this.duration,
    required this.steps,
    required this.zonesHR,
    required this.avgSpeed,
    required this.vo2Max,
    required this.elevationGain,
    required this.startingTime,
  });

  /// Parses an [Activity] object from JSON.
  ///
  /// [date] should be in yyyy-MM-dd format.
  /// [json] should include keys like "time", "activityName", "duration", etc.
  Activity.fromJson(String date, Map<String, dynamic> json)
      : activityName = json["activityName"] ?? '',
        avgHR = (json["averageHeartRate"] ?? 0).toInt(),
        calories = (json["calories"] ?? 0).toInt(),
        distance = (json["distance"] ?? 0).toDouble(),
        duration = Duration(milliseconds: (json["duration"] ?? 0).toInt()),
        steps = (json["steps"] ?? 0).toInt(),
        zonesHR = (json["heartRateZones"] as List<dynamic>? ?? [])
            .map((zone) => HRZone.fromJson(zone))
            .toList(),
        avgSpeed = (json["speed"] ?? 0).toDouble(),
        vo2Max = (json["vo2Max"]?["vo2Max"] ?? 0.0).toDouble(),
        elevationGain = (json["elevationGain"] ?? 0).toDouble(),
        startingTime = DateFormat('yyyy-MM-dd HH:mm:ss').parse('$date ${json["time"]}');
}

/// Represents a heart rate training zone with time spent in it.
class HRZone {
  /// The name of the heart rate zone (e.g., "Fat Burn", "Peak").
  final String name;

  /// Minimum heart rate threshold for the zone.
  final int minHR;

  /// Maximum heart rate threshold for the zone.
  final int maxHR;

  /// Duration spent in this heart rate zone (in minutes).
  final int minutes;

  /// Creates an [HRZone] with the given parameters.
  HRZone({
    required this.name,
    required this.minHR,
    required this.maxHR,
    required this.minutes,
  });

  /// Parses an [HRZone] object from JSON.
  HRZone.fromJson(Map<String, dynamic> json)
      : name = json["name"] ?? '',
        minHR = (json["min"] ?? 0).toInt(),
        maxHR = (json["max"] ?? 0).toInt(),
        minutes = (json["minutes"] ?? 0).toInt();
}