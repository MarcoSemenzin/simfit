import 'package:flutter/material.dart';
import 'package:simfit/models/activity.dart';
import 'package:simfit/models/calories.dart';
import 'package:simfit/models/sleep.dart';
import 'package:simfit/models/steps.dart';
import 'package:simfit/server/impact.dart';

/// Provider to manage and expose daily activity-related data fetched from the IMPACT API.
/// 
/// This includes steps, calories, sleep, resting heart rate, and activities for a selected day.
/// Notifies listeners when data is loading or updated to support UI refresh.
class HomeProvider extends ChangeNotifier {
  /// List of steps recorded for the selected day.
  List<Steps> dailySteps = [];

  /// Total number of steps taken during the selected day.
  int totDailySteps = 0;

  /// List of calories data entries for the selected day.
  List<Calories> dailyCalories = [];

  /// Total calories burned during the selected day.
  int totDailyCalories = 0;

  /// List of sleep segments recorded for the selected day.
  List<Sleep> dailySleep = [];

  /// Duration of the main (longest) sleep segment in the selected day.
  Duration mainDailySleep = Duration.zero;

  /// Resting heart rate value measured during the selected day.
  int dailyRestHR = 0;

  /// List of other activities (besides steps, calories, sleep) for the selected day.
  List<Activity> dailyActivities = [];

  /// Indicates whether the daily data has been fully loaded and is ready for use.
  bool dataReady = false;

  /// Instance of the IMPACT API client used for data fetching.
  final Impact impact = Impact();

  /// Fetches and updates all daily data for the given [showDate].
  /// 
  /// Resets current data, retrieves steps, calories, sleep, resting heart rate, 
  /// and activities from the server, then marks data as ready and notifies listeners.
  Future<void> getDataOfDay(DateTime showDate) async {
    _loading();

    dailySteps = await impact.getStepsFromDay(showDate);
    totDailySteps = getTotalStepsFromDay(dailySteps);

    dailyCalories = await impact.getCaloriesFromDay(showDate);
    totDailyCalories = getTotalCaloriesFromDay(dailyCalories).toInt();

    dailySleep = await impact.getSleepsFromDay(showDate);
    mainDailySleep = getMainSleepFromDay(dailySleep);

    dailyRestHR = (await impact.getRestHRFromDay(showDate)).toInt();

    dailyActivities = await impact.getActivitiesFromDay(showDate);

    dataReady = true;
    _notifyListeners();
  }

  /// Resets all stored daily data to default empty values and sets loading state.
  void _loading() {
    dailySteps = [];
    totDailySteps = 0;

    dailyCalories = [];
    totDailyCalories = 0;

    dailySleep = [];
    mainDailySleep = Duration.zero;

    dailyRestHR = 0;

    dailyActivities = [];

    dataReady = false;
    _notifyListeners(); // Notifies listeners so the UI can reflect the loading state
  }

  /// Notifies listeners asynchronously to prevent synchronous update issues.
  void _notifyListeners() {
    Future.microtask(() => notifyListeners());
  }
}