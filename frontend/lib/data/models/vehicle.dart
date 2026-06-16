import 'package:flutter/material.dart';

enum VehicleType {
  car('Car', Icons.directions_car_rounded),
  suv('SUV', Icons.directions_car_filled_rounded),
  ev('EV', Icons.bolt_rounded),
  bike('Bike', Icons.two_wheeler_rounded),
  truck('Truck', Icons.local_shipping_rounded);

  const VehicleType(this.label, this.icon);
  final String label;
  final IconData icon;
}

class PFVehicle {
  PFVehicle({
    required this.id,
    required this.name,
    required this.plate,
    required this.type,
    required this.colorValue,
    this.notes = '',
    this.isFavorite = false,
  });

  final String id;
  final String name;
  final String plate;
  final VehicleType type;
  final int colorValue;
  final String notes;
  final bool isFavorite;

  Color get color => Color(colorValue);

  PFVehicle copyWith({
    String? name,
    String? plate,
    VehicleType? type,
    int? colorValue,
    String? notes,
    bool? isFavorite,
  }) =>
      PFVehicle(
        id: id,
        name: name ?? this.name,
        plate: plate ?? this.plate,
        type: type ?? this.type,
        colorValue: colorValue ?? this.colorValue,
        notes: notes ?? this.notes,
        isFavorite: isFavorite ?? this.isFavorite,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'plate': plate,
        'type': type.name,
        'colorValue': colorValue,
        'notes': notes,
        'isFavorite': isFavorite,
      };

  factory PFVehicle.fromJson(Map<String, dynamic> json) => PFVehicle(
        id: json['id'] as String,
        name: json['name'] as String,
        plate: json['plate'] as String,
        type: VehicleType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => VehicleType.car,
        ),
        colorValue: (json['colorValue'] as num).toInt(),
        notes: (json['notes'] as String?) ?? '',
        isFavorite: (json['isFavorite'] as bool?) ?? false,
      );
}
