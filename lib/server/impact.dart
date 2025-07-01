import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'package:simfit/models/activity.dart';
import 'package:simfit/models/calories.dart';
import 'package:simfit/models/heart_rate.dart';
import 'package:simfit/models/sleep.dart';
import 'package:simfit/models/steps.dart';

/// Class Impact providing methods to interact with the IMPACT API
class Impact {
  /// Base URL for all IMPACT API calls
  static String baseUrl = 'https://impact.dei.unipd.it/bwthw/';

  /// Endpoint to check backend availability
  static String pingEndpoint = 'gate/v1/ping/';

  /// Endpoint to obtain access and refresh tokens
  static String tokenEndpoint = 'gate/v1/token/';

  /// Endpoint to refresh JWT tokens
  static String refreshEndpoint = 'gate/v1/refresh/';

  /// Static username used in patient-specific API calls
  static String patientUsername = 'Jpefaq6m58';

  /// Checks if the IMPACT backend server is operational
  ///
  /// Sends a GET request to the ping endpoint and returns `true` if the response
  /// status code is 200, indicating the server is up.
  Future<bool> isImpactUp() async {
    final url = Impact.baseUrl + Impact.pingEndpoint;
    final response = await http.get(Uri.parse(url));
    return response.statusCode == 200;
  }

  /// Requests and stores JWT access and refresh tokens using username and password
  ///
  /// Sends a POST request to the token endpoint with credentials. If successful,
  /// stores the received tokens in `SharedPreferences`.
  ///
  /// Returns the HTTP status code of the response.
  Future<int> getAndStoreTokens(String username, String password) async {
    final url = Impact.baseUrl + Impact.tokenEndpoint;
    final body = {'username': username, 'password': password};
    final response = await http.post(Uri.parse(url), body: body);

    if (response.statusCode == 200) {
      final decodedResponse = jsonDecode(response.body);
      final sp = await SharedPreferences.getInstance();
      await sp.setString('access', decodedResponse['access']);
      await sp.setString('refresh', decodedResponse['refresh']);
    }

    return response.statusCode;
  }

  /// Refreshes stored JWT tokens using the saved refresh token
  ///
  /// Sends a POST request with the refresh token to the refresh endpoint.
  /// If successful, updates both access and refresh tokens in `SharedPreferences`.
  ///
  /// Returns the HTTP status code of the response, or 401 if the refresh token is null.
  Future<int> refreshTokens() async {
    final url = Impact.baseUrl + Impact.refreshEndpoint;
    final sp = await SharedPreferences.getInstance();
    final refresh = sp.getString('refresh');
    if (refresh != null) {
      final body = {'refresh': refresh};
      final response = await http.post(Uri.parse(url), body: body);

      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body);
        final sp = await SharedPreferences.getInstance();
        await sp.setString('access', decodedResponse['access']);
        await sp.setString('refresh', decodedResponse['refresh']);
      }

