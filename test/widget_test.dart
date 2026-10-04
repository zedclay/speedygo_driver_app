import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_driver_app/app/app.dart';

void main() {
  testWidgets('renders application shell', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: SpeedyGoApp()));

    expect(find.text('SpeedyGo Driver'), findsOneWidget);
    expect(
      find.text(
        'Application shell only. Driver features are not implemented yet.',
      ),
      findsOneWidget,
    );
  });
}
