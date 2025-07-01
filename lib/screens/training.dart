import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:simfit/models/activity.dart';
import 'package:simfit/navigation/navtools.dart';
import 'package:simfit/providers/score_provider.dart';
import 'package:simfit/providers/user_provider.dart';
import 'package:simfit/screens/help.dart';
import 'package:simfit/screens/simulation.dart';
import 'package:simfit/server/impact.dart';
import 'package:simfit/utils/algorithm.dart';
import 'package:simfit/utils/graphic_elements.dart';

/// The main widget representing the Training Load page of the application.
/// It fetches the user's training activities and resting heart rate (restHR),
/// and displays different UIs depending on the mesocycle state.
class Training extends StatefulWidget {
  /// Route name used for navigation.
  static const routename = 'Training';

  /// Constructor for Training widget.
  const Training({super.key});

  @override
  TrainingState createState() => TrainingState();
}

/// The state class for [Training] which manages data fetching and UI rendering.
class TrainingState extends State<Training> {
  /// Instance of the Impact class responsible for fetching activity and restHR data.
  final Impact impact = Impact();

  /// The last date to be considered for data fetching, defaulting to yesterday.
  DateTime lastDate = DateUtils.dateOnly(DateTime.now().subtract(const Duration(days: 1)));

  /// Future used to fetch data once during widget initialization.
  late Future<Map<String, dynamic>> _fetchDataFuture;

  /// Reference to the user provider that holds user-specific data like mesocycle.
  late UserProvider _userProvider;

  /// Indicates if today is the start of the mesocycle.
  bool isMesocycleStartToday = false;

  /// Indicates if the mesocycle is set to start in the future.
  bool isMesocycleStartFuture = false;

  /// Called when the widget is first inserted into the widget tree.
  /// Initializes the provider, determines mesocycle state, and sets up the data fetch future.
  @override
  void initState() {
    super.initState();
    _userProvider = Provider.of<UserProvider>(context, listen: false);

    DateTime? startDate = _userProvider.mesocycleStartDate;
    DateTime? endDate = _userProvider.mesocycleEndDate;

    if (startDate != null) {
      DateTime today = DateUtils.dateOnly(DateTime.now());

      // Check if the mesocycle starts today or in the future.
      if (DateUtils.dateOnly(startDate) == today) {
        isMesocycleStartToday = true;
      } else if (startDate.isAfter(today)) {
        isMesocycleStartFuture = true;
      }
    }

    // Update lastDate if mesocycle endDate is in the past.
    if (endDate != null && endDate.isBefore(DateUtils.dateOnly(DateTime.now()))) {
      lastDate = endDate;
    }

    // Fetch data during init
    _fetchDataFuture = _fetchData(context);
  }

  /// Asynchronously fetches activity data and resting heart rate from the Impact service.
  /// 
  /// Returns a map containing:
  /// - 'activities': A map of DateTime to list of activities.
  /// - 'restHR': A double representing resting heart rate.
  Future<Map<String, dynamic>> _fetchData(BuildContext context) async {
    try {
      // Simulate network latency (e.g., API call delay)
      await Future.delayed(const Duration(seconds: 2));

      // Define the start date for the query
      DateTime start = _userProvider.mesocycleStartDate ??
          DateUtils.dateOnly(DateTime.now().subtract(const Duration(days: 30)));

      // Fetch activity and heart rate data
      final Map<DateTime, List<Activity>> activities = await impact.getActivitiesFromDateRange(
        start,
        lastDate,
      );
      final double restHR = await impact.getRestHRFromDay(lastDate);

      return {
        'activities': activities,
        'restHR': restHR,
      };
    } catch (e) {
      throw Exception('Failed to fetch data: $e');
    }
  }

