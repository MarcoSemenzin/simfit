import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:simfit/models/activity.dart';
import 'package:simfit/navigation/navtools.dart';
import 'package:simfit/providers/home_provider.dart';
import 'package:simfit/utils/graphic_elements.dart';

/// The main Home widget that shows the home screen of the app.
/// It's a stateful widget because it manages the selected date.
class Home extends StatefulWidget {
  const Home({super.key});

  /// Named route for navigation.
  static const routename = 'Home';

  @override
  State<Home> createState() => _HomeState();
}

/// State class for the Home widget.
class _HomeState extends State<Home> {
  /// The date currently selected by the user (initialized as yesterday)
  DateTime selectedDate = DateTime.now().subtract(const Duration(days: 1));

  @override
  void initState() {
    super.initState();

    /// Fetch data for the initially selected date using the HomeProvider.
    Provider.of<HomeProvider>(context, listen: false)
        .getDataOfDay(selectedDate);
  }

  /// Displays the date picker dialog and updates [selectedDate] if a new date is picked.
  Future<void> selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000, 1),
      lastDate:
          DateUtils.dateOnly(DateTime.now().subtract(const Duration(days: 1))),
    );
    if (picked != null && picked != selectedDate) {
      selectedDate = picked;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the width of the screen to use for responsive layouts
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Home',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Theme.of(context).secondaryHeaderColor,
      ),

      // Main body of the screen within SafeArea and scrollable
      body: SafeArea(
        child: SingleChildScrollView(
          child: Consumer<HomeProvider>(
            // Reactively rebuilds UI when HomeProvider updates
            builder: (context, provider, child) {
              return Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Widget that allows user to change the selected date
                  _buildDateSelector(provider),

                  // Displays the main content of the home screen
                  _buildHomeBody(screenWidth),
                ],
              );
            },
          ),
        ),
      ),

      /// Navigation drawer for app-wide navigation.
      drawer: const NavDrawer(),
    );
  }

  /// Builds a row with left/right arrow buttons and a central date picker button.
  /// Allows the user to navigate between days and fetch corresponding data.
  Widget _buildDateSelector(HomeProvider provider) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Button to go to the previous day
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(12),
              backgroundColor: Theme.of(context).primaryColor,
            ),
            onPressed: () {
              // Move to the previous day and fetch corresponding data
              selectedDate = selectedDate.subtract(const Duration(days: 1));
              provider.getDataOfDay(selectedDate);
            },
            child: Icon(
              Icons.arrow_back_ios_rounded,
              color: Theme.of(context).secondaryHeaderColor,
              size: 26,
            ),
          ),
        ),

        // Central button showing the currently selected date
        // Opens a date picker when pressed
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextButton(
                onPressed: () async {
                  // Open date picker and fetch data if a date is picked
                  await selectDate(context);
                  provider.getDataOfDay(selectedDate);
                },
                child: Text(
                  DateFormat('EEE, d MMM').format(selectedDate),
                  style: TextStyle(
                    color: Theme.of(context).secondaryHeaderColor,
                    fontSize: 24,
                    letterSpacing: 0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),

        // Button to go to the next day, if not in the future
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(12),
              backgroundColor: Theme.of(context).primaryColor,
            ),
            onPressed: () {
              // Prevent going beyond yesterday (no future data)
              if (!selectedDate.isAfter(DateUtils.dateOnly(
                  DateTime.now().subtract(const Duration(days: 1))))) {
                selectedDate = selectedDate.add(const Duration(days: 1));
                provider.getDataOfDay(selectedDate);
              }
            },
            child: Icon(
              Icons.arrow_forward_ios_rounded,
              color: Theme.of(context).secondaryHeaderColor,
              size: 26,
            ),
          ),
        ),
      ],
    );
  }
  
  /// Builds the main content of the Home page, showing either a loading indicator
  /// or the daily summary data and activity recaps once data is ready.
  Widget _buildHomeBody(double screenWidth) {
    return Consumer<HomeProvider>(
      builder: (context, provider, child) {
        // Show a loading spinner while data is being fetched
        if (!provider.dataReady) {
          return const Column(
            children: [
              SizedBox(height: 100),
              CircularProgressIndicator(
                color: Colors.blue,
                strokeWidth: 5,
              ),
            ],
          );
        }

        // Helper function to build a card showing a single statistic with icon, label, and value.
        Widget buildStatCard({
          required IconData icon,
          required Color iconColor,
          required String label,
          required String value,
        }) {
          return Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(icon, color: iconColor, size: 26),
                    Padding(
                      padding: const EdgeInsets.all(4),
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: Color(0xFF14181B),
                          fontWeight: FontWeight.w500,
                          fontSize: 22,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF14181B),
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ],
            ),
          );
        }

        // Main column containing all content on the home page
        return Column(
          children: [
            // Container for daily recap stats
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                width: 0.9 * screenWidth, // Responsive width based on screen size
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    // Title for the daily recap section
                    const Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Center(
                        child: Text(
                          'Daily recap',
                          style: TextStyle(
                            color: Color(0xFF14181B),
                            fontWeight: FontWeight.w600,
                            fontSize: 24,
                          ),
                        ),
                      ),
                    ),

                    // Two columns displaying daily stats side by side
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // First column with Steps and Heart Rate cards
                        Column(
                          children: [
                            buildStatCard(
                              icon: FontAwesomeIcons.shoePrints,
                              iconColor: const Color(0xFF29C51F),
                              label: 'Steps',
                              value: provider.totDailySteps > 0
                                  ? provider.totDailySteps.toString()
                                  : '-', // Show '-' if no data
                            ),
                            buildStatCard(
                              icon: Icons.favorite_rounded,
                              iconColor: const Color(0xFFFF0000),
                              label: 'Heart rate',
                              value: provider.dailyRestHR > 0
                                  ? '${provider.dailyRestHR} bpm'
                                  : '-',
                            ),
                          ],
                        ),

                        // Second column with Calories and Sleep cards
                        Column(
                          children: [
                            buildStatCard(
                              icon: Icons.local_fire_department,
                              iconColor: const Color(0xFFF024F0),
                              label: 'Calories',
                              value: provider.totDailyCalories > 0
                                  ? '${provider.totDailyCalories} kcal'
                                  : '-',
                            ),
                            buildStatCard(
                              icon: Icons.bedtime_rounded,
                              iconColor: const Color(0xFF253CF8),
                              label: 'Sleep',
                              value: provider.mainDailySleep.inMinutes > 0
                                  ? '${provider.mainDailySleep.inHours} h ${provider.mainDailySleep.inMinutes.remainder(60)} min'
                                  : '-',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // If there are recorded daily activities, show each using the ActivityRecap widget
            if (provider.dailyActivities.isNotEmpty)
              Column(
                children: provider.dailyActivities
                    .map((activity) => ActivityRecap(activity: activity))
                    .toList(),
              )
            // Otherwise, display a message indicating no training sessions were recorded
            else
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                child: Text(
                  'No training session recorded.',
                  style: TextStyle(
                    color: Color.fromARGB(255, 126, 127, 129),
                    fontWeight: FontWeight.w500,
                    fontSize: 22,
                  ),
                ),
              ),

            // Extra spacing at the bottom
            const SizedBox(height: 40),
          ],
        );
      },
    );
  }
}

