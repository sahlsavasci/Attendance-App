import 'dart:convert';
import 'dart:js_interop';

@JS('document.createElement')
external JSObject _createElement(String tagName);

@JS('document.body.appendChild')
external void _appendChild(JSObject node);

extension type _AnchorElement(JSObject _) implements JSObject {
  external set href(String value);
  external set download(String value);
  external void click();
  external void remove();
}

Future<String> downloadCsvFile(String csvContent, String fileName) async {
  // Tambahkan UTF-8 BOM (\uFEFF) agar Microsoft Excel membaca kolom dengan benar
  final encoded = base64Encode(utf8.encode('\uFEFF$csvContent'));
  final dataUri = 'data:text/csv;charset=utf-8;base64,$encoded';

  final anchor = _AnchorElement(_createElement('a'));
  anchor.href = dataUri;
  anchor.download = fileName;
  _appendChild(anchor);
  anchor.click();
  anchor.remove();

  return fileName;
}

