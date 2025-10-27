import 'package:flutter/material.dart';

import '../core/constants/app_assets.dart';
import '../utils/responsive.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    return Scaffold(
      backgroundColor: Colors.blue,
      body: SizedBox(
        width: responsive.widthFraction(1),
        height: responsive.heightFraction(1),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: Image.asset(
                AppAssets.splashBackground,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
