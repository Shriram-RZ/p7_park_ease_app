// Live integration smoke test for the ParkFlow API layer.
// Requires the backend running and reachable. Run with:
//   flutter test --dart-define=API_BASE_URL=http://localhost:5000 \
//     test/backend_integration_test.dart
//
// Exercises the real ApiClient + model JSON round-trips the app uses.
import 'package:flutter_test/flutter_test.dart';
import 'package:park_ease/core/constants.dart';
import 'package:park_ease/data/api/api_client.dart';
import 'package:park_ease/data/models/vehicle.dart';
import 'package:park_ease/data/models/booking.dart';
import 'package:park_ease/data/models/ticket.dart';

void main() {
  final api = ApiClient(baseUrl: PFConstants.apiBaseUrl);
  final stamp = DateTime.now().millisecondsSinceEpoch;
  final email = 'it_$stamp@pf.test';

  test('signup -> vehicle -> booking -> ticket validate', () async {
    // Sign up and capture token.
    final signup = await api.post('/api/auth/signup', {
      'name': 'IT User',
      'email': email,
      'password': 'secret',
      'role': 'operator',
    }) as Map<String, dynamic>;
    api.token = signup['token'] as String;
    expect(api.token, isNotEmpty);

    // Add a vehicle via the real model and read it back.
    final vehicle = PFVehicle(
      id: 'v_$stamp',
      name: 'Aurora EV',
      plate: 'PF-2042',
      type: VehicleType.ev,
      colorValue: 0xFF22C55E,
    );
    await api.post('/api/vehicles', vehicle.toJson());
    final vRes = await api.get('/api/vehicles') as Map<String, dynamic>;
    final vehicles = (vRes['items'] as List)
        .map((e) => PFVehicle.fromJson(e as Map<String, dynamic>))
        .toList();
    expect(vehicles.any((v) => v.id == vehicle.id && v.type == VehicleType.ev),
        isTrue);

    // Create a booking + ticket.
    final now = DateTime.now();
    final booking = PFBooking(
      id: 'b_$stamp',
      slotId: 'F1_R0C0',
      slotLabel: 'F1-A1',
      floor: 1,
      vehicleId: vehicle.id,
      vehicleName: vehicle.name,
      vehiclePlate: vehicle.plate,
      startTime: now,
      endTime: now.add(const Duration(hours: 1)),
      feeCents: 37350,
      status: BookingStatus.active,
    );
    await api.post('/api/bookings', booking.toJson());
    final bookings = (await api.get('/api/bookings') as List)
        .map((e) => PFBooking.fromJson(e as Map<String, dynamic>))
        .toList();
    expect(bookings.any((b) => b.id == booking.id), isTrue);

    final ticket = PFTicket(
      id: 'T_$stamp',
      bookingId: booking.id,
      slotLabel: booking.slotLabel,
      floor: booking.floor,
      vehiclePlate: booking.vehiclePlate,
      qrPayload: 'PARKFLOW|${booking.id}|${booking.slotLabel}',
      issuedAt: now,
      expiresAt: now.add(const Duration(hours: 1)),
      status: TicketStatus.active,
    );
    await api.post('/api/tickets', ticket.toJson());

    // Validate: first valid, then alreadyUsed.
    final first =
        await api.post('/api/tickets/validate', {'code': ticket.qrPayload})
            as Map<String, dynamic>;
    expect(first['result'], 'valid');
    final second =
        await api.post('/api/tickets/validate', {'code': ticket.qrPayload})
            as Map<String, dynamic>;
    expect(second['result'], 'alreadyUsed');
  });

  test('invalid credentials are rejected', () async {
    expect(
      () => api.post('/api/auth/signin', {'email': email, 'password': 'wrong'}),
      throwsA(isA<ApiException>()),
    );
  });
}
