import 'package:flutter/material.dart';

enum DeviceType { small, medium, large, tablet }

class Responsive {
  Responsive(this.context);

  final BuildContext context;

  static Responsive of(BuildContext context) => Responsive(context);

  double get _width => MediaQuery.of(context).size.width;
  double get _height => MediaQuery.of(context).size.height;

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

  double scaleHeight(double value, {double baseHeight = 812}) {
    if (baseHeight == 0) {
      return value;
    }
    final scaled = (value / baseHeight) * _height;
    return scale(scaled);
  }

  double scaleWidth(double value, {double baseWidth = 375}) {
    if (baseWidth == 0) {
      return value;
    }
    final scaled = (value / baseWidth) * _width;
    return scale(scaled);
  }

  double heightFraction(double fraction) => _height * fraction;

  double widthFraction(double fraction) => _width * fraction;

  EdgeInsets scaledPadding(double base) {
    final factor = _paddingFactor;
    return EdgeInsets.all(base * factor);
  }

  EdgeInsets scaledSymmetric({double horizontal = 0, double vertical = 0}) {
    final factor = _paddingFactor;
    return EdgeInsets.symmetric(
      horizontal: horizontal * factor,
      vertical: vertical * factor,
    );
  }

  EdgeInsets scaledOnly({
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  }) {
    final factor = _paddingFactor;
    return EdgeInsets.only(
      left: left * factor,
      top: top * factor,
      right: right * factor,
      bottom: bottom * factor,
    );
  }
}

extension ResponsiveContextX on BuildContext {
  Responsive get responsive => Responsive(this);
}

extension ResponsiveNumX on num {
  double scaled(BuildContext context) => context.responsive.scale(toDouble());

  double scaledText(BuildContext context) =>
      context.responsive.scaleText(toDouble());

  double scaledHeight(BuildContext context, {double baseHeight = 812}) =>
      context.responsive
          .scaleHeight(toDouble(), baseHeight: baseHeight);

  double scaledWidth(BuildContext context, {double baseWidth = 375}) =>
      context.responsive.scaleWidth(toDouble(), baseWidth: baseWidth);
}

extension ResponsiveEdgeInsetsX on EdgeInsets {
  EdgeInsets scaled(BuildContext context) {
    final responsive = context.responsive;
    return EdgeInsets.only(
      left: responsive.scale(left),
      top: responsive.scale(top),
      right: responsive.scale(right),
      bottom: responsive.scale(bottom),
    );
  }

  EdgeInsets scaledSymmetric(BuildContext context) {
    final responsive = context.responsive;
    return EdgeInsets.symmetric(
      horizontal: responsive.scale(left + right) / 2,
      vertical: responsive.scale(top + bottom) / 2,
    );
  }
}
