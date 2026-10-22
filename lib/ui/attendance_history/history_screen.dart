import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  final CollectionReference dataCollection =
      FirebaseFirestore.instance.collection('attendance');

  String _searchQuery = "";
  String _selectedFilter = "Semua";
  final List<String> _filters = ["Semua", "Attend", "Late", "Izin", "Sakit"];

  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getAvatarColor(String name) {
    if (name.trim().isEmpty) return const Color(0xFF64748B);
    final int hash = name.codeUnits.fold(0, (prev, elem) => prev + elem);
    const colors = [
      Color(0xFF1E2B58),
      Color(0xFF0D9488),
      Color(0xFF2563EB),
      Color(0xFF7C3AED),
      Color(0xFFD97706),
      Color(0xFFDC2626),
      Color(0xFF059669),
    ];
    return colors[hash % colors.length];
  }

  Color _getStatusColor(String description) {
    final lower = description.toLowerCase();
    if (lower.contains('attend') || lower.contains('hadir') || lower.contains('tepat')) {
      return const Color(0xFF10B981); // Emerald
    } else if (lower.contains('late') || lower.contains('terlambat')) {
      return const Color(0xFFF59E0B); // Amber
    } else if (lower.contains('leave') || lower.contains('luar')) {
      return const Color(0xFFEF4444); // Red
    } else if (lower.contains('sakit') || lower.contains('izin')) {
      return const Color(0xFF2563EB); // Royal Blue
    }
    return const Color(0xFF64748B);
  }

  void _showEditDialog(String docId, Map<String, dynamic> currentData) {
    final nameController = TextEditingController(text: currentData['name']?.toString() ?? '');
    final addressController = TextEditingController(text: currentData['address']?.toString() ?? '');
    final descriptionController = TextEditingController(text: currentData['description']?.toString() ?? '');
    final datetimeController = TextEditingController(text: currentData['datetime']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Edit Catatan Presensi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Status / Keterangan'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: datetimeController,
                  decoration: const InputDecoration(labelText: 'Waktu / Tanggal'),
                ),
                const SizedBox(height: 12),
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
              child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              onPressed: () async {
                await dataCollection.doc(docId).update({
                  'name': nameController.text.trim(),
                  'address': addressController.text.trim(),
                  'description': descriptionController.text.trim(),
                  'datetime': datetimeController.text.trim(),
                });
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    behavior: SnackBarBehavior.floating,
                    content: Text('Data berhasil diperbarui!'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E2B58),
              ),
              child: const Text('Simpan Perubahan'),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Hapus Catatan?', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text(
            'Apakah Anda yakin ingin menghapus data presensi ini? Tindakan ini permanen dan tidak dapat dibatalkan.',
            style: TextStyle(color: Color(0xFF475569), height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              onPressed: () async {
                await dataCollection.doc(docId).delete();
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    behavior: SnackBarBehavior.floating,
                    content: Text('Data berhasil dihapus dari sistem!'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
              child: const Text('Ya, Hapus Data'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Riwayat Presensi Siswa'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            children: [
              // Search & Filter Header
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Column(
                  children: [
                    // Search bar
                    TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                      decoration: InputDecoration(
                        hintText: "Cari nama siswa...",
                        prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF64748B)),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = "");
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _filters.map((filter) {
                          final isSelected = _selectedFilter == filter;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6.0),
                            child: FilterChip(
                              label: Text(filter),
                              selected: isSelected,
                              onSelected: (_) => setState(() => _selectedFilter = filter),
                              selectedColor: const Color(0xFF1E2B58),
                              labelStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : const Color(0xFF475569),
                              ),
                              backgroundColor: const Color(0xFFF1F5F9),
                              showCheckmark: false,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: isSelected ? const Color(0xFF1E2B58) : const Color(0xFFE2E8F0),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, color: Color(0xFFE2E8F0)),

              // Stream List
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: dataCollection.snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: Color(0xFF1E2B58)),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.cloud_off, size: 48, color: Color(0xFFEF4444)),
                              const SizedBox(height: 12),
                              Text(
                                "Gagal memuat data: ${snapshot.error}",
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Color(0xFF475569)),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox_outlined, size: 56, color: Color(0xFF94A3B8)),
                              SizedBox(height: 12),
                              Text(
                                "Belum Ada Catatan Presensi",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                              ),
                              SizedBox(height: 6),
                              Text(
                                "Presensi yang terekam akan muncul di halaman ini secara real-time.",
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    // Sort data by created_at safely
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

                    // Filter based on search query and category
                    final filteredDocs = docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>? ?? {};
                      final name = (data['name']?.toString() ?? '').toLowerCase();
                      final desc = (data['description']?.toString() ?? '').toLowerCase();

                      final matchesSearch = _searchQuery.isEmpty || name.contains(_searchQuery);

                      if (!matchesSearch) return false;

                      if (_selectedFilter == "Semua") return true;
                      return desc.contains(_selectedFilter.toLowerCase());
                    }).toList();

                    if (filteredDocs.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Text(
                            "Tidak ada data presensi yang sesuai dengan pencarian.",
                            style: TextStyle(color: Color(0xFF64748B)),
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredDocs.length,
                      itemBuilder: (context, index) {
                        final doc = filteredDocs[index];
                        final data = doc.data() as Map<String, dynamic>? ?? {};
                        final docId = doc.id;
                        final name = data['name']?.toString() ?? 'Siswa';
                        final address = data['address']?.toString() ?? '-';
                        final description = data['description']?.toString() ?? '-';
                        final datetime = data['datetime']?.toString() ?? '-';

                        return _buildAttendanceCard(docId, name, address, description, datetime, data);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceCard(
    String docId,
    String name,
    String address,
    String description,
    String datetime,
    Map<String, dynamic> rawData,
  ) {
    final statusColor = _getStatusColor(description);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: _getAvatarColor(name),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          description,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: "Edit Presensi",
                      icon: const Icon(Icons.edit_outlined, color: Color(0xFF2563EB), size: 19),
                      onPressed: () => _showEditDialog(docId, rawData),
                    ),
                    IconButton(
                      tooltip: "Hapus Presensi",
                      icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 19),
                      onPressed: () => _showDeleteDialog(docId),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 20, color: Color(0xFFF1F5F9)),
            Row(
              children: [
                const Icon(Icons.schedule, size: 15, color: Color(0xFF64748B)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    datetime,
                    style: const TextStyle(color: Color(0xFF334155), fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            if (address != '-' && address.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_outlined, size: 15, color: Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      address,
                      style: const TextStyle(color: Color(0xFF475569), fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}