  /// Navigates to the Help page.
  void _toHelpPage(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => const Help()));
  }

  /// Builds the main UI of the Training page.
  /// Displays a loading indicator, error message, or appropriate content
  /// depending on the FutureBuilder state and mesocycle status.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Training Load',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Theme.of(context).secondaryHeaderColor,
        actions: [
          // Help icon that navigates to Help page
          Padding(
            padding: const EdgeInsets.only(right: 5),
            child: IconButton(
              icon: Icon(Icons.help_outline_rounded,
                  color: Theme.of(context).secondaryHeaderColor, size: 28),
              tooltip: 'Help',
              onPressed: () => _toHelpPage(context),
            ),
          ),
        ],
      ),

      // Body of the page managed by a FutureBuilder to handle asynchronous loading of training data
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // While loading, show a spinner
            return Center(
              child: CircularProgressIndicator(
                strokeWidth: 5,
                color: Theme.of(context).primaryColor,
              ),
            );
          } else if (snapshot.hasError) {
            // On error, show message
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            // No data to show
            return const Center(child: Text('No data available'));
          } else {
            // Show appropriate UI depending on mesocycle state
            if (isMesocycleStartToday) {
              return _buildMesocycleStartTodayUI(snapshot.data!['restHR']);
            } else if (isMesocycleStartFuture) {
              return _buildMesocycleStartFutureUI();
            } else {
              return _buildTrainingLoadUI(snapshot.data!);
            }
          }
        },
      ),

      // Navigation drawer on the left
      drawer: const NavDrawer(),
    );
  }

  /// Builds the UI displayed when the mesocycle starts today.
  /// It encourages the user to simulate their first training session
  /// by creating an `Algorithm` instance (based on user parameters and resting HR),
  /// and provides a button to navigate to the simulation page.
  Widget _buildMesocycleStartTodayUI(double restHR) {
    Algorithm algorithm = Algorithm(
      gender: _userProvider.gender ?? 'male',
      age: _userProvider.age ?? 0,
      rHR: restHR,
      mesoLen: _userProvider.mesocycleLength ?? 42,
      daysFromMesoStart: 1,
    );
    Map<DateTime, Map<String, double>> mesocycleScores = {};

    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Your training mesocycle starts today! You can try to simulate your first training session.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
            ElevatedButton(
              onPressed: () {
                _toSimulationPage(
                  context,
                  mesocycleScores,
                  algorithm,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Theme.of(context).secondaryHeaderColor,
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 5, vertical: 10),
                child: Text(
                  'SIMULATE TRAINING',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the UI shown when the mesocycle start date is in the future.
  /// It simply informs the user of the upcoming start date.
  Widget _buildMesocycleStartFutureUI() {
    DateTime startDate = _userProvider.mesocycleStartDate!;
    String startDateString =
        '${startDate.day.toString().padLeft(2, '0')}/${startDate.month.toString().padLeft(2, '0')}';

    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'Your training mesocycle will start on $startDateString',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  /// Builds the UI for displaying the training load overview of the current mesocycle.
  /// It processes user and activity data to compute training scores (TRIMP, ACL, CTL, TSB)
  /// using the `Algorithm` class, and visualizes them using various widgets.
  /// A button allows the user to simulate a future training session unless the mesocycle has ended.
  Widget _buildTrainingLoadUI(Map<String, dynamic> data) {
    Map<DateTime, List<Activity>> activities = data['activities'];
    double restHR = data['restHR'];

    // Calculate how many days have passed since the mesocycle started
    int dfms = ((lastDate.difference(_userProvider.mesocycleStartDate!).inHours) / 24).round() + 1;

    // Create algorithm instance with current user and session data
    Algorithm algorithm = Algorithm(
      gender: _userProvider.gender ?? 'male',
      age: _userProvider.age ?? 0,
      rHR: restHR,
      mesoLen: _userProvider.mesocycleLength ?? 42,
      daysFromMesoStart: dfms,
    );

    // Compute mesocycle scores for all days up to lastDate
    Map<DateTime, Map<String, double>> mesocycleScores =
        algorithm.computeScoresOfMesocycle(lastDate, activities);

    // Provide scores for the current (last) training day
    ScoreProvider scoreProvider = ScoreProvider(
      day: lastDate,
      scoresOfDay: mesocycleScores[lastDate]!,
    );

    return SafeArea(
      child: SingleChildScrollView(
        child: ChangeNotifierProvider<ScoreProvider>(
          create: (context) => scoreProvider,
          builder: (context, child) => Column(
            children: [
              // Displays the full mesocycle plot
              PlotContainer(
                scores: mesocycleScores,
                scoreProvider: scoreProvider,
              ),
              const SizedBox(height: 20),

              // Displays the scores of the selected training day
              Consumer<ScoreProvider>(
                builder: (context, provider, child) {
                  return Column(
                    children: [
                      Text(
                        'Training scores of ${provider.day.day.toString().padLeft(2, '0')}/${provider.day.month.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 5),
                      TRIMPDisplay(
                        index: provider.scoresOfDay['TRIMP']!,
                      ),
                      Text(
                        'Acute Training Load: ${provider.scoresOfDay['ACL']!.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        'Chronic Training Load: ${provider.scoresOfDay['CTL']!.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 18,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Training Stress Balance: ${provider.scoresOfDay['TSB']!.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.deepPurple,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(width: 5),
                          PerformanceEmoji(tsb: provider.scoresOfDay['TSB']!),
                        ],
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),

              // Button to simulate a training session or show a warning if the mesocycle has ended
              ElevatedButton(
                onPressed: () {
                  if (lastDate.isBefore(DateUtils.dateOnly(
                      DateTime.now().subtract(const Duration(days: 1))))) {
                    // Show warning if the mesocycle is over
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Center(
                          child: Text(
                            'Your mesocycle ended on ${lastDate.day.toString().padLeft(2, '0')}/${lastDate.month.toString().padLeft(2, '0')}!',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  } else {
                    // Navigate to simulation page
                    _toSimulationPage(
                      context,
                      mesocycleScores,
                      algorithm,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Theme.of(context).secondaryHeaderColor,
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5, vertical: 10),
                  child: Text(
                    'SIMULATE TRAINING',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  /// Navigates to the training session simulation page,
  /// passing along the current algorithm and computed scores.
  void _toSimulationPage(
    BuildContext context,
    Map<DateTime, Map<String, double>> mesocycleScores,
    Algorithm algorithm,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SessionSimulation(
          scores: mesocycleScores,
          algorithm: algorithm,
        ),
      ),
    );
  }
}

/// A container widget that displays a plot of training load and performance scores.
/// Shows a title, a legend for the score types (ACL, CTL, TSB),
/// and renders a custom plot if there is enough data.
class PlotContainer extends StatelessWidget {
  /// Map containing scores indexed by date.
  final Map<DateTime, Map<String, double>> scores;

  /// Provider managing selected score state or interaction.
  final ScoreProvider scoreProvider;

  /// Creates a PlotContainer with given scores and score provider.
  const PlotContainer({
    super.key,
    required this.scores,
    required this.scoreProvider,
  });

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsive sizing.
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // If there's only one score, return an empty placeholder of 25% screen height
    if (scores.length == 1) {
      return SizedBox(height: screenHeight * 0.25);
    }

    // Otherwise, return the full plot layout
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Title text for the plot section
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          child: Text(
            'Plot of the training load and performance',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),

        // Legend showing the meaning of each colored line (ACL, CTL, TSB)
        _buildLegend(),

        // Main plot container showing the CustomPlot
        Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 10, right: 10),
          child: SizedBox(
            width: screenWidth * 0.9,
            height: screenHeight * 0.4,
            child: CustomPlot(
              scores: scores,
              scoreProvider: scoreProvider,
            ),
          ),
        ),

        // Instructional text for interacting with the plot
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Click on data points in the chart to display their values below.',
            style: TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  /// Builds the legend row displaying color codes for ACL, CTL, and TSB.
  Widget _buildLegend() {
    return const Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _LegendItem(color: Colors.red, label: 'ACL'),
          SizedBox(width: 10),
          _LegendItem(color: Colors.blue, label: 'CTL'),
          SizedBox(width: 10),
          _LegendItem(color: Colors.deepPurple, label: 'TSB'),
        ],
      ),
    );
  }
}

/// A reusable widget to display a legend item with a colored square and a label.
class _LegendItem extends StatelessWidget {
  /// Color of the legend square.
  final Color color;

  /// Text label next to the square.
  final String label;

  /// Constructs a legend item with specified color and label.
  const _LegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Colored square
        Container(
          width: 12,
          height: 12,
          color: color,
          margin: const EdgeInsets.only(right: 4),
        ),

        // Label next to the square
        Text(
          label,
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }
}