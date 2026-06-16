/// Outcome of validating a ticket QR at the gate scanner.
enum ScanResult {
  valid,
  alreadyUsed,
  expired,
  invalid;

  String get label => switch (this) {
        ScanResult.valid => 'Valid',
        ScanResult.alreadyUsed => 'Already used',
        ScanResult.expired => 'Expired',
        ScanResult.invalid => 'Invalid',
      };

  bool get isSuccess => this == ScanResult.valid;
}

/// A single scan logged in the operator's offline scan history.
class PFScanEvent {
  PFScanEvent({
    required this.id,
    required this.result,
    required this.scannedAt,
    this.ticketId,
    this.slotLabel,
    this.vehiclePlate,
    this.rawCode,
  });

  final String id;
  final ScanResult result;
  final DateTime scannedAt;
  final String? ticketId;
  final String? slotLabel;
  final String? vehiclePlate;
  final String? rawCode;

  Map<String, dynamic> toJson() => {
        'id': id,
        'result': result.name,
        'scannedAt': scannedAt.toIso8601String(),
        'ticketId': ticketId,
        'slotLabel': slotLabel,
        'vehiclePlate': vehiclePlate,
        'rawCode': rawCode,
      };

  factory PFScanEvent.fromJson(Map<String, dynamic> json) => PFScanEvent(
        id: json['id'] as String,
        result: ScanResult.values.firstWhere(
          (r) => r.name == json['result'],
          orElse: () => ScanResult.invalid,
        ),
        scannedAt: DateTime.parse(json['scannedAt'] as String),
        ticketId: json['ticketId'] as String?,
        slotLabel: json['slotLabel'] as String?,
        vehiclePlate: json['vehiclePlate'] as String?,
        rawCode: json['rawCode'] as String?,
      );
}
