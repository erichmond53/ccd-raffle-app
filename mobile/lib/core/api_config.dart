/// Build-time config for the WordPress REST API this app talks to.
///
/// Pass these at build/run time, e.g.:
///   flutter run --dart-define=CCD_API_KEY=xxxxx --dart-define=DEVICE_ID=staff-phone-1
class ApiConfig {
  static const String baseUrl = 'https://carsandcoffeedarien.com/wp-json/ccd-raffle/v1';

  static const String apiKey = String.fromEnvironment('CCD_API_KEY', defaultValue: '');

  static const String deviceId = String.fromEnvironment('DEVICE_ID', defaultValue: 'unknown-device');
}
