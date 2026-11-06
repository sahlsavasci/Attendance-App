import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceModel {
  final String id;
  final String name;
  final String description;
  final String address;
  final String datetime;
  final String type;
  final String? reason;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;

  const AttendanceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.datetime,
    required this.type,
    this.reason,
    this.latitude,
    this.longitude,
    required this.createdAt,
  });

  factory AttendanceModel.fromFirestore(DocumentSnapshot doc) {
    final rawData = doc.data();
    final Map<String, dynamic> data =
        rawData is Map<String, dynamic> ? rawData : <String, dynamic>{};
    return AttendanceModel.fromMap(data, doc.id);
  }

  factory AttendanceModel.fromMap(Map<String, dynamic> data, String id) {
    return AttendanceModel(
      id: id,
      name: (data['name']?.toString() ?? '').trim().isNotEmpty
          ? data['name'].toString().trim()
          : 'Siswa',
      description: data['description']?.toString() ?? '-',
      address: data['address']?.toString() ?? '-',
      datetime: data['datetime']?.toString() ?? '-',
      type: data['type']?.toString() ?? 'attendance',
      reason: data['reason']?.toString(),
      latitude: _parseDouble(data['latitude']),
      longitude: _parseDouble(data['longitude']),
      createdAt: _parseDateTime(data['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'description': description,
      'address': address,
      'datetime': datetime,
      'type': type,
      if (reason != null) 'reason': reason,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }
}

