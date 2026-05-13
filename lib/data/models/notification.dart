enum PFNotificationType { reservation, expiry, confirmation, system, navigation }

class PFNotification {
  PFNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.read = false,
    this.bookingId,
  });

  final String id;
  final String title;
  final String body;
  final PFNotificationType type;
  final DateTime createdAt;
  bool read;
  final String? bookingId;

  PFNotification copyWith({bool? read}) => PFNotification(
        id: id,
        title: title,
        body: body,
        type: type,
        createdAt: createdAt,
        read: read ?? this.read,
        bookingId: bookingId,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'type': type.name,
        'createdAt': createdAt.toIso8601String(),
        'read': read,
        'bookingId': bookingId,
      };

  factory PFNotification.fromJson(Map<String, dynamic> json) => PFNotification(
        id: json['id'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        type: PFNotificationType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => PFNotificationType.system,
        ),
        createdAt: DateTime.parse(json['createdAt'] as String),
        read: (json['read'] as bool?) ?? false,
        bookingId: json['bookingId'] as String?,
      );
}
