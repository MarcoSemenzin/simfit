import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:simfit/models/activity.dart';
import 'package:simfit/providers/score_provider.dart';

/// A widget that renders a line chart of training performance scores over time.
/// 
/// The chart shows multiple performance metrics (like 'ACL', 'CTL', 'TSB') as lines,
/// with x-axis representing days since the first date in the data,
/// and y-axis representing the score values.
class CustomPlot extends StatelessWidget {
  /// Map of dates to a map of score types and their values for that date.
  final Map<DateTime, Map<String, double>> scores;

  /// Provider to handle score state updates when user interacts with the chart.
  final ScoreProvider scoreProvider;

  /// Creates a [CustomPlot] widget with the given [scores] and [scoreProvider].
  const CustomPlot({
    super.key, 
    required this.scores, 
    required this.scoreProvider,
  });

  @override
  Widget build(BuildContext context) {
    // Use the first date as the reference (day 0)
    final referenceDate = scores.keys.first;

    // Convert all dates to days difference relative to referenceDate, then sort
    final xValues = scores.keys
        .map((date) => date.difference(referenceDate).inDays.toDouble())
        .toList()
      ..sort();

    final double minX = xValues.first;
    final double maxX = xValues.last;

    // Calculate interval for x-axis titles based on the number of scores
    double? intervalX;
    if (scores.length > 2 && scores.length < 10) {
      intervalX = (maxX - minX) / (scores.length - 1);
    } else if (scores.length >= 10) {
      intervalX = (maxX - minX) / 3;
    }

    // Determine the min and max Y values, excluding the 'TRIMP' type
    double minY = double.infinity;
    double maxY = double.negativeInfinity;
    for (var dailyScores in scores.values) {
      dailyScores.forEach((type, value) {
        if (type != 'TRIMP') {
          if (value < minY) minY = value;
          if (value > maxY) maxY = value;
        }
      });
    }

    // Round minY down and maxY up to nearest 10, adding padding of 20 units total
    minY = ((minY / 10).ceil() - 2) * 10.0;
    maxY = ((maxY / 10).floor() + 2) * 10.0;

    // Calculate interval for y-axis labels
    double intervalY = ((maxY.abs() + minY.abs()) / 100).ceil() * 10.toDouble();

    return LineChart(
      LineChartData(
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: intervalX,
              getTitlesWidget: (value, meta) {
                final date = referenceDate.add(Duration(days: value.toInt()));
                // If intervalX is null, only show labels for min and max x values
                if (intervalX == null) {
                  if (value == minX || value == maxX) {
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      angle: -pi / 5,
                      child: Text(
                        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  return Container();
                }
                // Otherwise show label for every interval
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  angle: -pi / 5,
                  child: Text(
                    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: intervalY,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          drawVerticalLine: false,
          drawHorizontalLine: true,
          horizontalInterval: intervalY,
        ),
        borderData: FlBorderData(show: true),
        clipData: const FlClipData(
          top: true, 
          bottom: true, 
          left: false, 
          right: false,
        ),
        lineBarsData: [
          _buildLineChartBarData('ACL', Colors.red),
          _buildLineChartBarData('CTL', Colors.blue),
          _buildLineChartBarData('TSB', Colors.deepPurple),
        ],
        minY: minY,
        maxY: maxY,
        lineTouchData: LineTouchData(
          enabled: true,
          handleBuiltInTouches: true,
          touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
            // On tap or long press end, update the provider with selected date's scores
            if (event is FlTapUpEvent || event is FlLongPressEnd) {
              if (response?.lineBarSpots != null) {
                final spot = response!.lineBarSpots!.first;
                final date = referenceDate.add(Duration(days: spot.x.toInt()));
                scoreProvider.setNewScoresOfDay(date, scores[date]!);
              }
            }
          },
          touchTooltipData: LineTouchTooltipData(
            // Disabling tooltip content by returning null items
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((_) => null).toList();
            },
          ),
        ),
      ),
    );
  }

  /// Helper method to build [LineChartBarData] for a given score key and color.
  LineChartBarData _buildLineChartBarData(String key, Color color) {
    return LineChartBarData(
      spots: _getSpots(key),
      isCurved: false,
      barWidth: 3,
      color: color,
      belowBarData: BarAreaData(show: false),
    );
  }

  /// Converts scores of a specific key into sorted [FlSpot] objects for the chart.
  List<FlSpot> _getSpots(String key) {
    final referenceDate = scores.keys.first;
    return scores.entries
        .where((entry) => entry.value.containsKey(key))
        .map((entry) => FlSpot(
            entry.key.difference(referenceDate).inDays.toDouble(), 
            entry.value[key]!
          ))
        .toList()
      ..sort((a, b) => a.x.compareTo(b.x)); // Sort spots by x (date)
  }
}


/// A widget that displays the TRIMP (Training Impulse) value
/// along with a badge indicating the effort level category.
class TRIMPDisplay extends StatelessWidget {
  /// The TRIMP index value to display.
  final double index;

