enum BookingStatus { upcoming, active, completed, expired, cancelled }

class PFBooking {
  PFBooking({
    required this.id,
    required this.slotId,
    required this.slotLabel,
    required this.floor,
    required this.vehicleId,
    required this.vehicleName,
    required this.vehiclePlate,
    required this.startTime,
    required this.endTime,
    required this.feeCents,
    required this.status,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String slotId;
  final String slotLabel;
  final int floor;
  final String vehicleId;
  final String vehicleName;
  final String vehiclePlate;
  final DateTime startTime;
  final DateTime endTime;
  final int feeCents;
  BookingStatus status;
  final DateTime createdAt;

  Duration get duration => endTime.difference(startTime);
  Duration remaining(DateTime now) {
    if (now.isAfter(endTime)) return Duration.zero;
    if (now.isBefore(startTime)) return startTime.difference(now);
    return endTime.difference(now);
  }

  PFBooking copyWith({BookingStatus? status, DateTime? endTime, int? feeCents}) =>
      PFBooking(
        id: id,
        slotId: slotId,
        slotLabel: slotLabel,
        floor: floor,
        vehicleId: vehicleId,
        vehicleName: vehicleName,
        vehiclePlate: vehiclePlate,
        startTime: startTime,
        endTime: endTime ?? this.endTime,
        feeCents: feeCents ?? this.feeCents,
        status: status ?? this.status,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'slotId': slotId,
        'slotLabel': slotLabel,
        'floor': floor,
        'vehicleId': vehicleId,
        'vehicleName': vehicleName,
        'vehiclePlate': vehiclePlate,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'feeCents': feeCents,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory PFBooking.fromJson(Map<String, dynamic> json) => PFBooking(
        id: json['id'] as String,
        slotId: json['slotId'] as String,
        slotLabel: json['slotLabel'] as String,
        floor: (json['floor'] as num).toInt(),
        vehicleId: json['vehicleId'] as String,
        vehicleName: json['vehicleName'] as String,
        vehiclePlate: json['vehiclePlate'] as String,
        startTime: DateTime.parse(json['startTime'] as String),
        endTime: DateTime.parse(json['endTime'] as String),
        feeCents: (json['feeCents'] as num).toInt(),
        status: BookingStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => BookingStatus.completed,
        ),
        createdAt: json['createdAt'] is String
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
      );
}