/// A stateless widget that displays a summary of a physical activity,
/// including duration, speed, heart rate, VO2 max, distance, steps,
/// calories, elevation gain, and heart rate training zones.
class ActivityRecap extends StatelessWidget {
  /// The activity to display.
  final Activity activity;

  /// Creates an [ActivityRecap] widget.
  const ActivityRecap({super.key, required this.activity});

  /// Replaces default placeholder values with a dash if matched.
  String _formatLabel(String value, String defaultValue) => (value == defaultValue) ? ' - ' : value;

  /// Returns a label combining the activity name and start time.
  String get activityLabel => '${activity.activityName} - ${DateFormat('HH:mm').format(activity.startingTime)}';

  /// Returns a formatted string representing the duration of the activity.
  /// If duration is zero, returns a dash.
  String get durationLabel {
    final duration = activity.duration;
    if (duration == Duration.zero) return ' - ';
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  /// Returns the average speed formatted in km/h or a dash if zero.
  String get avgSpeedLabel =>
      _formatLabel('${activity.avgSpeed.toStringAsFixed(2)} km/h', '0.00 km/h');

  /// Returns the average heart rate or a dash if zero.
  String get avgHRLabel =>
      _formatLabel('${activity.avgHR} bpm', '0 bpm');

  /// Returns the estimated VO2 max or a dash if zero.
  String get vo2MaxLabel =>
      _formatLabel('${activity.vo2Max.toStringAsFixed(1)} ml/kg/min', '0.0 ml/kg/min');

  /// Returns the distance or a dash if zero.
  String get distanceLabel =>
      _formatLabel('${activity.distance.toStringAsFixed(2)} km', '0.00 km');

  /// Returns the number of steps or a dash if zero.
  String get stepsLabel =>
      _formatLabel('${activity.steps} steps', '0 steps');

  /// Returns the calories burned or a dash if zero.
  String get caloriesLabel =>
      _formatLabel('${activity.calories} kcal', '0 kcal');

  /// Returns the elevation gain or a dash if zero.
  String get elevationGainLabel =>
      _formatLabel('${activity.elevationGain.toStringAsFixed(0)} m', '0 m');

  /// Returns an icon matching the activity type.
  IconData get trainingIcon {
    switch (activity.activityName) {
      case 'Corsa':
        return FontAwesomeIcons.personRunning;
      case 'Bici':
        return FontAwesomeIcons.personBiking;
      case 'Camminata':
        return FontAwesomeIcons.personWalking;
      default:
        return FontAwesomeIcons.dumbbell;
    }
  }

  /// Builds a row with an icon and a text label.
  Widget _infoRow(IconData icon, Color color, String text, {double iconSize = 24}) {
    return Row(
      children: [
        Icon(icon, color: color, size: iconSize),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            color: Color(0xFF14181B),
            fontWeight: FontWeight.w500,
            fontSize: 18,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        width: screenWidth * 0.8,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: const [
            BoxShadow(
              blurRadius: 4,
              color: Color(0x33000000),
              offset: Offset(0, 2),
            ),
          ],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            children: [
              // Header with activity icon and label.
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: FaIcon(trainingIcon,
                          color: Theme.of(context).primaryColor, size: 26),
                    ),
                    Text(
                      activityLabel,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ],
                ),
              ),

              // Two-column display of activity metrics.
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoRow(Icons.timer_outlined, const Color(0xFFFF8A2C), durationLabel),
                        _infoRow(Icons.speed_outlined, const Color(0xFF118D4F), avgSpeedLabel),
                        _infoRow(Icons.favorite_border_rounded, Colors.red, avgHRLabel),
                        _infoRow(Icons.air_outlined, const Color(0xFF08D3FF), vo2MaxLabel),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoRow(Icons.outlined_flag_rounded, const Color(0xFF6800FF), distanceLabel),
                        _infoRow(FontAwesomeIcons.shoePrints, const Color(0xFF28DA32), stepsLabel, iconSize: 16),
                        _infoRow(Icons.local_fire_department_outlined, const Color(0xFFF024F0), caloriesLabel),
                        _infoRow(Icons.trending_up_rounded, const Color(0xFEF0C500), elevationGainLabel),
                      ],
                    ),
                  ],
                ),
              ),

              // Expandable section for heart rate training zones.
              ExpansionTile(
                title: const Center(child: Text('Heart Rate Training Zones')),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                  side: BorderSide(color: Colors.transparent),
                ),
                initiallyExpanded: false,
                backgroundColor: Colors.transparent,
                collapsedBackgroundColor: Colors.transparent,
                children: [
                  const Center(child: Text('Minutes spent in each zone')),
                  Container(
                    height: 200,
                    padding: const EdgeInsets.all(10),
                    child: HRZoneBarChart(zonesHR: activity.zonesHR),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
