import 'package:flutter_test/flutter_test.dart';
import 'package:attendance_app/main.dart';
import 'package:attendance_app/ui/home_screen.dart';

void main() {
  testWidgets('AttendanceApp UI Smoke Test', (WidgetTester tester) async {
    await tester.pumpWidget(const AttendanceApp());
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Presensi Digital XI RPL'), findsOneWidget);
    expect(find.text('Presensi Kehadiran'), findsOneWidget);
    expect(find.text('Pengajuan Izin & Sakit'), findsOneWidget);
  });
}
