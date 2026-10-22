import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AttendScreen extends StatefulWidget {
  final XFile? image;

  const AttendScreen({super.key, this.image});

  @override
  State<AttendScreen> createState() => _AttendScreenState();
}

class _AttendScreenState extends State<AttendScreen> {
  // Variabel Lokasi
  bool isLoadingLocation = false;
  bool isSubmitting = false;
  double dLat = 0.0;
  double dLong = 0.0;
  String strAlamat = "Mencari lokasi GPS...";

  // Variabel Foto
  XFile? _selectedImage;
  Uint8List? _imageBytes;

  // Variabel Status & Waktu
  String strStatus = "Attend";
  String strDateTime = "";

  // Controller untuk input nama
  final TextEditingController nameController = TextEditingController();

  // Koneksi ke Koleksi Firestore
  final CollectionReference dataCollection =
      FirebaseFirestore.instance.collection('attendance');

  @override
  void initState() {
    super.initState();
    _selectedImage = widget.image;
    if (_selectedImage != null) {
      _loadImageBytes(_selectedImage!);
    }

    _updateCurrentTime();
    setStatusAbsen();
    getGeoLocationPosition();
  }

  Future<void> _loadImageBytes(XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      if (mounted) {
        setState(() {
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      debugPrint("Error loading image bytes: $e");
    }
  }

  void _updateCurrentTime() {
    final now = DateTime.now();
    try {
      strDateTime = DateFormat('EEEE, d MMMM yyyy HH:mm', 'id_ID').format(now);
    } catch (_) {
      strDateTime = DateFormat('EEEE, d MMMM yyyy HH:mm').format(now);
    }
  }

  // ==========================================
  // 1. Aturan Waktu Kehadiran Otomatis
  // ==========================================
  void setStatusAbsen() {
    final now = DateTime.now();
    final dateHours = now.hour;
    final dateMinutes = now.minute;

    if (dateHours < 8 || (dateHours == 8 && dateMinutes <= 30)) {
      strStatus = "Attend"; // Tepat waktu (sebelum / pukul 08:30)
    } else if ((dateHours > 8 && dateHours < 18) ||
        (dateHours == 8 && dateMinutes >= 31)) {
      strStatus = "Late"; // Terlambat (08:31 s/d 18:00)
    } else {
      strStatus = "Leave"; // Di luar jam operasional
    }
  }

  // ==========================================
  // 2. Akses Kamera / Pengambilan Foto Selfie
  // ==========================================
  Future<void> _pickSelfiePhoto() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (photo != null) {
        _selectedImage = photo;
        await _loadImageBytes(photo);
      }
    } catch (e) {
      // Fallback untuk browser jika camera tidak dapat diakses langsung via ImageSource.camera
      try {
        final XFile? photo = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        );
        if (photo != null) {
          _selectedImage = photo;
          await _loadImageBytes(photo);
        }
      } catch (err) {
        _showSnackBar("Tidak dapat mengakses kamera: $err", Icons.error_outline);
      }
    }
  }

  // ==========================================
  // 3. Pengiriman Payload ke Cloud Firestore
  // ==========================================
  Future<void> submitAbsen(String alamat, String nama, String status) async {
    final trimmedName = nama.trim();
    if (trimmedName.isEmpty) {
      _showSnackBar("Nama lengkap tidak boleh kosong!", Icons.warning_amber_rounded);
      return;
    }

    setState(() => isSubmitting = true);
    _showLoaderDialog();

    try {
      await dataCollection.add({
        'name': trimmedName,
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

      _showSnackBar("Presensi berhasil terekam ke sistem!", Icons.check_circle_outline);

      // Kembali ke layar sebelumnya dengan benar
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // Tutup Loader Dialog
      _showSnackBar("Gagal menyimpan presensi: $e", Icons.error_outline);
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }

  void _showLoaderDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                CircularProgressIndicator(color: Color(0xFF1E2B58)),
                SizedBox(width: 20),
                Expanded(
                  child: Text(
                    "Menyimpan data presensi...",
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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

  // ==========================================
  // 4. Penanganan Lokasi GPS (Aman untuk Web & Mobile)
  // ==========================================
  Future<bool> handleLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled && !kIsWeb) {
      _showSnackBar(
        "Layanan GPS dinonaktifkan. Silakan aktifkan GPS perangkat Anda.",
        Icons.location_off,
      );
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showSnackBar(
          "Izin akses lokasi ditolak oleh browser/perangkat.",
          Icons.warning_amber_rounded,
        );
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      _showSnackBar(
        "Izin lokasi ditolak permanen di pengaturan sistem.",
        Icons.error_outline,
      );
      return false;
    }
    return true;
  }

  Future<void> getGeoLocationPosition() async {
    final hasPermission = await handleLocationPermission();
    if (!hasPermission) {
      setState(() {
        strAlamat = "Izin lokasi tidak diberikan.";
        isLoadingLocation = false;
      });
      return;
    }

    setState(() => isLoadingLocation = true);

    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      dLat = position.latitude;
      dLong = position.longitude;

      await getAddressFromLongLat(position);
    } catch (e) {
      if (mounted) {
        setState(() {
          strAlamat = dLat != 0.0
              ? "Koordinat: ${dLat.toStringAsFixed(5)}, ${dLong.toStringAsFixed(5)}"
              : "Gagal mendeteksi lokasi: $e";
          isLoadingLocation = false;
        });
      }
    }
  }

  Future<void> getAddressFromLongLat(Position position) async {
    // Pada Flutter Web, geocoding native plugin tidak didukung.
    // Gunakan fallback koordinat yang bersih agar tidak memicu PlatformException.
    if (kIsWeb) {
      setState(() {
        strAlamat =
            "Koordinat: Lat ${position.latitude.toStringAsFixed(5)}, Long ${position.longitude.toStringAsFixed(5)} (Web Browser)";
        isLoadingLocation = false;
      });
      return;
    }

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty && mounted) {
        final place = placemarks[0];
        final parts = [
          place.street,
          place.subLocality,
          place.locality,
          place.administrativeArea,
          place.country,
        ].where((e) => e != null && e.isNotEmpty).toList();

        setState(() {
          strAlamat = parts.isNotEmpty
              ? parts.join(', ')
              : "Lat: ${position.latitude.toStringAsFixed(5)}, Long: ${position.longitude.toStringAsFixed(5)}";
          isLoadingLocation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          strAlamat =
              "Lat: ${position.latitude.toStringAsFixed(5)}, Long: ${position.longitude.toStringAsFixed(5)}";
          isLoadingLocation = false;
        });
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  Color _getStatusColor() {
    switch (strStatus) {
      case "Attend":
        return const Color(0xFF10B981); // Emerald
      case "Late":
        return const Color(0xFFF59E0B); // Amber
      default:
        return const Color(0xFFEF4444); // Red
    }
  }

  String _getStatusLabel() {
    switch (strStatus) {
      case "Attend":
        return "Tepat Waktu (Attend)";
      case "Late":
        return "Terlambat (Late)";
      default:
        return "Di Luar Jam Operasional (Leave)";
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Konfirmasi Presensi"),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Box Preview Foto Selfie
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      if (_imageBytes != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            _imageBytes!,
                            height: 220,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        )
                      else
                        Container(
                          height: 180,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFCBD5E1),
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.face_retouching_natural, size: 52, color: Colors.grey.shade400),
                              const SizedBox(height: 8),
                              Text(
                                "Foto verifikasi kehadiran",
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _pickSelfiePhoto,
                        icon: const Icon(Icons.camera_alt, size: 18),
                        label: Text(_imageBytes == null ? "Ambil Foto Selfie" : "Ganti Foto Selfie"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1E2B58),
                          side: const BorderSide(color: Color(0xFF1E2B58)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 2. Status Kehadiran & Waktu Realtime
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "STATUS PRESENSI",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: statusColor),
                            ),
                            child: Text(
                              _getStatusLabel(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        children: [
                          const Icon(Icons.schedule, size: 18, color: Color(0xFF2563EB)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              strDateTime.isNotEmpty ? strDateTime : "Memuat waktu...",
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 3. Card Lokasi GPS dengan Tombol Refresh
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.location_on, color: Color(0xFFEF4444), size: 20),
                              SizedBox(width: 6),
                              Text(
                                "Lokasi Presensi Anda",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            tooltip: "Segarkan Lokasi GPS",
                            onPressed: isLoadingLocation ? null : getGeoLocationPosition,
                            icon: isLoadingLocation
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.refresh, size: 20, color: Color(0xFF2563EB)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        strAlamat,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF475569),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 4. Input Nama Lengkap
                TextField(
                  controller: nameController,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Nama Lengkap Siswa',
                    hintText: 'Masukkan nama sesuai absensi',
                    prefixIcon: Icon(Icons.badge_outlined, color: Color(0xFF64748B)),
                  ),
                ),

                const SizedBox(height: 28),

                // 5. Tombol Submit Presensi
                ElevatedButton(
                  onPressed: (isLoadingLocation || isSubmitting)
                      ? null
                      : () => submitAbsen(strAlamat, nameController.text, strStatus),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E2B58),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    "KIRIM PRESENSI KEHADIRAN",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
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
