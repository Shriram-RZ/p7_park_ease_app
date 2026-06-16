enum TicketStatus { active, used, expired, invalid }

class PFTicket {
  PFTicket({
    required this.id,
    required this.bookingId,
    required this.slotLabel,
    required this.floor,
    required this.vehiclePlate,
    required this.qrPayload,
    required this.issuedAt,
    required this.expiresAt,
    required this.status,
  });

  final String id;
  final String bookingId;
  final String slotLabel;
  final int floor;
  final String vehiclePlate;
  final String qrPayload;
  final DateTime issuedAt;
  final DateTime expiresAt;
  TicketStatus status;

  PFTicket copyWith({TicketStatus? status}) => PFTicket(
        id: id,
        bookingId: bookingId,
        slotLabel: slotLabel,
        floor: floor,
        vehiclePlate: vehiclePlate,
        qrPayload: qrPayload,
        issuedAt: issuedAt,
        expiresAt: expiresAt,
        status: status ?? this.status,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'bookingId': bookingId,
        'slotLabel': slotLabel,
        'floor': floor,
        'vehiclePlate': vehiclePlate,
        'qrPayload': qrPayload,
        'issuedAt': issuedAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
        'status': status.name,
      };

  factory PFTicket.fromJson(Map<String, dynamic> json) => PFTicket(
        id: json['id'] as String,
        bookingId: json['bookingId'] as String,
        slotLabel: json['slotLabel'] as String,
        floor: (json['floor'] as num).toInt(),
        vehiclePlate: json['vehiclePlate'] as String,
        qrPayload: json['qrPayload'] as String,
        issuedAt: DateTime.parse(json['issuedAt'] as String),
        expiresAt: DateTime.parse(json['expiresAt'] as String),
        status: TicketStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => TicketStatus.active,
        ),
      );
}
