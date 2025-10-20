import 'package:attendancepro/screens/walkthrough_screen.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const WalkthroughScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ✅ Background image
          Image.asset(
            'assets/images/Splash (2).png', // <-- Use your blue+white curve background image
            fit: BoxFit.cover,
          ),

         /* // ✅ Center content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/logo_splash.png', // <-- Use your calendar/clock logo
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
                  'AttendancePro',
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
