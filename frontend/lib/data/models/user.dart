/// Account type. Drivers use the consumer parking app; operators get the
/// admin dashboard + offline ticket scanner.
enum PFUserRole {
  driver,
  operator;

  String get label => this == PFUserRole.operator ? 'Operator' : 'Driver';

  static PFUserRole fromName(String? name) =>
      PFUserRole.values.firstWhere((r) => r.name == name,
          orElse: () => PFUserRole.driver);
}

class PFUser {
  PFUser({
    required this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
    this.role = PFUserRole.driver,
    this.avatarSeed = 0,
    this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final String passwordHash;
  final PFUserRole role;
  final int avatarSeed;
  final DateTime? createdAt;

  bool get isOperator => role == PFUserRole.operator;

  PFUser copyWith({String? name, String? email, int? avatarSeed}) => PFUser(
        id: id,
        name: name ?? this.name,
        email: email ?? this.email,
        passwordHash: passwordHash,
        role: role,
        avatarSeed: avatarSeed ?? this.avatarSeed,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'passwordHash': passwordHash,
        'role': role.name,
        'avatarSeed': avatarSeed,
        'createdAt': createdAt?.toIso8601String(),
      };

  factory PFUser.fromJson(Map<String, dynamic> json) => PFUser(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        passwordHash: json['passwordHash'] as String,
        role: PFUserRole.fromName(json['role'] as String?),
        avatarSeed: (json['avatarSeed'] as num?)?.toInt() ?? 0,
        createdAt: json['createdAt'] is String
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
      );

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'P';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}
