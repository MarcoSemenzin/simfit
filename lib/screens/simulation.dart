import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:simfit/models/activity.dart';
import 'package:simfit/providers/simulation_provider.dart';
import 'package:simfit/utils/graphic_elements.dart';

/// Widget for simulating a training session and computing its effects.
///
/// Allows users to define multiple simulated activities using sliders and text fields,
/// and computes the resulting metrics using the [SimulationProvider] and a custom algorithm.
class SessionSimulation extends StatefulWidget {
  /// Named route for navigation.
  static const routename = 'SessionSimulation';

  /// Simulation provider instance containing scores and algorithm.
  final SimulationProvider simProv;

  /// Constructs the session simulation widget using historical [scores] and an [algorithm].
  ///
  /// Instantiates a new [SimulationProvider] with the given parameters.
  SessionSimulation({
    super.key,
    required Map<DateTime, Map<String, double>> scores,
    required algorithm,
  }) : simProv = SimulationProvider(scores: scores, algorithm: algorithm);

  @override
  State<SessionSimulation> createState() => _SessionSimulationState();
}

/// State class for [SessionSimulation], handling user input and simulation logic.
class _SessionSimulationState extends State<SessionSimulation> {
  /// List of user-defined simulated activity blocks.
  ///
  /// Each block contains a [TextEditingController] for duration and a slider value for heart rate.
  final List<Map<String, dynamic>> _activityBlocks = [];

  @override
  void initState() {
    super.initState();
    _addActivityBlock(); // Add the first activity block by default.
  }

  /// Adds a new activity block to the list, with default HR slider and empty text field.
  void _addActivityBlock() {
    _activityBlocks.add({
      'controller': TextEditingController(),
      'sliderValue': widget.simProv.algorithm.restHR + 10.0,
    });
  }

  /// Removes the most recently added activity block, if more than one is present.
  void _removeActivityBlock() {
    if (_activityBlocks.length > 1) {
      _activityBlocks.removeLast();
    }
  }

  /// Runs the simulation based on current input in all activity blocks.
  ///
  /// Validates input, builds [Activity] objects, and triggers score computation.
  /// Displays an error snackbar if input is invalid.
  Future<void> _runSimulation(BuildContext context) async {
    final List<Activity> simActivities = [];

    for (var block in _activityBlocks) {
      final controller = block['controller'] as TextEditingController;
      final sliderValue = block['sliderValue'] as double;

      if (controller.text.trim().isEmpty) {
        _showSnackBar(context, 'Some activity parameters are empty!');
        return;
      }

      final minutes = int.tryParse(controller.text) ?? 0;

      simActivities.add(Activity(
        activityName: 'Simulated activity #${_activityBlocks.indexOf(block) + 1}',
        avgHR: sliderValue.toInt(),
        calories: 0,
        distance: 0,
        duration: Duration(minutes: minutes),
        steps: 0,
        zonesHR: [],
        avgSpeed: 0.0,
        vo2Max: 0.0,
        elevationGain: 0.0,
        startingTime: DateUtils.dateOnly(DateTime.now()),
      ));
    }

    await widget.simProv.computeSimulatedScores(simActivities);
  }

  /// Displays a [SnackBar] with a warning [message].
  ///
  /// Used for showing validation errors to the user.
  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Center(
          child: Text(
            message,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SimulationProvider>.value(
      value: widget.simProv,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Session Simulation',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
          ),
          centerTitle: true,
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Theme.of(context).secondaryHeaderColor,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'Plan the physical activities you want to do today and simulate your performance score.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),

                // Dynamically generated list of activity blocks
                ..._activityBlocks.map((block) {
                  final controller = block['controller'] as TextEditingController;
                  final sliderValue = block['sliderValue'] as double;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Label for the activity number
                        Text(
                          'Activity #${_activityBlocks.indexOf(block) + 1}',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),

                        // Text input for duration of the activity in minutes
                        TextField(
                          controller: controller,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Duration (minutes)',
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Label and value for session intensity slider
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Session intensity (avg bpm)', style: TextStyle(fontSize: 16)),
                            Text('${sliderValue.toInt()} bpm', style: const TextStyle(fontSize: 16)),
                          ],
                        ),

                        // Slider to select average heart rate for the activity
                        Slider(
                          value: sliderValue,
                          min: widget.simProv.algorithm.restHR + 10.0,
                          max: widget.simProv.algorithm.maxHR,
                          onChanged: (newValue) {
                            setState(() => block['sliderValue'] = newValue);
                          },
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 10),

                // Row of control buttons: add, remove, and run simulation
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Button to add a new activity block
                    ElevatedButton(
                      onPressed: () => setState(_addActivityBlock),
                      style: _buttonStyle(context),
                      child: const Icon(Icons.add),
                    ),
                    const SizedBox(width: 8),

                    // Button to remove the last activity block
                    ElevatedButton(
                      onPressed: () => setState(_removeActivityBlock),
                      style: _buttonStyle(context),
                      child: const Icon(Icons.remove),
                    ),
                    const SizedBox(width: 8),

                    // Button to run the simulation and compute training scores
                    ElevatedButton(
                      onPressed: () => _runSimulation(context),
                      style: _buttonStyle(context),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          'RUN SIMULATION',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // Displays simulation results when available
                Consumer<SimulationProvider>(
                  builder: (context, provider, _) {
                    if (provider.isComputingScores) {
                      return const Column(
                        children: [
                          SizedBox(height: 50),
                          CircularProgressIndicator(
                            color: Colors.blue,
                            strokeWidth: 5,
                          ),
                        ],
                      );
                    }

                    if (provider.simulatedScores.isEmpty) {
                      return const SizedBox.shrink(); // Show nothing if no scores
                    }

                    return Column(
                      children: [
                        // Title for simulated training scores section
                        const Text(
                          'Training scores post simulation',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                        ),
                        const SizedBox(height: 10),

                        // TRIMP score visualization
                        TRIMPDisplay(index: provider.simulatedScores['TRIMP'] ?? 0.0),

                        // Display ACL score
                        Text(
                          'Acute Training Load: ${provider.simulatedScores['ACL']?.toStringAsFixed(2) ?? '0.00'}',
                          style: const TextStyle(color: Colors.red, fontSize: 18),
                        ),

                        // Display CTL score
                        Text(
                          'Chronic Training Load: ${provider.simulatedScores['CTL']?.toStringAsFixed(2) ?? '0.00'}',
                          style: const TextStyle(color: Colors.blue, fontSize: 18),
                        ),

                        // Display TSB score with emoji indicator
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Training Stress Balance: ${provider.simulatedScores['TSB']?.toStringAsFixed(2) ?? '0.00'}',
                              style: const TextStyle(color: Colors.deepPurple, fontSize: 18),
                            ),
                            const SizedBox(width: 5),
                            PerformanceEmoji(tsb: provider.simulatedScores['TSB'] ?? 0.0),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  ButtonStyle _buttonStyle(BuildContext context) {
    return ElevatedButton.styleFrom(
      backgroundColor: Theme.of(context).primaryColor,
      foregroundColor: Theme.of(context).secondaryHeaderColor,
    );
  }
}