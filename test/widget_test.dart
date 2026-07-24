import 'package:flutter_test/flutter_test.dart';

import 'package:gatehub360_app/main.dart';

void main() {
  testWidgets('Login screen shows GateHub360 branding', (WidgetTester tester) async {
    await tester.pumpWidget(const GateHub360App());

    expect(find.textContaining('GateHub360', findRichText: true), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);
    expect(find.text('Continue as Guest'), findsOneWidget);
  });
}
