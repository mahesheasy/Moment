import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moment/core/theme/app_spacing.dart';
import 'package:moment/core/widgets/moment_button.dart';

void main() {
  test('spacing scale matches spec', () {
    expect(AppSpacing.xs, 4);
    expect(AppSpacing.sm, 8);
    expect(AppSpacing.md, 12);
    expect(AppSpacing.lg, 16);
    expect(AppSpacing.xl, 20);
    expect(AppSpacing.xxl, 24);
    expect(AppSpacing.xxxl, 32);
    expect(AppSpacing.huge, 40);
    expect(AppSpacing.massive, 48);
  });

  testWidgets('MomentButton renders label', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MomentButton(
            label: 'Take a moment',
            onPressed: () {},
          ),
        ),
      ),
    );
    expect(find.text('Take a moment'), findsOneWidget);
  });

  testWidgets('MomentButton in a Row does not force infinite width', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              Row(
                children: [
                  const Text('Memories'),
                  const Spacer(),
                  MomentButton(
                    label: 'New',
                    variant: MomentButtonVariant.secondary,
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('New'), findsOneWidget);
  });
}