      return response.statusCode;
    }
    return 401;
  }

  /// Validates a saved token (access or refresh)
  ///
  /// Checks whether a saved token (access by default, or refresh if specified)
  /// exists and is not expired.
  ///
  /// Returns `true` if the token is valid, `false` otherwise.
  Future<bool> checkSavedToken({bool refresh = false}) async {
    final sp = await SharedPreferences.getInstance();
    final token = sp.getString(refresh ? 'refresh' : 'access');

    if (token == null) {
      return false;
    }
    try {
      return Impact.checkToken(token);
    } catch (_) {
      return false;
    }
  }

  /// Static helper method to check whether a JWT token is expired
  ///
  /// Uses the `JwtDecoder` package to determine token validity.
  static bool checkToken(String token) {
    if (JwtDecoder.isExpired(token)) {
      return false;
    }
    return true;
  }

  /// Prepares and returns the Bearer Authorization header for API requests
  ///
  /// If the access token is invalid, tries to refresh it or fetch new tokens.
  /// Returns a map containing the `Authorization` header.
  Future<Map<String, String>> getBearer() async {
    if (!await checkSavedToken()) {
      if (!await checkSavedToken(refresh: true)) {
        final sp = await SharedPreferences.getInstance();
        String username = sp.getString('username') ?? '';
        String password = sp.getString('password') ?? '';
        await getAndStoreTokens(username, password);
      } else {
        await refreshTokens();
      }
    }
    final sp = await SharedPreferences.getInstance();
    final token = sp.getString('access');

    return {'Authorization': 'Bearer $token'};
  }

  /// Fetches daily activities from the IMPACT API for a specific [day].
  ///
  /// Returns a list of [Activity] objects for that date.
  /// If the request fails or no data is returned, an empty list is returned.
  Future<List<Activity>> getActivitiesFromDay(DateTime day) async {
    var header = await getBearer();
    String formattedDay = DateFormat('yyyy-MM-dd').format(day);
    var r = await http.get(
      Uri.parse(
        '${Impact.baseUrl}/data/v1/exercise/patients/$patientUsername/day/$formattedDay/',
      ),
      headers: header,
    );
    if (r.statusCode != 200) return [];

    dynamic data = jsonDecode(r.body)["data"];
    if (data.isNotEmpty) {
      List<Activity> activities = [];
      for (var currentActivity in data["data"]) {
        activities.add(Activity.fromJson(
            data["date"], currentActivity)); // Parsing activity data
      }
      return activities;
    }
    return [];
  }

  /// Fetches physical activity data from the IMPACT API for the date range
  /// between [start] and [end] (inclusive).
  ///
  /// Returns a map where each key is a [DateTime] representing a day in the range,
  /// and the value is a list of [Activity] objects for that day.
  ///
  /// If the start and end dates are the same, only that day's activities are returned.
  Future<Map<DateTime, List<Activity>>> getActivitiesFromDateRange(
    DateTime start,
    DateTime end,
  ) async {
    Map<DateTime, List<Activity>> activities = {};

    if (start.isAtSameMomentAs(end)) {
      // Checking if start and end dates are the same
      activities[start] = await getActivitiesFromDay(
          start); // Fetching activities for single day
      return activities;
    }

    List<Map<String, String>> formattedStartEnd =
        _formatFromRangeToWeeks(start, end);
    for (var element in formattedStartEnd) {
      var header = await getBearer();
      var r = await http.get(
        Uri.parse(
          '${Impact.baseUrl}/data/v1/exercise/patients/$patientUsername/daterange/start_date/${element['start']}/end_date/${element['end']}/',
        ),
        headers: header,
      );
      if (r.statusCode == 200) {
        List<dynamic> data = jsonDecode(r.body)["data"];
        if (data.isNotEmpty) {
          for (var daydata in data) {
            List<Activity> dayActivities = [];
            String day = daydata["date"];
            for (var currentActivity in daydata["data"]) {
              dayActivities.add(Activity.fromJson(
                  day, currentActivity)); // Parsing activity data
            }
            activities[DateFormat('yyyy-MM-dd').parse(day)] =
                dayActivities; // Adding activities to map
          }
        }
      }
    }
    return activities;
  }

  /// Fetches heart rate (HR) data from the IMPACT API for a specific [day].
  ///
  /// Returns a sorted list of [HR] objects by timestamp.
  /// If the request fails or no data is available, returns an empty list.
  Future<List<HR>> getHRFromDay(DateTime day) async {
    var header = await getBearer();
    String formattedDay = DateFormat('yyyy-MM-dd').format(day);
    var r = await http.get(
      Uri.parse(
        '${Impact.baseUrl}/data/v1/heart_rate/patients/$patientUsername/day/$formattedDay/',
      ),
      headers: header,
    );
    if (r.statusCode != 200) return [];

    dynamic data = jsonDecode(r.body)["data"];
    if (data.isNotEmpty) {
      List<HR> hr = [];
      for (var currentHR in data["data"]) {
        hr.add(HR.fromJson(data["date"], currentHR)); // Parsing heart rate data
      }

      var hrlist = hr.toList()
        ..sort((a, b) =>
            a.timestamp.compareTo(b.timestamp)); // Sorting heart rate data
      return hrlist; // Returning sorted heart rate list
    }
    return [];
  }

  /// Fetches calories data from the IMPACT API for a specific [day].
  ///
  /// Returns a sorted list of [Calories] objects by timestamp.
  /// If the request fails or no data is available, returns an empty list.
  Future<List<Calories>> getCaloriesFromDay(DateTime day) async {
    var header = await getBearer();
    String formattedDay = DateFormat('yyyy-MM-dd').format(day);
    var r = await http.get(
      Uri.parse(
        '${Impact.baseUrl}/data/v1/calories/patients/$patientUsername/day/$formattedDay/',
      ),
      headers: header,
    );
    if (r.statusCode != 200) return [];

    dynamic data = jsonDecode(r.body)["data"];
    if (data.isNotEmpty) {
      List<Calories> calories = [];
      for (var currentCals in data["data"]) {
        calories.add(Calories.fromJson(
            data["date"], currentCals)); // Parsing calories data
      }

      var calorieslist = calories.toList()
        ..sort((a, b) =>
            a.timestamp.compareTo(b.timestamp)); // Sorting calories data
      return calorieslist; // Returning sorted calories list
    }
    return [];
  }

  /// Fetches steps data from the IMPACT API for a specific [day].
  ///
  /// Returns a sorted list of [Steps] objects by timestamp.
  /// If the request fails or no data is available, returns an empty list.
  Future<List<Steps>> getStepsFromDay(DateTime day) async {
    var header = await getBearer();
    String formattedDay = DateFormat('yyyy-MM-dd').format(day);
    var r = await http.get(
      Uri.parse(
        '${Impact.baseUrl}/data/v1/steps/patients/$patientUsername/day/$formattedDay/',
      ),
      headers: header,
    );
    if (r.statusCode != 200) return [];

    dynamic data = jsonDecode(r.body)["data"];
    if (data.isNotEmpty) {
      List<Steps> steps = [];
      for (var currentSteps in data["data"]) {
        steps.add(
            Steps.fromJson(data["date"], currentSteps)); // Parsing steps data
      }

      var stepslist = steps.toList()
        ..sort(
            (a, b) => a.timestamp.compareTo(b.timestamp)); // Sorting steps data
      return stepslist; // Returning sorted steps list
    }
    return [];
  }

  /// Fetches sleep data from the IMPACT API for a specific [day].
  ///
  /// Returns a list of [Sleep] objects parsed from the response.
  /// Handles both list and single map data formats in the response.
  /// Returns an empty list if the request fails or no data is available.
  Future<List<Sleep>> getSleepsFromDay(DateTime day) async {
    var header = await getBearer();
    String formattedDay = DateFormat('yyyy-MM-dd').format(day);
    var r = await http.get(
      Uri.parse(
        '${Impact.baseUrl}/data/v1/sleep/patients/$patientUsername/day/$formattedDay/',
      ),
      headers: header,
    );
    if (r.statusCode != 200) return [];

    dynamic data = jsonDecode(r.body)["data"];
    if (data.isNotEmpty) {
      List<Sleep> sleeps = [];
      if (data["data"] is List) {
        for (var currentSleep in data["data"]) {
          sleeps.add(Sleep.fromJson(data["date"], currentSleep));
        }
      } else if (data["data"] is Map) {
        sleeps.add(Sleep.fromJson(data["date"], data["data"]));
      }
      return sleeps;
    }
    return [];
  }

  /// Fetches resting heart rate (Rest HR) data from the IMPACT API for a specific [day].
  ///
  /// Returns the resting heart rate value as a [double].
  /// Returns 0.0 if the request fails or no data is available.
  Future<double> getRestHRFromDay(DateTime day) async {
    var header = await getBearer();
    String formattedDay = DateFormat('yyyy-MM-dd').format(day);
    var r = await http.get(
      Uri.parse(
        '${Impact.baseUrl}/data/v1/resting_heart_rate/patients/$patientUsername/day/$formattedDay/',
      ),
      headers: header,
    );
    if (r.statusCode != 200) return 0.0;

    dynamic data = jsonDecode(r.body)["data"];
    if (data.isNotEmpty) {
      return data["data"]["value"] ?? 0.0;
    }
    return 0.0;
  }

  /// Fetches resting heart rate (Rest HR) data from the IMPACT API for a date range
  /// between [start] and [end].
  ///
  /// Returns a map with keys as [DateTime] objects representing days, and values
  /// as resting heart rate values (double) for those days.
  /// Returns an empty map if no data is available or request fails.
  Future<Map<DateTime, double>> getRestHRsFromDateRange(
    DateTime start,
    DateTime end,
  ) async {
    Map<DateTime, double> restHRs = {};

    List<Map<String, String>> formattedStartEnd = _formatFromRangeToWeeks(start, end);

    for (Map<String, String> element in formattedStartEnd) {
      var header = await getBearer();
      var r = await http.get(
        Uri.parse(
          '${Impact.baseUrl}/data/v1/resting_heart_rate/patients/$patientUsername/daterange/start_date/${element['start']}/end_date/${element['end']}/',
        ),
        headers: header,
      );
      if (r.statusCode == 200) {
        List<dynamic> data = jsonDecode(r.body)["data"];
        for (var daydata in data) {
          String day = daydata["date"];
          double dayRestHR = daydata["data"]["value"];
          restHRs[DateFormat('yyyy-MM-dd').parse(day)] = dayRestHR; // Adding resting heart rate to map
        }
      }
    }

    return restHRs;
  }

  /// Converts a date range from [start] to [end] into a list of weeks,
  /// where each week is represented as a map with 'start' and 'end' keys,
  /// containing the formatted dates ('yyyy-MM-dd') for that week.
  ///
  /// The weeks are full 7-day periods starting from [start]. The last week
  /// may have fewer than 7 days if the range doesn't divide evenly.
  ///
  /// Returns a list of maps representing each week's start and end dates.
  List<Map<String, String>> _formatFromRangeToWeeks(DateTime start, DateTime end) {
    List<Map<String, String>> weeks = [];

    int daysRange = end.difference(start).inDays + 1;
    int completeWeeks = daysRange ~/ 7;
    int remainingDays = daysRange % 7;

    // Add complete weeks
    for (int week = 0; week < completeWeeks; week++) {
      DateTime weekStart = start.add(Duration(days: week * 7));
      DateTime weekEnd = weekStart.add(const Duration(days: 6));

      weeks.add({
        'start': DateFormat('yyyy-MM-dd').format(weekStart),
        'end': DateFormat('yyyy-MM-dd').format(weekEnd),
      });
    }

    // Add remaining days as a partial week, if any
    if (remainingDays > 0) {
      DateTime remainingStart = start.add(Duration(days: completeWeeks * 7));
      weeks.add({
        'start': DateFormat('yyyy-MM-dd').format(remainingStart),
        'end': DateFormat('yyyy-MM-dd').format(end),
      });
    }

    return weeks;
  }
}
