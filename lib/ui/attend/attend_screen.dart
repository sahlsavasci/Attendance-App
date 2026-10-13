import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class AttendScreen extends StatefulWidget {
  final XFile? image;

  const AttendScreen({super.key, this.image});

  @override
  State<AttendScreen> createState() => _AttendScreenState();
}

class _AttendScreenState extends State<AttendScreen> {
  // Variabel Penampung Data Lokasi
  bool isLoading = false;
  double dLat = 0.0;
  double dLong = 0.0;
  String strAlamat = "Mencari lokasi...";

  @override
  void initState() {
    super.initState();
    // Otomatis mencari lokasi GPS saat halaman pertama kali dibuka
    getGeoLocationPosition();
  }

  // ==========================================
  // 1. Manajemen Izin Lokasi Runtime
  // ==========================================
  Future<bool> handleLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnackBar(
          "Layanan GPS tidak aktif. Silakan aktifkan GPS perangkat Anda.",
          Icons.location_off);
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showSnackBar(
            "Izin akses lokasi ditolak.", Icons.warning_amber_rounded);
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showSnackBar(
          "Izin lokasi ditolak permanen. Buka pengaturan aplikasi untuk mengizinkan.",
          Icons.error_outline);
      return false;
    }

    return true;
  }

  // ==========================================
  // 2. Mengambil Posisi Koordinat Presisi
  // ==========================================
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

      // Memanggil fungsi konversi koordinat ke nama alamat
      await getAddressFromLongLat(position);
    } catch (e) {
      debugPrint("Error GPS: $e");
      if (mounted) {
        setState(() {
          strAlamat = "Koordinat: Lat $dLat, Long $dLong";
          isLoading = false;
        });
      }
    }
  }

  // ==========================================
  // 3. Reverse Geocoding & Konversi Koordinat ke Alamat Nyata
  // ==========================================
  Future<void> getAddressFromLongLat(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty && mounted) {
        final place = placemarks[0];
        setState(() {
          strAlamat =
              "${place.street ?? ''}, ${place.subLocality ?? ''}, ${place.locality ?? ''}, ${place.country ?? ''}"
                  .replaceAll(RegExp(r'^[\s,]+|[\s,]+$'), '')
                  .replaceAll(RegExp(r',\s*,+'), ',');
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        strAlamat =
            "Lat: ${position.latitude.toStringAsFixed(5)}, Long: ${position.longitude.toStringAsFixed(5)}";
        isLoading = false;
      });
    }
  }

  // Fungsi pembantu untuk menampilkan pesan error/notifikasi
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Konfirmasi Presensi'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Menampilkan indikator loading jika GPS sedang mencari titik
            if (isLoading) const CircularProgressIndicator(),
            const SizedBox(height: 16),

            // Menampilkan hasil teks alamat/koordinat
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                strAlamat,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Tampilan sementara untuk menunjukkan data foto
            if (widget.image != null)
              Text('Wajah terdeteksi! Siap untuk dikirim.', style: TextStyle(color: Colors.green[700])),
          ],
        ),
      ),
    );
  }
}