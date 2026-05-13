import 'dart:math';

import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/storage.dart';
import '../data/models/booking.dart';
import '../data/models/notification.dart';
import '../data/models/parking_slot.dart';
import '../data/models/ticket.dart';
import '../data/models/user.dart';
import '../data/models/vehicle.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/booking_repository.dart';
import '../data/repositories/notification_repository.dart';
import '../data/repositories/parking_repository.dart';
import '../data/repositories/ticket_repository.dart';
import '../data/repositories/vehicle_repository.dart';
import '../data/services/simulation_service.dart';

/// Single source of truth for the running app. Combines repositories with
/// a ChangeNotifier so any widget can subscribe via [AnimatedBuilder] or
/// [ListenableBuilder]. Keeps the surface area small without pulling in a
/// heavier state-management package.
class AppState extends ChangeNotifier {
  AppState({
    required this.storage,
    required this.auth,
    required this.vehicles,
    required this.parking,
    required this.bookings,
    required this.tickets,
    required this.notifications,
    required this.simulation,
  }) {
    _themeMode = _resolveThemeMode();
    _reduceMotion = storage.getBool(StorageKeys.reduceMotion);
    simulation.addListener(_onSimTick);
    simulation.start();
  }

  static Future<AppState> bootstrap() async {
    final storage = await LocalStorage.instance();
    final auth = AuthRepository(storage);
    final vehicles = VehicleRepository(storage);
    final parking = ParkingRepository(storage);
    final bookings = BookingRepository(storage);
    final tickets = TicketRepository(storage);
    final notifications = NotificationRepository(storage);
    final simulation = SimulationService(parking);

    await vehicles.seedIfEmpty();
    await bookings.seedIfEmpty();
    await notifications.seedIfEmpty();

    return AppState(
      storage: storage,
      auth: auth,
      vehicles: vehicles,
      parking: parking,
      bookings: bookings,
      tickets: tickets,
      notifications: notifications,
      simulation: simulation,
    );
  }

  final LocalStorage storage;
  final AuthRepository auth;
  final VehicleRepository vehicles;
  final ParkingRepository parking;
  final BookingRepository bookings;
  final TicketRepository tickets;
  final NotificationRepository notifications;
  final SimulationService simulation;

  late ThemeMode _themeMode;
  ThemeMode get themeMode => _themeMode;

  bool _reduceMotion = false;
  bool get reduceMotion => _reduceMotion;

  PFUser? get currentUser => auth.currentUser();
  bool get onboardingComplete =>
      storage.getBool(StorageKeys.onboardingComplete, defaultValue: false);

  ThemeMode _resolveThemeMode() {
    final raw = storage.getString(StorageKeys.themeMode);
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.dark;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await storage.setString(
      StorageKeys.themeMode,
      mode == ThemeMode.dark
          ? 'dark'
          : mode == ThemeMode.light
              ? 'light'
              : 'system',
    );
    notifyListeners();
  }

  Future<void> setReduceMotion(bool value) async {
    _reduceMotion = value;
    await storage.setBool(StorageKeys.reduceMotion, value);
    notifyListeners();
  }

  void setSimulationPeakMode(bool value) {
    simulation.peakMode = value;
    notifyListeners();
  }

  void pulseSimulation() {
    simulation.pulse();
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    await storage.setBool(StorageKeys.onboardingComplete, true);
    notifyListeners();
  }

  void _onSimTick() => notifyListeners();

  // ---------- Vehicle operations ----------

  Future<void> addVehicle(PFVehicle vehicle) async {
    await vehicles.add(vehicle);
    notifyListeners();
  }

  Future<void> updateVehicle(PFVehicle vehicle) async {
    await vehicles.update(vehicle);
    notifyListeners();
  }

  Future<void> removeVehicle(String id) async {
    await vehicles.remove(id);
    notifyListeners();
  }

  Future<void> setActiveVehicle(String id) async {
    await vehicles.setActive(id);
    notifyListeners();
  }

  // ---------- Booking operations ----------

  Future<({PFBooking booking, PFTicket ticket})> reserveSlot({
    required PFSlot slot,
    required PFVehicle vehicle,
    required Duration duration,
  }) async {
    final now = DateTime.now();
    final end = now.add(duration);
    final hours = duration.inMinutes / 60.0;
    final feeCents = (PFConstants.feePerHour * hours * 100).round();
    final id = 'b_${now.millisecondsSinceEpoch}_${Random().nextInt(9999)}';
    final booking = PFBooking(
      id: id,
      slotId: slot.id,
      slotLabel: slot.label,
      floor: slot.floor,
      vehicleId: vehicle.id,
      vehicleName: vehicle.name,
      vehiclePlate: vehicle.plate,
      startTime: now,
      endTime: end,
      feeCents: feeCents,
      status: BookingStatus.active,
    );
    final ticket = PFTicket(
      id: 'T-${id.substring(2, 10).toUpperCase()}',
      bookingId: id,
      slotLabel: slot.label,
      floor: slot.floor,
      vehiclePlate: vehicle.plate,
      qrPayload:
          'PARKFLOW|${booking.id}|${slot.label}|${vehicle.plate}|${end.millisecondsSinceEpoch}',
      issuedAt: now,
      expiresAt: end,
      status: TicketStatus.active,
    );
    await bookings.add(booking);
    await tickets.add(ticket);
    parking.reserve(slot.id);
    await notifications.add(PFNotification(
      id: 'n_${now.millisecondsSinceEpoch}',
      title: 'Reservation confirmed',
      body: 'Slot ${slot.label} on Level F${slot.floor} is yours.',
      type: PFNotificationType.confirmation,
      createdAt: now,
      bookingId: id,
    ));
    notifyListeners();
    return (booking: booking, ticket: ticket);
  }

  Future<void> cancelBooking(PFBooking booking) async {
    await bookings.update(booking.copyWith(status: BookingStatus.cancelled));
    parking.free(booking.slotId);
    notifyListeners();
  }

  Future<void> extendBooking(PFBooking booking, Duration extra) async {
    final updated = booking.copyWith(
      endTime: booking.endTime.add(extra),
      feeCents: booking.feeCents +
          (PFConstants.feePerHour * (extra.inMinutes / 60.0) * 100).round(),
    );
    await bookings.update(updated);
    notifyListeners();
  }

  // ---------- Notifications ----------

  Future<void> markNotificationsRead() async {
    await notifications.markAllRead();
    notifyListeners();
  }

  Future<void> markNotificationRead(String id) async {
    await notifications.markRead(id);
    notifyListeners();
  }

  // ---------- Auth ----------

  Future<void> signOut() async {
    await auth.signOut();
    notifyListeners();
  }

  @override
  void dispose() {
    simulation.removeListener(_onSimTick);
    simulation.stop();
    super.dispose();
  }
}

/// Inherited widget that exposes [AppState] to descendants. Lightweight DI
/// without an extra package.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({
    super.key,
    required AppState state,
    required super.child,
  }) : super(notifier: state);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found in widget tree');
    return scope!.notifier!;
  }

  static AppState read(BuildContext context) {
    final scope =
        context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found in widget tree');
    return scope!.notifier!;
  }
}
