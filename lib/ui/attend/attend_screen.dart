import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:attendance_app/ui/home_screen.dart'; // Import HomeScreen

class AttendScreen extends StatefulWidget {
  final XFile? image;

  const AttendScreen({super.key, this.image});

  @override
  State<AttendScreen> createState() => _AttendScreenState();
}

class _AttendScreenState extends State<AttendScreen> {
  // Variabel Lokasi
  bool isLoading = false;
  double dLat = 0.0;
  double dLong = 0.0;
  String strAlamat = "Mencari lokasi...";

  // Variabel Status & Waktu
  String strStatus = "Mencari status...";
  String strDateTime = "";

  // Controller untuk input nama
  final TextEditingController nameController = TextEditingController();

  // Koneksi ke Koleksi Firestore
  final CollectionReference dataCollection = FirebaseFirestore.instance.collection('attendance');

  @override
  void initState() {
    super.initState();
    getGeoLocationPosition();
    setStatusAbsen();
    // Mengambil tanggal dan waktu saat ini dengan format Hari, Tanggal Bulan Tahun Jam:Menit
    strDateTime = DateFormat('EEEE, d MMMM yyyy HH:mm', 'id_ID').format(DateTime.now());
  }

  // ==========================================
  // 1. Aturan Waktu Kehadiran Otomatis
  // ==========================================
  void setStatusAbsen() {
    final now = DateTime.now();
    final dateHours = now.hour;
    final dateMinutes = now.minute;

    if (dateHours < 8 || (dateHours == 8 && dateMinutes <= 30)) {
      strStatus = "Attend";   // Tepat waktu (sebelum / pukul 08:30)
    } else if ((dateHours > 8 && dateHours < 18) ||
        (dateHours == 8 && dateMinutes >= 31)) {
      strStatus = "Late";     // Terlambat (08:31 s/d 18:00)
    } else {
      strStatus = "Leave";    // Di luar jam operasional
    }
  }

  // ==========================================
  // 2. Pengiriman Payload ke Cloud Firestore
  // ==========================================
  Future<void> submitAbsen(String alamat, String nama, String status) async {
    // Validasi form kosong
    if (nama.isEmpty) {
      _showSnackBar("Nama tidak boleh kosong!", Icons.warning_amber_rounded);
      return;
    }

    _showLoaderDialog();

    try {
      await dataCollection.add({
        'name': nama.trim(),
        'address': alamat.isEmpty ? 'Lokasi tidak terekam' : alamat,
        'description': status,
        'datetime': strDateTime,
        'latitude': dLat,
        'longitude': dLong,
        'type': 'attendance',
        'created_at': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // Tutup Loader Dialog
      
      _showSnackBar("Presensi berhasil dikirim!", Icons.check_circle_outline);

      // Kembali ke HomeScreen setelah sukses
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // Tutup Loader Dialog
      _showSnackBar("Gagal menyimpan presensi: $e", Icons.error_outline);
    }
  }

  // ==========================================
  // Fungsi Pendukung: Loader, SnackBar, dan Geolocation (yang sudah Anda buat)
  // ==========================================
  void _showLoaderDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  void _showSnackBar(String message, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  Future<bool> handleLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnackBar("Layanan GPS tidak aktif. Silakan aktifkan GPS.", Icons.location_off);
      return false;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showSnackBar("Izin akses lokasi ditolak.", Icons.warning_amber_rounded);
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      _showSnackBar("Izin lokasi ditolak permanen.", Icons.error_outline);
      return false;
    }
    return true;
  }

  Future<void> getGeoLocationPosition() async {
    final hasPermission = await handleLocationPermission();
    if (!hasPermission) return;

    setState(() => isLoading = true);
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      dLat = position.latitude;
      dLong = position.longitude;
      await getAddressFromLongLat(position);
    } catch (e) {
      if (mounted) {
        setState(() {
          strAlamat = "Koordinat: Lat $dLat, Long $dLong";
          isLoading = false;
        });
      }
    }
  }

  Future<void> getAddressFromLongLat(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty && mounted) {
        final place = placemarks[0];
        setState(() {
          strAlamat = "${place.street ?? ''}, ${place.subLocality ?? ''}, ${place.locality ?? ''}, ${place.country ?? ''}"
              .replaceAll(RegExp(r'^[\s,]+|[\s,]+$'), '')
              .replaceAll(RegExp(r',\s*,+'), ',');
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        strAlamat = "Lat: ${position.latitude.toStringAsFixed(5)}, Long: ${position.longitude.toStringAsFixed(5)}";
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  // ==========================================
  // Antarmuka Form Konfirmasi
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Konfirmasi Presensi'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Preview Foto
            if (widget.image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(widget.image!.path),
                  height: 200,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.person, size: 80, color: Colors.grey),
              ),
            
            const SizedBox(height: 24),

            // Card Info Waktu & Status
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text("Waktu: $strDateTime", style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      "Status: $strStatus", 
                      style: TextStyle(
                        fontSize: 18, 
                        fontWeight: FontWeight.bold,
                        color: strStatus == "Attend" ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Indikator Lokasi
            isLoading 
                ? const Center(child: CircularProgressIndicator())
                : ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.location_on, color: Colors.red, size: 36),
                    title: const Text("Lokasi Anda saat ini:"),
                    subtitle: Text(strAlamat),
                  ),

            const SizedBox(height: 24),

            // Input Nama Siswa
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Lengkap',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.badge),
              ),
            ),

            const SizedBox(height: 32),

            // Tombol Submit
            ElevatedButton(
              onPressed: isLoading 
                ? null 
                : () => submitAbsen(strAlamat, nameController.text, strStatus),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("KIRIM PRESENSI", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}