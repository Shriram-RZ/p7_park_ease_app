/// App-wide constants for ParkFlow.
class PFConstants {
  PFConstants._();

  static const String appName = 'ParkFlow';
  static const String appTagline = 'Smart Offline Parking';

  // Parking simulation tuning.
  static const int floorsCount = 4;
  static const int slotsPerFloor = 36; // 6 x 6 grid per floor.
  static const Duration simulationTick = Duration(seconds: 3);

  // Offline fee simulation (per hour, in chosen currency unit).
  static const double feePerHour = 40.0;
  static const String currencySymbol = '₹'; // ₹

  // Backend base URL. Override locally with:
  //   flutter run --dart-define=API_BASE_URL=http://localhost:5000
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://parkeasebackend-production.up.railway.app',
  );
}
