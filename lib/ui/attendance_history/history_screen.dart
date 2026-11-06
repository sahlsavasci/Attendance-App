import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  static const _navy = Color(0xFF1E2B58);
  static const _filters = ['Semua', 'Attend', 'Late', 'Izin', 'Sakit'];

  final CollectionReference dataCollection =
      FirebaseFirestore.instance.collection('attendance');

  // Stream dibuat sekali. Jika dibuat di build(), setiap ketikan di kolom
  // pencarian akan membuka ulang koneksi Firestore dan daftar berkedip.
  late final Stream<QuerySnapshot> _attendanceStream;

  final TextEditingController searchController = TextEditingController();
  String selectedFilter = 'Semua';

  String get _searchQuery => searchController.text.trim().toLowerCase();

  @override
  void initState() {
    super.initState();
    _attendanceStream = dataCollection.snapshots();
    // Rebuild saat teks berubah, termasuk saat dikosongkan lewat tombol clear.
    searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() => setState(() {});

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
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

  // Warna teks status dipilih yang cukup gelap agar terbaca di atas latar pucat.
  Color _getStatusColor(String description) {
    final lower = description.toLowerCase();
    if (lower.contains('attend') || lower.contains('hadir') || lower.contains('tepat')) {
      return const Color(0xFF047857); // Emerald
    } else if (lower.contains('late') || lower.contains('terlambat')) {
      return const Color(0xFFB45309); // Amber
    } else if (lower.contains('leave') || lower.contains('luar')) {
      return const Color(0xFFB91C1C); // Red
    } else if (lower.contains('sakit') || lower.contains('izin')) {
      return const Color(0xFF1D4ED8); // Royal Blue
    }
    return const Color(0xFF475569);
  }

  bool _matchesSearch(Map<String, dynamic> data) {
    if (_searchQuery.isEmpty) return true;
    final name = (data['name']?.toString() ?? '').toLowerCase();
    return name.contains(_searchQuery);
  }

  bool _matchesFilter(Map<String, dynamic> data) {
    if (selectedFilter == 'Semua') return true;

    final desc = (data['description']?.toString() ?? '').trim().toLowerCase();
    final isPermission = data['type'] == 'permission';

    switch (selectedFilter) {
      case 'Attend':
        return !isPermission &&
            (desc.contains('attend') || desc.contains('hadir') || desc.contains('tepat'));
      case 'Late':
        return !isPermission && (desc.contains('late') || desc.contains('terlambat'));
      case 'Izin':
      case 'Sakit':
        // Keterangan izin berformat "Kategori: alasan". Dicocokkan di awal teks
        // agar "Sakit: izin ke dokter" tidak ikut masuk filter Izin.
        return desc.startsWith(selectedFilter.toLowerCase());
      default:
        return true;
    }
  }

  void _showSnackBar(ScaffoldMessengerState messenger, String message) {
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(message),
      ),
    );
  }

  void _showEditDialog(String docId, Map<String, dynamic> currentData) {
    final nameController = TextEditingController(text: currentData['name']?.toString() ?? '');
    final addressController = TextEditingController(text: currentData['address']?.toString() ?? '');
    final descriptionController = TextEditingController(text: currentData['description']?.toString() ?? '');
    final datetimeController = TextEditingController(text: currentData['datetime']?.toString() ?? '');
    final messenger = ScaffoldMessenger.of(context);
    var isSaving = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Future<void> save() async {
              if (nameController.text.trim().isEmpty) {
                _showSnackBar(messenger, 'Nama lengkap tidak boleh kosong.');
                return;
              }
              setDialogState(() => isSaving = true);
              try {
                await dataCollection.doc(docId).update({
                  'name': nameController.text.trim(),
                  'address': addressController.text.trim(),
                  'description': descriptionController.text.trim(),
                  'datetime': datetimeController.text.trim(),
                });
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                _showSnackBar(messenger, 'Data berhasil diperbarui!');
              } catch (e) {
                if (dialogContext.mounted) setDialogState(() => isSaving = false);
                _showSnackBar(messenger, 'Gagal memperbarui data: $e');
              }
            }

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
                  onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Batal', style: TextStyle(color: Color(0xFF475569))),
                ),
                ElevatedButton(
                  onPressed: isSaving ? null : save,
                  style: ElevatedButton.styleFrom(backgroundColor: _navy),
                  child: Text(isSaving ? 'Menyimpan…' : 'Simpan Perubahan'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      nameController.dispose();
      addressController.dispose();
      descriptionController.dispose();
      datetimeController.dispose();
    });
  }

  void _showDeleteDialog(String docId) {
    final messenger = ScaffoldMessenger.of(context);
    var isDeleting = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Future<void> delete() async {
              setDialogState(() => isDeleting = true);
              try {
                await dataCollection.doc(docId).delete();
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                _showSnackBar(messenger, 'Data berhasil dihapus dari sistem!');
              } catch (e) {
                if (dialogContext.mounted) setDialogState(() => isDeleting = false);
                _showSnackBar(messenger, 'Gagal menghapus data: $e');
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Hapus Catatan?', style: TextStyle(fontWeight: FontWeight.bold)),
              content: const Text(
                'Apakah Anda yakin ingin menghapus data presensi ini? Tindakan ini permanen dan tidak dapat dibatalkan.',
                style: TextStyle(color: Color(0xFF475569), height: 1.4),
              ),
              actions: [
                TextButton(
                  onPressed: isDeleting ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Batal', style: TextStyle(color: Color(0xFF475569))),
                ),
                ElevatedButton(
                  onPressed: isDeleting ? null : delete,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB91C1C)),
                  child: Text(isDeleting ? 'Menghapus…' : 'Ya, Hapus Data'),
                ),
              ],
            );
          },
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
              _buildSearchAndFilter(),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              Expanded(child: _buildHistoryList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        children: [
          TextField(
            controller: searchController,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Cari nama siswa...',
              prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF64748B)),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      tooltip: 'Hapus pencarian',
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: searchController.clear,
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = selectedFilter == filter;
                return ChoiceChip(
                  label: Text(filter),
                  selected: isSelected,
                  onSelected: (_) => setState(() => selectedFilter = filter),
                  selectedColor: _navy,
                  backgroundColor: const Color(0xFFF1F5F9),
                  showCheckmark: false,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : const Color(0xFF475569),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? _navy : const Color(0xFFCBD5E1),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _attendanceStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildMessage(
            icon: Icons.cloud_off,
            iconColor: const Color(0xFFB91C1C),
            title: 'Gagal memuat data',
            body: 'Periksa koneksi internet, lalu buka ulang halaman ini.\n${snapshot.error}',
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: _navy),
          );
        }

        final docs = List<QueryDocumentSnapshot>.from(snapshot.data!.docs);
        if (docs.isEmpty) {
          return _buildMessage(
            icon: Icons.inbox_outlined,
            title: 'Belum Ada Catatan Presensi',
            body: 'Presensi yang terekam akan muncul di halaman ini secara real-time.',
          );
        }

        // Urutkan terbaru di atas. Data yang baru dikirim belum punya created_at
        // dari server, jadi ditaruh paling atas.
        docs.sort((a, b) {
          final timeA = (a.data() as Map<String, dynamic>?)?['created_at'] as Timestamp?;
          final timeB = (b.data() as Map<String, dynamic>?)?['created_at'] as Timestamp?;
          if (timeA == null && timeB == null) return 0;
          if (timeA == null) return -1;
          if (timeB == null) return 1;
          return timeB.compareTo(timeA);
        });

        final filteredDocs = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>? ?? {};
          return _matchesSearch(data) && _matchesFilter(data);
        }).toList();

        if (filteredDocs.isEmpty) {
          return _buildMessage(
            icon: Icons.search_off,
            title: 'Tidak ada yang cocok',
            body: _emptyFilterMessage(),
            action: TextButton(
              onPressed: () {
                searchController.clear();
                setState(() => selectedFilter = 'Semua');
              },
              child: const Text('Tampilkan semua catatan'),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            final doc = filteredDocs[index];
            final data = doc.data() as Map<String, dynamic>? ?? {};
            final name = data['name']?.toString() ?? 'Siswa';
            final address = data['address']?.toString() ?? '-';
            final description = data['description']?.toString() ?? '-';
            final datetime = data['datetime']?.toString() ?? '-';

            return _buildAttendanceCard(doc.id, name, address, description, datetime, data);
          },
        );
      },
    );
  }

  String _emptyFilterMessage() {
    final query = searchController.text.trim();
    if (query.isNotEmpty && selectedFilter != 'Semua') {
      return 'Tidak ada catatan "$selectedFilter" atas nama "$query".';
    }
    if (query.isNotEmpty) {
      return 'Tidak ada catatan atas nama "$query".';
    }
    return 'Belum ada catatan dengan status "$selectedFilter".';
  }

  Widget _buildMessage({
    required IconData icon,
    required String title,
    required String body,
    Color iconColor = const Color(0xFF94A3B8),
    Widget? action,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: iconColor),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
            ),
            const SizedBox(height: 6),
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF475569)),
            ),
            if (action != null) ...[
              const SizedBox(height: 12),
              action,
            ],
          ],
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
                    name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?',
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
                          color: statusColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: statusColor.withValues(alpha: 0.4)),
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
                      tooltip: 'Edit Presensi',
                      icon: const Icon(Icons.edit_outlined, color: Color(0xFF1D4ED8), size: 20),
                      onPressed: () => _showEditDialog(docId, rawData),
                    ),
                    IconButton(
                      tooltip: 'Hapus Presensi',
                      icon: const Icon(Icons.delete_outline, color: Color(0xFFB91C1C), size: 20),
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
