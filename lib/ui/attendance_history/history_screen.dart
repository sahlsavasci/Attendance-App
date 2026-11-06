import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../models/attendance_model.dart';
import '../../models/user_model.dart';
import '../../services/attendance_service.dart';
import '../../services/auth_service.dart';
import '../../utils/csv_exporter/csv_exporter.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  final UserModel? currentUser;

  const AttendanceHistoryScreen({super.key, this.currentUser});

  @override
  State<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  static const _cobalt500 = Color(0xFF2952F2);
  static const _filters = ['Semua', 'Attend', 'Late', 'Izin', 'Sakit'];
  static const _csvFileName = 'rekap_presensi_XI_RPL.csv';

  final AttendanceService _attendanceService = AttendanceService();
  final AuthService _authService = AuthService();

  final TextEditingController searchController = TextEditingController();
  String selectedFilter = 'Semua';

  UserModel? _activeUser;
  List<AttendanceModel> _currentItems = [];
  bool _isExporting = false;

  bool get _isTeacher => _activeUser?.isTeacher ?? false;

  @override
  void initState() {
    super.initState();
    _activeUser = widget.currentUser;
    if (_activeUser == null) {
      _loadUser();
    }
    searchController.addListener(_onSearchChanged);
  }

  Future<void> _loadUser() async {
    final profile = await _authService.getCurrentUserProfile();
    if (mounted && profile != null) {
      setState(() => _activeUser = profile);
    }
  }

  void _onSearchChanged() => setState(() {});

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.dispose();
  }

  String _escapeCsvField(String value) {
    final cleaned = value.replaceAll('\r\n', ' ').replaceAll('\n', ' ').trim();
    if (cleaned.contains(',') || cleaned.contains('"')) {
      final escapedQuotes = cleaned.replaceAll('"', '""');
      return '"$escapedQuotes"';
    }
    return cleaned;
  }

  String _buildCsvString(List<AttendanceModel> data) {
    final buffer = StringBuffer();
    buffer.writeln('Nama,NIS,Kelas,Status,Approval,Tanggal/Waktu,Alamat,Alasan');

    for (final item in data) {
      final row = [
        _escapeCsvField(item.name),
        _escapeCsvField(item.nis),
        _escapeCsvField(item.studentClass),
        _escapeCsvField(item.description),
        _escapeCsvField(item.approvalStatus),
        _escapeCsvField(item.datetime),
        _escapeCsvField(item.address),
        _escapeCsvField(item.reason ?? '-'),
      ].join(',');
      buffer.writeln(row);
    }

    return buffer.toString();
  }

  Future<void> exportAttendanceToCsv(List<AttendanceModel> data) async {
    final messenger = ScaffoldMessenger.of(context);
    if (data.isEmpty) {
      _showSnackBar(
        messenger,
        'Belum ada data presensi untuk diekspor ke CSV.',
      );
      return;
    }

    setState(() => _isExporting = true);
    try {
      final csvContent = _buildCsvString(data);
      final savedLocation = await downloadCsvFile(csvContent, _csvFileName);
      if (!mounted) return;

      if (kIsWeb) {
        _showSnackBar(
          messenger,
          'Berhasil mengunduh $_csvFileName (${data.length} baris).',
        );
      } else {
        _showSnackBar(
          messenger,
          'CSV disimpan di: $savedLocation & disalin ke Clipboard (${data.length} baris).',
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(messenger, 'Gagal mengekspor CSV: $e');
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Color _getAvatarColor(String name) {
    if (name.trim().isEmpty) return const Color(0xFF64748B);
    final int hash = name.codeUnits.fold(0, (prev, elem) => prev + elem);
    const colors = [
      Color(0xFF2952F2),
      Color(0xFF0D9488),
      Color(0xFF1A36A6),
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
      return const Color(0xFF12B76A);
    } else if (lower.contains('late') || lower.contains('terlambat')) {
      return const Color(0xFFF79009);
    } else if (lower.contains('leave') || lower.contains('luar')) {
      return const Color(0xFFD92D20);
    } else if (lower.contains('sakit') || lower.contains('izin')) {
      return const Color(0xFF2952F2);
    }
    return const Color(0xFF5B6474);
  }

  void _showSnackBar(ScaffoldMessengerState messenger, String message) {
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(message),
      ),
    );
  }

  void _showEditDialog(AttendanceModel item) {
    final nameController = TextEditingController(text: item.name);
    final addressController = TextEditingController(text: item.address);
    final descriptionController = TextEditingController(text: item.description);
    final datetimeController = TextEditingController(text: item.datetime);
    String approvalStatus = item.approvalStatus;
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
                await _attendanceService.updateAttendance(item.id, {
                  'name': nameController.text.trim(),
                  'address': addressController.text.trim(),
                  'description': descriptionController.text.trim(),
                  'datetime': datetimeController.text.trim(),
                  'approvalStatus': approvalStatus,
                });
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                _showSnackBar(messenger, 'Data berhasil diperbarui oleh Wali Kelas!');
              } catch (e) {
                if (dialogContext.mounted) setDialogState(() => isSaving = false);
                _showSnackBar(messenger, 'Gagal memperbarui data: $e');
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Kelola Catatan (Wali Kelas)', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
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
                    DropdownButtonFormField<String>(
                      initialValue: ['pending', 'approved', 'rejected'].contains(approvalStatus)
                          ? approvalStatus
                          : 'approved',
                      decoration: const InputDecoration(labelText: 'Status Persetujuan'),
                      items: const [
                        DropdownMenuItem(value: 'approved', child: Text('Approved (Disetujui)')),
                        DropdownMenuItem(value: 'pending', child: Text('Pending (Menunggu)')),
                        DropdownMenuItem(value: 'rejected', child: Text('Rejected (Ditolak)')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => approvalStatus = val);
                        }
                      },
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
                  style: ElevatedButton.styleFrom(backgroundColor: _cobalt500),
                  child: Text(isSaving ? 'Menyimpan…' : 'Simpan'),
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
                await _attendanceService.deleteAttendance(docId);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                _showSnackBar(messenger, 'Data berhasil dihapus dari sistem!');
              } catch (e) {
                if (dialogContext.mounted) setDialogState(() => isDeleting = false);
                _showSnackBar(messenger, 'Gagal menghapus data: $e');
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Hapus Catatan?', style: TextStyle(fontWeight: FontWeight.bold)),
              content: const Text(
                'Apakah Anda yakin ingin menghapus data presensi ini? Tindakan ini hanya diizinkan untuk Wali Kelas.',
                style: TextStyle(color: Color(0xFF475569), height: 1.4),
              ),
              actions: [
                TextButton(
                  onPressed: isDeleting ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Batal', style: TextStyle(color: Color(0xFF475569))),
                ),
                ElevatedButton(
                  onPressed: isDeleting ? null : delete,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD92D20)),
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
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        title: const Text('Riwayat Presensi Siswa'),
        actions: [
          IconButton(
            tooltip: 'Ekspor ke CSV ($_csvFileName)',
            icon: _isExporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.download),
            onPressed: _isExporting
                ? null
                : () => exportAttendanceToCsv(_currentItems),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            children: [
              _buildSearchAndFilter(),
              const Divider(height: 1, color: Color(0xFFE8EEFF)),
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
              hintText: 'Cari nama atau NIS siswa...',
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
                  selectedColor: _cobalt500,
                  backgroundColor: const Color(0xFFF2F4F7),
                  showCheckmark: false,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : const Color(0xFF475569),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? _cobalt500 : const Color(0xFFE8EEFF),
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
    final query = searchController.text.trim();
    final isFiltering = query.isNotEmpty || selectedFilter != 'Semua';

    return StreamBuilder<List<AttendanceModel>>(
      stream: _attendanceService.streamAttendanceHistory(
        statusFilter: selectedFilter,
        searchQuery: query,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildMessage(
            icon: Icons.cloud_off,
            iconColor: const Color(0xFFD92D20),
            title: 'Gagal memuat data',
            body: 'Periksa koneksi internet, lalu buka ulang halaman ini.\n${snapshot.error}',
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: _cobalt500),
          );
        }

        final items = snapshot.data!;
        _currentItems = items;

        if (items.isEmpty) {
          if (isFiltering) {
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

          return _buildMessage(
            icon: Icons.inbox_outlined,
            title: 'Belum Ada Catatan Presensi',
            body: 'Presensi yang terekam akan muncul di halaman ini secara real-time.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            return _buildAttendanceCard(items[index]);
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

  Widget _buildApprovalChip(String approvalStatus) {
    final status = approvalStatus.toLowerCase();
    Color color = const Color(0xFF12B76A);
    String label = 'Approved';

    if (status == 'pending') {
      color = const Color(0xFFF79009);
      label = 'Pending';
    } else if (status == 'rejected') {
      color = const Color(0xFFD92D20);
      label = 'Rejected';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '• $label',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 10.5,
        ),
      ),
    );
  }

  Widget _buildAttendanceCard(AttendanceModel item) {
    final statusColor = _getStatusColor(item.description);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EEFF), width: 1.2),
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
                  backgroundColor: _getAvatarColor(item.name),
                  child: Text(
                    item.name.trim().isNotEmpty ? item.name.trim()[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0E1A2B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'NIS: ${item.nis} • ${item.studentClass}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF5B6474),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              item.description,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          _buildApprovalChip(item.approvalStatus),
                        ],
                      ),
                    ],
                  ),
                ),
                // Role-Based Access Control: Hanya Wali Kelas (teacher) yang boleh Edit/Delete
                if (_isTeacher)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Kelola / Setujui (Wali Kelas)',
                        icon: const Icon(Icons.edit_outlined, color: Color(0xFF2952F2), size: 20),
                        onPressed: () => _showEditDialog(item),
                      ),
                      IconButton(
                        tooltip: 'Hapus Presensi (Wali Kelas)',
                        icon: const Icon(Icons.delete_outline, color: Color(0xFFD92D20), size: 20),
                        onPressed: () => _showDeleteDialog(item.id),
                      ),
                    ],
                  ),
              ],
            ),
            const Divider(height: 20, color: Color(0xFFF1F5F9)),
            Row(
              children: [
                const Icon(Icons.schedule, size: 15, color: Color(0xFF5B6474)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item.datetime,
                    style: const TextStyle(color: Color(0xFF334155), fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            if (item.address != '-' && item.address.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_outlined, size: 15, color: Color(0xFF5B6474)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.address,
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
