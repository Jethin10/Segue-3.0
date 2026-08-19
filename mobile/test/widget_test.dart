import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pramaan_mobile/main.dart';

void main() {
  testWidgets('starts the offline demo without Firebase setup', (tester) async {
    await tester.pumpWidget(const SatyakApp());

    expect(find.text('SATYAK  सत्यक'), findsOneWidget);
    expect(find.text('Offline demo ready'), findsOneWidget);
    expect(find.textContaining('Firebase project'), findsOneWidget);
    expect(find.text('Connect Firebase to continue'), findsNothing);
  });

  testWidgets('citizen can enter the seeded demo', (tester) async {
    await tester.pumpWidget(const SatyakApp());
    await tester.tap(find.byKey(const Key('citizen-demo')));
    await tester.pumpAndSettle();

    expect(find.text('Your city should show its work.'), findsOneWidget);
    expect(find.text('Overflowing garbage near school'), findsOneWidget);
    expect(find.byKey(const Key('report-issue')), findsOneWidget);
  });

  testWidgets('citizen can submit a report without device permissions',
      (tester) async {
    await tester.pumpWidget(const SatyakApp());
    await tester.tap(find.byKey(const Key('citizen-demo')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('report-issue')));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const Key('issue-description')), 'Broken streetlight');
    await tester.tap(find.byKey(const Key('demo-location')));
    await tester.tap(find.byKey(const Key('demo-photo')));
    await tester.ensureVisible(find.byKey(const Key('submit-report')));
    await tester.tap(find.byKey(const Key('submit-report')));
    await tester.pumpAndSettle();

    expect(find.text('Broken streetlight'), findsOneWidget);
    expect(find.text('Citizen report recorded'), findsOneWidget);
  });

  testWidgets('worker can create demo proof without Firebase', (tester) async {
    await tester.pumpWidget(const SatyakApp());
    await tester.tap(find.byKey(const Key('worker-demo')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Overflowing garbage near school'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('start-verification')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('demo-selfie')));
    await tester.tap(find.byKey(const Key('demo-selfie')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('demo-before')));
    await tester.tap(find.byKey(const Key('demo-before')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('demo-after')));
    await tester.tap(find.byKey(const Key('demo-after')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('submit-proof')));
    await tester.tap(find.byKey(const Key('submit-proof')));
    await tester.pumpAndSettle();

    expect(find.text('PROOF OF SERVICE CREATED'), findsOneWidget);
    expect(find.text('Awaiting citizen verification'), findsOneWidget);
  });
}
