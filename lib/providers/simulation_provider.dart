import 'package:flutter/material.dart';
import 'package:simfit/models/activity.dart';
import 'package:simfit/utils/algorithm.dart';

/// Provider class to manage simulation data for training sessions.
///
/// It holds the currently selected simulation date, computed simulation scores,
/// and uses a provided algorithm to compute scores based on new activities.
class SimulationProvider extends ChangeNotifier {
  /// The date for which the simulation is computed.
  DateTime simDate = DateUtils.dateOnly(DateTime.now());

  /// Holds the computed scores for the simulation on [simDate].
  /// The key is the metric name, and the value is the score.
  Map<String, double> simulatedScores = {};

  /// Historical scores for previous dates.
  /// Maps each date to a map of metric scores.
  final Map<DateTime, Map<String, double>> scores;

  /// Algorithm instance used to compute scores based on activities and past data.
  final Algorithm algorithm;

  /// Boolean flag representing the computing of the simulated scores.
  bool isComputingScores = false;

  /// Constructor requires historical scores and an algorithm instance.
  SimulationProvider({
    required this.scores,
    required this.algorithm,
  });

  /// Computes the simulated scores for the currently selected [simDate]
  /// based on the provided list of simulated activities [simActivities].
  ///
  /// This method simulates a loading delay of 1 second to represent
  /// computation or network wait time, clears previous scores,
  /// then updates [simulatedScores] with new calculated values and notifies listeners.
  Future<void> computeSimulatedScores(List<Activity> simActivities) async {
    _loading(); // Provide loading feedback by clearing previous scores.

    // Simulate a delay to mimic computation/network latency.
    await Future.delayed(const Duration(seconds: 1));

    // Compute new simulated scores using the algorithm provided.
    simulatedScores = algorithm.computeScoresOfNewDay(simDate, simActivities, scores);

    // Set the computing flag to false.
    isComputingScores = false;

    // Notify UI or listeners about the updated scores.
    notifyListeners();
  }

  /// Internal method to clear simulated scores, activate loading flag and notify listeners.
  ///
  /// Typically called before starting a new computation to provide
  /// loading UI feedback to users.
  void _loading() {
    simulatedScores.clear();
    isComputingScores = true;
    notifyListeners();
  }
}