import 'dart:io';
import 'package:flutter/services.dart';

Future<String> downloadCsvFile(String csvContent, String fileName) async {
  final file = File('${Directory.systemTemp.path}/$fileName');
  await file.writeAsString('\uFEFF$csvContent', flush: true);

  // Salin ke clipboard juga agar pengguna mobile dapat langsung membagikan/menempelkannya
  await Clipboard.setData(ClipboardData(text: csvContent));
  return file.path;
}
