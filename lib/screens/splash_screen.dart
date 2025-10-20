import 'package:flutter/material.dart';

import '../core/constants/app_assets.dart';
import '../core/constants/app_strings.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ✅ Background image
          Image.asset(
            AppAssets.splashBackground, // <-- Use your blue+white curve background image
            fit: BoxFit.cover,
          ),

         /* // ✅ Center content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  AppAssets.splashLogo, // <-- Use your calendar/clock logo
                  width: 140,
                  height: 140,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.calendar_month,
                      size: 100,
                      color: Colors.white,
                    );
                  },
                ),
                const SizedBox(height: 20),
                const Text(
                  AppStrings.splashTitle,
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),*/
        ],
      ),
    );
  }
}
