import 'package:flutter/material.dart';
import 'package:flutter_onboarding_slider/flutter_onboarding_slider.dart';
import 'package:provider/provider.dart';
import 'package:simfit/providers/user_provider.dart';
import 'package:simfit/screens/login.dart';
import 'package:simfit/screens/info.dart';

/// The OnBoarding screen displays a three-page introductory slider
/// to familiarize the user with the app features. Once completed,
/// it marks onboarding as completed and navigates to the Login screen.
class OnBoarding extends StatelessWidget {
  const OnBoarding({super.key});

  /// Helper method to build content for each onboarding page
  Widget _buildPageBody({
    required BuildContext context,
    required String title,
    required String description,
    required double spacing,
  }) {
    return Container(
      alignment: Alignment.center,
      width: MediaQuery.of(context).size.width * 0.9,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          SizedBox(height: spacing),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontSize: 30.0,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 24.0,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: OnBoardingSlider(
        // Text displayed on the final button
        finishButtonText: 'LOG IN',

        // Action when the onboarding is finished
        onFinish: () async {
          await Provider.of<UserProvider>(context, listen: false).onboardUser();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const Login()),
          );
        },

        // Styling for the final button
        finishButtonStyle: FinishButtonStyle(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Theme.of(context).secondaryHeaderColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),

        // "Skip" text button shown on top right
        skipTextButton: Text(
          'Skip',
          style: TextStyle(
            fontSize: 20,
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),

        // "Learn more" trailing text on bottom
        trailing: Text(
          'Learn more',
          style: TextStyle(
            fontSize: 20,
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),

        // Function to navigate to the info page
        trailingFunction: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const Info()),
          );
        },

        // Slider appearance and behavior
        controllerColor: Theme.of(context).primaryColor,
        totalPage: 3,
        speed: 1.8,
        centerBackground: true,
        headerBackgroundColor: Colors.white,
        pageBackgroundColor: Colors.white,

        // Images shown for each slide
        background: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Image.asset('assets/allenamento1.png', height: 400),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Image.asset('assets/grafico2.jpg', height: 400),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Image.asset('assets/ciclista.jpg', height: 400),
          ),
        ],

        // Page bodies corresponding to each background
        pageBodies: [
          _buildPageBody(
            context: context,
            title: 'Track',
            description:
                'Keep track of your training data collected by your Fitbit watch',
            spacing: 420,
          ),
          _buildPageBody(
            context: context,
            title: 'Simulate',
            description:
                'Visualize your training load and simulate training sessions that suit your goals',
            spacing: 420,
          ),
          _buildPageBody(
            context: context,
            title: 'Train',
            description:
                'Tune the progress of your performance and start!',
            spacing: 420,
          ),
        ],
      ),
    );
  }
}
