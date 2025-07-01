import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A [ChangeNotifier] that manages user information, including
/// onboarding status, personal details, and mesocycle tracking.
class UserProvider with ChangeNotifier {
  /// Whether this is the user's first login.
  bool firstLogin = true;

  /// The user's name.
  String? name;

  /// The user's gender.
  String? gender;

  /// The user's birth date.
  DateTime? birthDate;

  /// The user's computed age.
  int? age;

  /// The length of the user's mesocycle in days.
  int? mesocycleLength;

  /// The start date of the current mesocycle.
  DateTime? mesocycleStartDate;

  /// The end date of the current mesocycle.
  DateTime? mesocycleEndDate;

  /// Creates an instance of [UserProvider] and loads saved user data.
  UserProvider() {
    _loadUserData();
  }

  /// Marks the user as onboarded by setting the relevant flag in [SharedPreferences].
  Future<void> onboardUser() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('onboarded', true);
  }

  /// Checks if the user has already completed onboarding.
  ///
  /// Returns `true` if onboarding is complete, otherwise `false`.
  Future<bool> checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarded') ?? false;
  }

  /// Loads user data from [SharedPreferences] and updates internal state.
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();

    firstLogin = prefs.getBool('firstLogin') ?? firstLogin;
    name = prefs.getString('name') ?? name;
    gender = prefs.getString('gender') ?? gender;

    // Parse birthDate string into DateTime
    String? bd = prefs.getString('birthDate');
    if (bd != null) {
      birthDate = DateUtils.dateOnly(DateFormat('yyyy-MM-dd').parse(bd));
    }

    // Calculate age from birthDate
    age = _computeAge();

    // Load mesocycle data
    mesocycleLength = prefs.getInt('mesocycleLength') ?? mesocycleLength;

    // Parse mesocycle start and compute end date if possible
    String? startDate = prefs.getString('mesocycleStart');
    if (startDate != null) {
      mesocycleStartDate = DateUtils.dateOnly(DateFormat('yyyy-MM-dd').parse(startDate));

      if (mesocycleLength != null) {
        mesocycleEndDate = DateUtils.dateOnly(
          DateFormat('yyyy-MM-dd').parse(startDate).add(
            Duration(days: mesocycleLength! - 1),
          ),
        );
      }
    }

    notifyListeners();
  }

  /// Saves and sets the user's data, including personal info and mesocycle details.
  ///
  /// - [newName] - the user's name
  /// - [newGender] - the user's gender
  /// - [newBirthDate] - the user's birth date in 'yyyy-MM-dd' format
  /// - [newMesoLength] - the length of the mesocycle in days
  /// - [newMesoStart] - the start date of the mesocycle in 'yyyy-MM-dd' format
  Future<void> setUserData({
    required String newName,
    required String newGender,
    required String newBirthDate,
    required int newMesoLength,
    required String newMesoStart,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // If this is the first login, mark it as completed
    if (firstLogin) {
      await prefs.setBool('firstLogin', false);
      firstLogin = false;
    }

    // Save data to SharedPreferences
    await prefs.setString('name', newName);
    await prefs.setString('gender', newGender);
    await prefs.setString('birthDate', newBirthDate);
    await prefs.setInt('mesocycleLength', newMesoLength);
    await prefs.setString('mesocycleStart', newMesoStart);

    // Update local state variables
    name = newName;
    gender = newGender;
    birthDate = DateUtils.dateOnly(DateFormat('yyyy-MM-dd').parse(newBirthDate));
    age = _computeAge();
    mesocycleLength = newMesoLength;
    mesocycleStartDate = DateUtils.dateOnly(DateFormat('yyyy-MM-dd').parse(newMesoStart));
    mesocycleEndDate = DateUtils.dateOnly(
      DateFormat('yyyy-MM-dd').parse(newMesoStart).add(
        Duration(days: newMesoLength - 1),
      ),
    );

    notifyListeners();
  }

  /// Computes the user's age based on [birthDate].
  ///
  /// Returns the calculated age in years.
  int _computeAge() {
    if (birthDate == null) return 0;

    DateTime today = DateTime.now();
    int years = today.year - birthDate!.year;
    int months = today.month - birthDate!.month;
    int days = today.day - birthDate!.day;

    // Adjust if the birthday hasn't occurred yet this year
    if (months < 0 || (months == 0 && days < 0)) {
      years--;
    }

    return years;
  }
}