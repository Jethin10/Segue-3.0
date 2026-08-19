import 'package:flutter_test/flutter_test.dart';
import 'package:pramaan_mobile/main.dart';

void main() {
  testWidgets('shows a recoverable setup screen without Firebase configuration',
      (tester) async {
    await tester.pumpWidget(const PramaanApp());

    expect(find.text('PRAMAAN  प्रमाण'), findsOneWidget);
    expect(find.text('Connect Firebase to continue'), findsOneWidget);
    expect(find.textContaining('flutterfire configure'), findsOneWidget);
  });
}
