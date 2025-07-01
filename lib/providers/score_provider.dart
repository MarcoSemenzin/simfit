import 'package:flutter/material.dart';

/// A provider class for managing and notifying changes in the selected day's training scores.
///
/// This class is used to store and update the scores (e.g., TRIMP, ACL, CTL, TSB)
/// of a specific day within a mesocycle. It notifies listeners when a new day
/// and its corresponding scores are selected, triggering UI updates.
class ScoreProvider extends ChangeNotifier {

  /// The currently selected day for which training scores are shown.
  DateTime day;

  /// A map containing the training scores for the selected day.
  /// Keys include: 'TRIMP', 'ACL', 'CTL', 'TSB'.
  Map<String, double> scoresOfDay;

  /// Creates a [ScoreProvider] with an initial day and its corresponding scores.
  ScoreProvider({
    required this.day,
    required this.scoresOfDay,
  });

  /// Updates the provider with a new day and its associated scores,
  /// then notifies all listeners to trigger UI updates.
  void setNewScoresOfDay(DateTime newDay, Map<String, double> scoresOfNewDay) {
    day = newDay;
    scoresOfDay = scoresOfNewDay;
    notifyListeners();
  }
}