import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AbsentScreen extends StatefulWidget {
  const AbsentScreen({super.key});

  @override
  State<AbsentScreen> createState() => _AbsentScreenState();
}

class _AbsentScreenState extends State<AbsentScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  
  DateTime? _startDate;
  DateTime? _endDate;

  String _selectedCategory = "Sakit";
  final List<String> _categories = ["Sakit", "Izin", "Lainnya"];

  bool _isLoading = false;
  
  final CollectionReference _dataCollection =
      FirebaseFirestore.instance.collection('attendance');

  @override
  void initState() {
    super.initState();
    _startDate = DateTime.now();
    _endDate = DateTime.now();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "Pilih tanggal";
    try {
      return DateFormat('dd MMMM yyyy', 'id_ID').format(date);
    } catch (_) {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
      helpText: "PILIH TANGGAL MULAI IZIN",
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(_startDate!)) {
          _endDate = _startDate;
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2023),
      lastDate: DateTime(2030),
      helpText: "PILIH TANGGAL SELESAI IZIN",
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _submitPermission() async {
    final name = _nameController.text.trim();
    final reason = _reasonController.text.trim();

    if (name.isEmpty) {
      _showSnackBar("Harap isi nama lengkap Anda!", Icons.warning_amber_rounded);
      return;
    }

    if (_startDate == null || _endDate == null) {
      _showSnackBar("Harap tentukan tanggal mulai dan selesai izin!", Icons.warning_amber_rounded);
      return;
    }

    setState(() => _isLoading = true);

    final startStr = DateFormat('dd/MM/yyyy').format(_startDate!);
    final endStr = DateFormat('dd/MM/yyyy').format(_endDate!);
    final dateRangeStr = startStr == endStr ? startStr : "$startStr - $endStr";

    final descriptionText = reason.isNotEmpty
        ? "$_selectedCategory: $reason"
        : _selectedCategory;

    try {
      await _dataCollection.add({
        'name': name,
        'address': '-',
        'description': descriptionText,
        'datetime': dateRangeStr,
        'type': 'permission',
        'category': _selectedCategory,
        'reason': reason,
        'start_date': Timestamp.fromDate(_startDate!),
        'end_date': Timestamp.fromDate(_endDate!),
        'created_at': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      _showSnackBar("Pengajuan izin berhasil tersimpan!", Icons.check_circle_outline);
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar("Gagal mengirim pengajuan izin: $e", Icons.error_outline);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Pengajuan Izin & Sakit"),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: Color(0xFF2563EB), size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Pengajuan izin atau sakit akan diverifikasi oleh wali kelas dan tercatat di riwayat kehadiran XI RPL.",
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF1E3A8A),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 1. Input Nama Lengkap
                const Text(
                  "NAMA SISWA",
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B), letterSpacing: 0.6),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: "Nama lengkap sesuai presensi",
                    prefixIcon: Icon(Icons.person_outline, color: Color(0xFF64748B)),
                  ),
                ),

                const SizedBox(height: 20),

                // 2. Kategori Izin (Segmented Buttons)
                const Text(
                  "KATEGORI PERIZINAN",
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B), letterSpacing: 0.6),
                ),
                const SizedBox(height: 8),
                Row(
                  children: _categories.map((category) {
                    final isSelected = _selectedCategory == category;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => setState(() => _selectedCategory = category),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF1E2B58) : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF1E2B58) : const Color(0xFFCBD5E1),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              category,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? Colors.white : const Color(0xFF334155),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),

                // 3. Rentang Waktu
                const Text(
                  "RENTANG WAKTU IZIN",
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B), letterSpacing: 0.6),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _pickStartDate,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.calendar_today, size: 14, color: Color(0xFF2563EB)),
                                  SizedBox(width: 6),
                                  Text("Mulai", style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _formatDate(_startDate),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: _pickEndDate,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.event, size: 14, color: Color(0xFF2563EB)),
                                  SizedBox(width: 6),
                                  Text("Sampai", style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _formatDate(_endDate),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // 4. Keterangan / Alasan
                const Text(
                  "KETERANGAN / ALASAN (OPSIONAL)",
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B), letterSpacing: 0.6),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _reasonController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: "Tuliskan alasan izin atau diagnosis sakit...",
                  ),
                ),

                const SizedBox(height: 32),

                // Tombol Kirim
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitPermission,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E2B58),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          "KIRIM PENGAJUAN IZIN",
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.3),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}