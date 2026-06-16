enum SlotStatus { available, occupied, reserved, selected, disabled }

enum SlotSize { compact, standard, large }

class PFSlot {
  PFSlot({
    required this.id,
    required this.floor,
    required this.row,
    required this.col,
    required this.label,
    required this.status,
    this.size = SlotSize.standard,
    this.hasCharger = false,
    this.disabledAccess = false,
    this.walkingDistance = 0,
    this.score = 0.0,
  });

  final String id;
  final int floor;
  final int row;
  final int col;
  final String label;
  SlotStatus status;
  final SlotSize size;
  final bool hasCharger;
  final bool disabledAccess;
  final int walkingDistance; // meters
  final double score; // recommendation score 0-1

  PFSlot copyWith({SlotStatus? status}) => PFSlot(
        id: id,
        floor: floor,
        row: row,
        col: col,
        label: label,
        status: status ?? this.status,
        size: size,
        hasCharger: hasCharger,
        disabledAccess: disabledAccess,
        walkingDistance: walkingDistance,
        score: score,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'floor': floor,
        'row': row,
        'col': col,
        'label': label,
        'status': status.name,
        'size': size.name,
        'hasCharger': hasCharger,
        'disabledAccess': disabledAccess,
        'walkingDistance': walkingDistance,
        'score': score,
      };

  factory PFSlot.fromJson(Map<String, dynamic> json) => PFSlot(
        id: json['id'] as String,
        floor: (json['floor'] as num).toInt(),
        row: (json['row'] as num).toInt(),
        col: (json['col'] as num).toInt(),
        label: json['label'] as String,
        status: SlotStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => SlotStatus.available,
        ),
        size: SlotSize.values.firstWhere(
          (s) => s.name == json['size'],
          orElse: () => SlotSize.standard,
        ),
        hasCharger: (json['hasCharger'] as bool?) ?? false,
        disabledAccess: (json['disabledAccess'] as bool?) ?? false,
        walkingDistance: (json['walkingDistance'] as num?)?.toInt() ?? 0,
        score: (json['score'] as num?)?.toDouble() ?? 0.0,
      );
}
