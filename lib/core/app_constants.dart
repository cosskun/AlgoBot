/// Central application constants and configurations
class AppConstants {
  AppConstants._();

  static const String appName = 'AlgoKids';
  static const String appVersion = '1.0.0';

  // Interpreter & Execution
  static const int maxExecutionSteps = 200;
  static const int defaultStepDelayMs = 450;
  static const int slowStepDelayMs = 750;
  static const int fastStepDelayMs = 220;

  // Grid Defaults
  static const int defaultGridCols = 5;
  static const int defaultGridRows = 5;

  // Workspace
  static const int defaultMaxBlocks = 24;

  // Storage
  static const String defaultAvatarId = 'classic_robi';
  static const String defaultLanguageCode = 'tr';
}
