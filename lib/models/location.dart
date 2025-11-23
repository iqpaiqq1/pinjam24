// lib/models/location.dart

class Location {
  final int id;
  final String locationName;

  Location({required this.id, required this.locationName});

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(id: json['id'], locationName: json['location_name']);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'location_name': locationName};
  }
}
