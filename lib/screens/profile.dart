import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:simfit/navigation/navtools.dart';
import 'package:simfit/providers/user_provider.dart';
import 'package:simfit/screens/home.dart';

/// A user profile page that allows editing and saving of personal data,
/// including name, gender, birth date, and mesocycle information.
///
/// This widget loads existing data from [UserProvider] and updates it upon save.
/// If the user is logging in for the first time, they are redirected to the home page after saving.
class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  /// Key used to validate the profile form.
  final _formKey = GlobalKey<FormState>();

  /// Controller for the user's name input.
  final TextEditingController nameController = TextEditingController();

  /// Controller for the user's date of birth input.
  final TextEditingController dateBirthController = TextEditingController();

  /// Controller for the mesocycle start date input.
  final TextEditingController dateMesoController = TextEditingController();

  /// Controller for the mesocycle duration input (in days).
  final TextEditingController durationMesoController = TextEditingController();

  /// The user provider containing profile data.
  late UserProvider _userProvider;

  /// The selected date used in date pickers.
  DateTime selectedDate = DateTime.now();

  /// The selected gender (default is 'male').
  String _gender = 'male';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  /// Displays a date picker and sets the result into the given [controller].
  Future<void> _selectDate(
      BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(1970, 1),
      lastDate: DateTime(2025, 12),
    );
    if (picked != null && picked != selectedDate) {
      controller.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  /// Loads user data from the [UserProvider] and populates the form fields.
  void _loadUserInfo() {
    _userProvider = Provider.of<UserProvider>(context, listen: false);
    setState(() {
      _gender = _userProvider.gender ?? 'male';
      dateBirthController.text = _userProvider.birthDate != null
          ? DateFormat('yyyy-MM-dd').format(_userProvider.birthDate!)
          : '';
      dateMesoController.text = _userProvider.mesocycleStartDate != null
          ? DateFormat('yyyy-MM-dd')
              .format(_userProvider.mesocycleStartDate!)
          : '';
      nameController.text = _userProvider.name ?? '';
      durationMesoController.text =
          _userProvider.mesocycleLength?.toString() ?? '';
    });
  }

  /// Validates and saves the form data into the [UserProvider].
  /// If it is the first login, navigates to the home page after saving.
  void _saveUserInfo() {
    bool firstLogin = _userProvider.firstLogin;
    if (_formKey.currentState!.validate()) {
      _userProvider.setUserData(
        newName: nameController.text,
        newGender: _gender,
        newBirthDate: dateBirthController.text,
        newMesoLength: int.parse(durationMesoController.text),
        newMesoStart: dateMesoController.text,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Center(
            child: Text(
              'Information saved correctly!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
      if (firstLogin) {
        Future.delayed(const Duration(seconds: 3), () {
          _toHomePage(context);
        });
      }
    }
  }

  /// Navigates to the home page, replacing the current route.
  void _toHomePage(BuildContext context) {
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (context) => const Home()));
  }

  /// Builds a styled [TextFormField] used in the profile form.
  ///
  /// [controller] is the field controller, [labelText] is the field label,
  /// [icon] is the leading icon, [validator] validates the input,
  /// and [onTap] can be used for custom tap behavior (e.g., date pickers).
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    required String? Function(String?) validator,
    VoidCallback? onTap,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 10,
        horizontal: 10,
      ),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          filled: true,
          fillColor: Theme.of(context).secondaryHeaderColor,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(100.0),
            borderSide: const BorderSide(color: Colors.transparent, width: 1),
          ),
          enabledBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(100.0)),
            borderSide: BorderSide(color: Colors.transparent, width: 1),
          ),
          focusedErrorBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(100.0)),
            borderSide: BorderSide(color: Colors.transparent, width: 1),
          ),
          errorBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(100.0)),
            borderSide: BorderSide(color: Colors.transparent, width: 1),
          ),
          prefixIcon:
              Icon(icon, color: Theme.of(context).primaryColor, size: 30),
          labelText: labelText,
          labelStyle: const TextStyle(fontSize: 20),
        ),
        validator: validator,
        onTap: onTap,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Theme.of(context).secondaryHeaderColor,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    'About you',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 5),

                  // Name input field with validation
                  _buildTextFormField(
                    controller: nameController,
                    labelText: 'Name',
                    icon: Icons.person,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Name is required';
                      }
                      if (value.length > 20) {
                        return 'Name can have max 20 characters';
                      }
                      return null;
                    },
                  ),

                  // Date of birth input field with date picker and validation
                  _buildTextFormField(
                    controller: dateBirthController,
                    labelText: 'Date of Birth',
                    icon: Icons.calendar_month_outlined,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Date of Birth is required';
                      }
                      int year = int.parse(value.substring(0, 4));
                      if (year < (DateTime.now().year - 100) ||
                          year > (DateTime.now().year - 12)) {
                        return 'Year of birth must be from ${(DateTime.now().year - 100)} to ${(DateTime.now().year - 12)}';
                      }
                      return null;
                    },
                    onTap: () => _selectDate(context, dateBirthController),
                  ),

                  // Gender dropdown with custom icons and validation
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 10,
                    ),
                    child: SizedBox(
                      height: 65,
                      child: DropdownButtonFormField(
                        isDense: false,
                        itemHeight: 50,
                        value: _gender,
                        validator: (value) {
                          if (value == null) {
                            return 'Biological sex is required';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Theme.of(context).secondaryHeaderColor,
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(100.0),
                            borderSide: const BorderSide(
                                color: Colors.transparent, width: 1),
                          ),
                          enabledBorder: const OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(100.0)),
                            borderSide:
                                BorderSide(color: Colors.transparent, width: 1),
                          ),
                          focusedErrorBorder: const OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(100.0)),
                            borderSide:
                                BorderSide(color: Colors.transparent, width: 1),
                          ),
                          errorBorder: const OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(100.0)),
                            borderSide:
                                BorderSide(color: Colors.transparent, width: 1),
                          ),
                        ),
                        items: [
                          // Male option
                          DropdownMenuItem(
                            value: 'male',
                            child: Row(
                              children: [
                                Icon(MdiIcons.genderMale,
                                    color: Theme.of(context).primaryColor,
                                    size: 35),
                                const Padding(
                                  padding: EdgeInsets.only(left: 5),
                                  child: Text(
                                    'Male',
                                    style: TextStyle(
                                      fontWeight: FontWeight.normal,
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Female option
                          DropdownMenuItem(
                            value: 'female',
                            child: Row(
                              children: [
                                Icon(MdiIcons.genderFemale,
                                    color: Theme.of(context).primaryColor,
                                    size: 35),
                                const Padding(
                                  padding: EdgeInsets.only(left: 5),
                                  child: Text(
                                    'Female',
                                    style: TextStyle(
                                      fontWeight: FontWeight.normal,
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _gender = value ?? _gender;
                          });
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Section title: About the training
                  Text(
                    'About the training',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 5),

                  // Mesocycle duration input with numeric validation
                  _buildTextFormField(
                    controller: durationMesoController,
                    labelText: 'Mesocycle duration (days)',
                    icon: Icons.av_timer,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Mesocycle duration is required';
                      }
                      int duration = int.parse(value);
                      if (duration > 100 || duration < 14) {
                        return 'Mesocycle duration must be from 14 to 100 days';
                      }
                      return null;
                    },
                  ),

                  // Mesocycle start date input with date picker
                  _buildTextFormField(
                    controller: dateMesoController,
                    labelText: 'Date of mesocycle start',
                    icon: Icons.play_arrow_rounded,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Date of mesocycle start is required';
                      }
                      return null;
                    },
                    onTap: () => _selectDate(context, dateMesoController),
                  ),

                  const SizedBox(height: 20),

                  // Save button to submit the form
                  Center(
                    child: ElevatedButton(
                      onPressed: _saveUserInfo,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Theme.of(context).secondaryHeaderColor,
                      ),
                      child: const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 5, vertical: 10),
                        child: Text(
                          'SAVE',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),

      // Navigation drawer shown only if it's not the user's first login
      drawer: _userProvider.firstLogin ? null : const NavDrawer(),
    );
  }
}
