import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  // Koneksi ke Koleksi Firestore
  final CollectionReference dataCollection = FirebaseFirestore.instance.collection('attendance');

  // ==========================================
  // 1. Algoritma Hash Warna Avatar Deterministik
  // ==========================================
  Color _getAvatarColor(String name) {
    if (name.trim().isEmpty) return Colors.blueGrey;
    final int hash = name.codeUnits.fold(0, (prev, elem) => prev + elem);
    return Colors.primaries[hash % Colors.primaries.length];
  }

  // ==========================================
  // 2. Operasi Update & Delete Firestore (Dialogs)
  // ==========================================
  void _showEditDialog(String docId, Map<String, dynamic> currentData) {
    final nameController = TextEditingController(text: currentData['name']?.toString() ?? '');
    final addressController = TextEditingController(text: currentData['address']?.toString() ?? '');
    final descriptionController = TextEditingController(text: currentData['description']?.toString() ?? '');
    final datetimeController = TextEditingController(text: currentData['datetime']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Presensi', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Status / Keterangan'),
                ),
                TextField(
                  controller: datetimeController,
                  decoration: const InputDecoration(labelText: 'Waktu / Tanggal'),
                ),
                TextField(
                  controller: addressController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Alamat Lokasi'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Memperbarui dokumen
                await dataCollection.doc(docId).update({
                  'name': nameController.text.trim(),
                  'address': addressController.text.trim(),
                  'description': descriptionController.text.trim(),
                  'datetime': datetimeController.text.trim(),
                });
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Data berhasil diperbarui!')),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
              child: const Text('Simpan', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteDialog(String docId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus Data', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('Apakah Anda yakin ingin menghapus riwayat presensi ini? Tindakan ini tidak dapat dibatalkan.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Menghapus dokumen
                await dataCollection.doc(docId).delete();
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Data berhasil dihapus!')),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Hapus', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Presensi'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: dataCollection.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "Belum ada riwayat presensi",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final docs = List<QueryDocumentSnapshot>.from(snapshot.data!.docs);
          docs.sort((a, b) {
            final dataA = a.data() as Map<String, dynamic>? ?? {};
            final dataB = b.data() as Map<String, dynamic>? ?? {};
            final timeA = dataA['created_at'] as Timestamp?;
            final timeB = dataB['created_at'] as Timestamp?;
            if (timeA != null && timeB != null) {
              return timeB.compareTo(timeA);
            }
            return 0;
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>? ?? {};
              final docId = docs[index].id;
              final name = data['name']?.toString() ?? 'Unknown';
              final address = data['address']?.toString() ?? '-';
              final description = data['description']?.toString() ?? '-';
              final datetime = data['datetime']?.toString() ?? '-';

              return _buildAttendanceCard(docId, name, address, description, datetime, data);
            },
          );
        },
      ),
    );
  }

  // ==========================================
  // Desain Kartu dengan Avatar & Aksi CRUD
  // ==========================================
  Widget _buildAttendanceCard(String docId, String name, String address, String description, String datetime, Map<String, dynamic> rawData) {
    Color statusColor = Colors.grey;
    if (description == 'Attend') {
      statusColor = Colors.green;
    } else if (description == 'Late') {
      statusColor = Colors.orange;
    } else if (description == 'Leave') {
      statusColor = Colors.red;
    } else if (description == 'Sakit' || description == 'Izin') {
      statusColor = Colors.blueAccent;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar Berwarna Deterministik
                CircleAvatar(
                  backgroundColor: _getAvatarColor(name),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Info Nama dan Lencana Status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: statusColor),
                        ),
                        child: Text(
                          description,
                          style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),

                // Tombol Aksi (Edit & Delete)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent, size: 20),
                      onPressed: () => _showEditDialog(docId, rawData),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      onPressed: () => _showDeleteDialog(docId),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(datetime, style: const TextStyle(color: Colors.black87)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(address, style: const TextStyle(color: Colors.black87)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}