  /// Creates a TRIMPDisplay widget.
  /// 
  /// The [index] parameter must not be null.
  const TRIMPDisplay({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    String badgeText = '';
    Color badgeColor = Colors.green;

    // Determine the badge text and color based on the TRIMP value
    if (index < 50) {
      badgeText = 'Easy';
      badgeColor = Colors.green;
    } else if (index < 120) {
      badgeText = 'Moderate';
      badgeColor = Colors.orange;
    } else if (index < 250) {
      badgeText = 'Hard';
      badgeColor = Colors.red;
    } else {
      badgeText = 'Very hard';
      badgeColor = Colors.black;
    }

    return Container(
      padding: const EdgeInsets.all(5.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            /// Displays the TRIMP index value formatted to 2 decimal places.
            Text(
              'TRIMP: ${double.parse((index).toStringAsFixed(2))}',
              style: const TextStyle(fontSize: 18),
            ),

            /// Badge showing the effort level category with corresponding color.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                badgeText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A bar chart widget to display heart rate (HR) zones and
/// the corresponding minutes spent in each zone.
class HRZoneBarChart extends StatelessWidget {
  /// List of heart rate zones with their respective minutes.
  final List<HRZone> zonesHR;

  /// Creates an HRZoneBarChart widget.
  /// 
  /// The [zonesHR] parameter must not be null.
  const HRZoneBarChart({super.key, required this.zonesHR});

  @override
  Widget build(BuildContext context) {
    // Find the maximum minutes spent among all HR zones to
    // determine the scale of the vertical axis.
    int maxMinutes = zonesHR
        .map((zone) => zone.minutes)
        .reduce((max, minutes) => max > minutes ? max : minutes);

    // Calculate the vertical interval for y-axis titles:
    // If maxMinutes < 50, use interval of 5,
    // otherwise, calculate a rounded interval based on maxMinutes.
    double intervalY =
        (maxMinutes < 50) ? 5 : (maxMinutes.abs() / 100).ceil() * 10.toDouble();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,

        // Create a group of bars for each HR zone,
        // using the index as the x-coordinate.
        barGroups: zonesHR.map((zone) {
          int index = zonesHR.indexOf(zone);
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: zone.minutes.toDouble(),
                color: Theme.of(context).primaryColor,
                width: 30,
                borderRadius: BorderRadius.circular(0),
              ),
            ],
          );
        }).toList(),

        // Configure titles on all sides
        titlesData: FlTitlesData(
          show: true,

          // Bottom axis titles: zone names, split into multiple lines on spaces.
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    zonesHR[value.toInt()].name.replaceAll(' ', '\n'),
                    softWrap: true,
                  ),
                );
              },
            ),
          ),

          // Left axis titles: numeric minutes labels spaced by intervalY.
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: intervalY,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(value.toInt().toString()),
                );
              },
            ),
          ),

          // Hide top and right axis titles.
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),

        // No borders or grid lines for a cleaner look.
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
      ),
    );
  }
}


/// A widget that displays an emoji representing performance status
/// based on the TSB (Training Stress Balance) value.
///
/// The emoji reflects the user's recovery and training load:
/// - 🥵 : Very negative TSB (overtrained or fatigued)
/// - 😟 : Moderately negative TSB (fatigued)
/// - 😐 : Neutral TSB (balanced)
/// - 😊 : Positive TSB (well recovered)
/// - 🤩 : Very positive TSB (fresh and ready)
class PerformanceEmoji extends StatelessWidget {
  /// The training stress balance value used to determine the emoji.
  final double tsb;

  /// Emoji string determined from [tsb].
  late final String emoji;

  /// Creates a PerformanceEmoji widget.
  ///
  /// The [tsb] value is required and used to select the emoji.
  PerformanceEmoji({super.key, required this.tsb}) {
    if (tsb < -25.0) {
      emoji = '🥵';
    } else if (tsb < -10.0) {
      emoji = '😟';
    } else if (tsb < 5.0) {
      emoji = '😐';
    } else if (tsb < 20.0) {
      emoji = '😊';
    } else {
      emoji = '🤩';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      emoji,
      style: const TextStyle(
        fontSize: 24,
        color: Colors.deepPurple,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}