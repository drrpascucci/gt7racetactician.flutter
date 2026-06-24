import '../config/app_config.dart';

class UiConstants {
  static const double compactBigFontSize = 46;
  static const double tabletBigFontSize = 36;
  static const double smallFontSize = 16;
  /// Returns the appropriate big font size based on the visualization mode.
  static double getBigFontSize(DashboardViewMode mode) {
    return mode == DashboardViewMode.tablet ? tabletBigFontSize : compactBigFontSize;
  }
}
