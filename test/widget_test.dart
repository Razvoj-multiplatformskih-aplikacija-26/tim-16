import 'package:flutter_test/flutter_test.dart';
import 'package:svezko_app/app.dart';
import 'package:svezko_app/main.dart';

void main() {
  testWidgets('Provera učitavanja Svezko aplikacije', (WidgetTester tester) async {
    // Pokreni aplikaciju
    await tester.pumpWidget(const SvezkoApp());

    // Proveri da li se naslov prikazuje na ekranu
    expect(find.text('Svezko - Korisnički pregled'), findsOneWidget);
  });
}