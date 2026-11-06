import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/attendance_model.dart';

class AttendanceService {
  final CollectionReference<Map<String, dynamic>> _collection =
      FirebaseFirestore.instance.collection('attendance');

  Future<void> recordAttendance(AttendanceModel attendance) async {
    final payload = attendance.toMap();
    payload['type'] = 'attendance';
    payload['created_at'] = FieldValue.serverTimestamp();
    await _collection.add(payload);
  }

  Future<void> submitPermission(AttendanceModel permission) async {
    final payload = permission.toMap();
    payload['type'] = 'permission';
    payload['created_at'] = FieldValue.serverTimestamp();
    await _collection.add(payload);
  }

  Stream<List<AttendanceModel>> streamAttendanceHistory({
    String? statusFilter,
    String? searchQuery,
  }) {
    final normalizedQuery = searchQuery?.trim().toLowerCase() ?? '';
    final normalizedFilter = statusFilter?.trim() ?? 'Semua';

    return _collection.snapshots().map((snapshot) {
      final items = snapshot.docs
          .map((doc) => AttendanceModel.fromFirestore(doc))
          .where((item) =>
              _matchesSearch(item, normalizedQuery) &&
              _matchesFilter(item, normalizedFilter))
          .toList();

      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    });
  }

  Future<void> updateAttendance(
    String docId,
    Map<String, dynamic> updatedData,
  ) async {
    await _collection.doc(docId).update(updatedData);
  }

  Future<void> deleteAttendance(String docId) async {
    await _collection.doc(docId).delete();
  }

  bool _matchesSearch(AttendanceModel item, String query) {
    if (query.isEmpty) return true;
    return item.name.toLowerCase().contains(query);
  }

  bool _matchesFilter(AttendanceModel item, String filter) {
    if (filter.isEmpty || filter == 'Semua') return true;

    final desc = item.description.trim().toLowerCase();
    final isPermission = item.type == 'permission';

    switch (filter) {
      case 'Attend':
        return !isPermission &&
            (desc.contains('attend') ||
                desc.contains('hadir') ||
                desc.contains('tepat'));
      case 'Late':
        return !isPermission &&
            (desc.contains('late') || desc.contains('terlambat'));
      case 'Izin':
      case 'Sakit':
        return desc.startsWith(filter.toLowerCase()) ||
            desc.contains(filter.toLowerCase());
      default:
        return desc.contains(filter.toLowerCase());
    }
  }
}

