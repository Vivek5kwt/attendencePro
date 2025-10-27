import 'package:flutter/material.dart';

enum DeviceType { small, medium, large, tablet }

class Responsive {
  Responsive(this.context);

  final BuildContext context;

  static Responsive of(BuildContext context) => Responsive(context);

  double get _width => MediaQuery.of(context).size.width;

  DeviceType get deviceType {
    final width = _width;
    if (width < 350) {
      return DeviceType.small;
    } else if (width < 600) {
      return DeviceType.medium;
    } else if (width < 900) {
      return DeviceType.large;
    } else {
      return DeviceType.tablet;
    }
  }

  double get textScaleFactor {
    switch (deviceType) {
      case DeviceType.small:
        return 0.9;
      case DeviceType.medium:
        return 1.0;
      case DeviceType.large:
        return 1.1;
      case DeviceType.tablet:
        return 1.25;
    }
  }

  double get _scaleFactor {
    switch (deviceType) {
      case DeviceType.small:
        return 0.9;
      case DeviceType.medium:
        return 1.0;
      case DeviceType.large:
        return 1.15;
      case DeviceType.tablet:
        return 1.3;
    }
  }

  double get _paddingFactor {
    switch (deviceType) {
      case DeviceType.small:
        return 0.85;
      case DeviceType.medium:
        return 1.0;
      case DeviceType.large:
        return 1.1;
      case DeviceType.tablet:
        return 1.25;
    }
  }

  double scaleText(double size) => size * textScaleFactor;

  double scale(double value) => value * _scaleFactor;

  EdgeInsets scaledPadding(double base) {
    final factor = _paddingFactor;
    return EdgeInsets.all(base * factor);
  }
}

extension ResponsiveContextX on BuildContext {
  Responsive get responsive => Responsive(this);
}
