class AppConfig {
  /// Debounce duration to prevent excessive syncs
  /// when user returns to the app from background
  static const syncDebounceDuration = Duration(seconds: 60);
}
