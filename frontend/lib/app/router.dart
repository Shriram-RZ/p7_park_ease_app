import 'package:flutter/material.dart';

import '../data/models/booking.dart';
import '../data/models/parking_slot.dart';
import '../data/models/ticket.dart';
import '../features/admin/admin_dashboard_screen.dart';
import '../features/analytics/analytics_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/pin_setup_screen.dart';
import '../features/auth/signup_screen.dart';
import '../features/booking/booking_flow_screen.dart';
import '../features/booking/booking_success_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/history/history_screen.dart';
import '../features/main_shell/main_shell.dart';
import '../features/navigation/navigation_screen.dart';
import '../features/notifications/notifications_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/parking_map/parking_map_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/splash/splash_screen.dart';
import '../features/tickets/qr_scanner_screen.dart';
import '../features/tickets/tickets_screen.dart';
import '../features/vehicles/add_vehicle_screen.dart';
import '../features/vehicles/vehicles_screen.dart';

class AppRoutes {
  AppRoutes._();
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const signup = '/signup';
  static const pinSetup = '/pin';
  static const mainShell = '/main';
  static const adminShell = '/admin';
  static const dashboard = '/dashboard';
  static const parkingMap = '/parking-map';
  static const bookingFlow = '/booking';
  static const bookingSuccess = '/booking/success';
  static const navigation = '/navigate';
  static const tickets = '/tickets';
  static const scanner = '/tickets/scan';
  static const vehicles = '/vehicles';
  static const addVehicle = '/vehicles/add';
  static const history = '/history';
  static const analytics = '/analytics';
  static const notifications = '/notifications';
  static const settings = '/settings';
}

Route<dynamic>? appOnGenerateRoute(RouteSettings settings) {
  Widget builder(Widget Function() create) => create();

  switch (settings.name) {
    case AppRoutes.splash:
      return _fade(const SplashScreen());
    case AppRoutes.onboarding:
      return _shared(const OnboardingScreen());
    case AppRoutes.login:
      return _shared(const LoginScreen());
    case AppRoutes.signup:
      return _shared(const SignupScreen());
    case AppRoutes.pinSetup:
      final args = settings.arguments as Map<String, dynamic>?;
      return _shared(PinSetupScreen(mode: args?['mode'] as String? ?? 'create'));
    case AppRoutes.mainShell:
      return _fade(const MainShell());
    case AppRoutes.adminShell:
      return _fade(const AdminDashboardScreen());
    case AppRoutes.dashboard:
      return _shared(const DashboardScreen());
    case AppRoutes.parkingMap:
      return _shared(const ParkingMapScreen());
    case AppRoutes.bookingFlow:
      final slot = settings.arguments as PFSlot;
      return _shared(BookingFlowScreen(slot: slot));
    case AppRoutes.bookingSuccess:
      final result =
          settings.arguments as ({PFBooking booking, PFTicket ticket});
      return _shared(BookingSuccessScreen(
        booking: result.booking,
        ticket: result.ticket,
      ));
    case AppRoutes.navigation:
      return _shared(NavigationScreen(slot: settings.arguments as PFSlot?));
    case AppRoutes.tickets:
      return _shared(const TicketsScreen());
    case AppRoutes.scanner:
      return _shared(const QrScannerScreen());
    case AppRoutes.vehicles:
      return _shared(const VehiclesScreen());
    case AppRoutes.addVehicle:
      return _shared(const AddVehicleScreen());
    case AppRoutes.history:
      return _shared(const HistoryScreen());
    case AppRoutes.analytics:
      return _shared(const AnalyticsScreen());
    case AppRoutes.notifications:
      return _shared(const NotificationsScreen());
    case AppRoutes.settings:
      return _shared(const SettingsScreen());
  }
  builder; // suppress unused warning
  return null;
}

PageRoute<T> _shared<T>(Widget page) => PageRouteBuilder<T>(
      pageBuilder: (_, _, _) => page,
      transitionDuration: const Duration(milliseconds: 380),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      transitionsBuilder: (_, anim, _, child) {
        final curved =
            CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );

PageRoute<T> _fade<T>(Widget page) => PageRouteBuilder<T>(
      pageBuilder: (_, _, _) => page,
      transitionDuration: const Duration(milliseconds: 480),
      transitionsBuilder: (_, anim, _, child) =>
          FadeTransition(opacity: anim, child: child),
    );
