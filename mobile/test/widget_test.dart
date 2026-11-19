import 'package:flutter_test/flutter_test.dart';

import 'package:ccd_raffle/main.dart';

void main() {
  testWidgets('Home screen shows New Sale and History buttons', (WidgetTester tester) async {
    await tester.pumpWidget(const CcdRaffleApp());

    expect(find.text('New Sale'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
  });
}
