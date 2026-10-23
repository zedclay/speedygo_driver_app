import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_driver_app/features/availability/presentation/availability_slide_control.dart';

Widget _harness({
  required AvailabilitySlideControl child,
  TextDirection direction = TextDirection.ltr,
}) {
  return MaterialApp(
    home: Directionality(
      textDirection: direction,
      child: Scaffold(
        body: Center(
          child: SizedBox(width: 320, child: child),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('partial drag returns without calling onConfirmed', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      _harness(
        child: AvailabilitySlideControl(
          key: const Key('go_online_button'),
          onlineMode: false,
          label: 'slide',
          pendingLabel: 'pending',
          onConfirmed: () => calls += 1,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byKey(const Key('go_online_button')), const Offset(80, 0));
    await tester.pumpAndSettle();
    expect(calls, 0);
    final state = tester.state<AvailabilitySlideControlState>(
      find.byType(AvailabilitySlideControl),
    );
    expect(state.progress, lessThan(0.2));
  });

  testWidgets('complete drag fires once and shows pending label', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      _harness(
        child: AvailabilitySlideControl(
          key: const Key('go_online_button'),
          onlineMode: false,
          label: 'slide',
          pendingLabel: 'pending…',
          busy: false,
          onConfirmed: () => calls += 1,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const Key('go_online_button')),
      const Offset(280, 0),
    );
    await tester.pump();
    expect(calls, 1);
    expect(find.text('pending…'), findsOneWidget);

    await tester.drag(
      find.byKey(const Key('go_online_button')),
      const Offset(280, 0),
    );
    await tester.pump();
    expect(calls, 1);
  });

  testWidgets('failure while busy clears and rolls thumb back', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      _harness(
        child: AvailabilitySlideControl(
          key: const Key('slide'),
          onlineMode: false,
          label: 'slide',
          pendingLabel: 'pending…',
          busy: false,
          onConfirmed: () => calls += 1,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byKey(const Key('slide')), const Offset(280, 0));
    await tester.pump();
    expect(calls, 1);

    await tester.pumpWidget(
      _harness(
        child: AvailabilitySlideControl(
          key: const Key('slide'),
          onlineMode: false,
          label: 'slide',
          pendingLabel: 'pending…',
          busy: true,
          onConfirmed: () => calls += 1,
        ),
      ),
    );
    await tester.pump();

    await tester.pumpWidget(
      _harness(
        child: AvailabilitySlideControl(
          key: const Key('slide'),
          onlineMode: false,
          label: 'slide',
          pendingLabel: 'pending…',
          busy: false,
          onConfirmed: () => calls += 1,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final state = tester.state<AvailabilitySlideControlState>(
      find.byType(AvailabilitySlideControl),
    );
    expect(state.progress, lessThan(0.15));
    expect(find.text('slide'), findsOneWidget);
    expect(calls, 1);
  });

  testWidgets('RTL go-online completes when dragging toward start', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      _harness(
        direction: TextDirection.rtl,
        child: AvailabilitySlideControl(
          key: const Key('go_online_button'),
          onlineMode: false,
          label: 'slide',
          pendingLabel: 'pending',
          onConfirmed: () => calls += 1,
        ),
      ),
    );
    await tester.pumpAndSettle();
    // In RTL, confirm direction is toward the left (negative dx in global).
    await tester.drag(
      find.byKey(const Key('go_online_button')),
      const Offset(-280, 0),
    );
    await tester.pump();
    expect(calls, 1);
  });
}
