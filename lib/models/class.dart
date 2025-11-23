// lib/models/class.dart

class Class {
  final int id;
  final String className;

  Class({required this.id, required this.className});

  factory Class.fromJson(Map<String, dynamic> json) {
    return Class(id: json['id'], className: json['class_name']);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'class_name': className};
  }
}
