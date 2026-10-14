import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AbsentScreen extends StatefulWidget {
  const AbsentScreen({super.key});

  @override
  State<AbsentScreen> createState() => _AbsentScreenState();
}

class _AbsentScreenState extends State<AbsentScreen> {
  // Controller untuk input form
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _untilController = TextEditingController();
  
  // Variabel untuk Dropdown Kategori
  String dropDownValue = "Sakit";
  var categories = ["Sakit", "Izin", "Lainnya"];

  bool isLoading = false;
  
  // Koneksi ke Firestore
  final CollectionReference dataCollection = FirebaseFirestore.instance.collection('attendance');

  // ==========================================
  // 1. Pemilih Tanggal Interaktif
  // ==========================================
  Future<void> _pickDate(TextEditingController controller) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        controller.text = DateFormat('dd/MM/yyyy').format(pickedDate);
      });
    }
  }

  // ==========================================
  // 2. Fungsi Pengiriman Izin ke Firestore
  // ==========================================
  Future<void> submitPermission(String nama, String keterangan, String from, String until) async {
    // Validasi form kosong
    if (nama.isEmpty || from.isEmpty || until.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Harap lengkapi semua data form!")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await dataCollection.add({
        'name': nama.trim(),
        'address': '-', // Tidak butuh lokasi GPS untuk izin
        'description': keterangan, // Kategori (Sakit/Izin)
        'datetime': '$from - $until', // Rentang Tanggal
        'type': 'permission', // Penanda bahwa ini bukan absen hadir
        'created_at': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pengajuan izin berhasil dikirim!")),
      );
      
      // Kembali ke layar sebelumnya (HomeScreen)
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal mengirim izin: $e")),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _fromController.dispose();
    _untilController.dispose();
    super.dispose();
  }

  // ==========================================
  // Antarmuka (UI) Form Izin
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Formulir Izin & Sakit"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Silakan lengkapi formulir di bawah ini untuk mengajukan perizinan.",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            
            // Input Nama
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Lengkap',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),

            // Dropdown Kategori (Sakit / Izin)
            DropdownButtonFormField<String>(
              value: dropDownValue,
              decoration: const InputDecoration(
                labelText: 'Kategori',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: categories.map((String category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  dropDownValue = newValue!;
                });
              },
            ),
            const SizedBox(height: 16),

            // Rentang Waktu (Dari)
            TextField(
              controller: _fromController,
              readOnly: true,
              onTap: () => _pickDate(_fromController),
              decoration: const InputDecoration(
                labelText: 'Mulai Tanggal',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
              ),
            ),
            const SizedBox(height: 16),

            // Rentang Waktu (Sampai)
            TextField(
              controller: _untilController,
              readOnly: true,
              onTap: () => _pickDate(_untilController),
              decoration: const InputDecoration(
                labelText: 'Sampai Tanggal',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.event),
              ),
            ),
            const SizedBox(height: 32),

            // Tombol Kirim
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () {
                      submitPermission(
                        _nameController.text,
                        dropDownValue,
                        _fromController.text,
                        _untilController.text,
                      );
                    },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
              ),
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("KIRIM PENGAJUAN", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}