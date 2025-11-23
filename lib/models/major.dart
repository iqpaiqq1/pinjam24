// lib/models/major.dart

class Major {
  final int id;
  final String majorName;

  Major({required this.id, required this.majorName});

  factory Major.fromJson(Map<String, dynamic> json) {
    return Major(id: json['id'], majorName: json['major_name']);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'major_name': majorName};
  }
}
