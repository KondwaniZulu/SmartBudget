import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartbudget_app/app/smart_budget_app.dart';

void main() {
  testWidgets('renders smart budget dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartBudgetApp());

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Welcome,'), findsOneWidget);
    expect(find.text('Kondwani'), findsOneWidget);
    expect(find.text('Total Balance'), findsOneWidget);
    expect(find.text('ZMW 11,200.30'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Monthly Goal'),
      220,
      scrollable: find.byType(Scrollable),
    );
    await tester.pumpAndSettle();
    expect(find.text('Monthly Goal'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Quick Actions'),
      220,
      scrollable: find.byType(Scrollable),
    );
    await tester.pumpAndSettle();
    expect(find.text('Quick Actions'), findsOneWidget);
    expect(find.text('Add Expense'), findsOneWidget);
    expect(find.text('Add Income'), findsOneWidget);
    expect(find.text('Set Budget'), findsOneWidget);

    await tester.tap(find.text('Add Expense'));
    await tester.pumpAndSettle();
    expect(find.text('Add Transaction'), findsOneWidget);
    expect(find.text('Save Expense'), findsOneWidget);

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'Library Printing',
    );
    await tester.enterText(find.byType(TextFormField).at(1), '35');
    await tester.tap(find.text('Save Expense'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Budget Overview'),
      220,
      scrollable: find.byType(Scrollable),
    );
    await tester.pumpAndSettle();
    expect(find.text('Budget Overview'), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);
    expect(find.text('Tax'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Recent Activity'),
      220,
      scrollable: find.byType(Scrollable),
    );
    await tester.pumpAndSettle();
    expect(find.text('Recent Activity'), findsOneWidget);
    expect(find.text('Library Printing'), findsOneWidget);

    final Rect navBarRect = tester.getRect(find.byType(NavigationBar));
    await tester.tapAt(
      Offset(navBarRect.left + navBarRect.width * 0.38, navBarRect.center.dy),
    );
    await tester.pumpAndSettle();
    expect(find.text('Budget Plan'), findsOneWidget);
  });

  testWidgets('set budget action opens budget editor sheet', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SmartBudgetApp());

    await tester.scrollUntilVisible(
      find.text('Quick Actions'),
      220,
      scrollable: find.byType(Scrollable),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Set Budget'));
    await tester.pumpAndSettle();
    expect(find.text('Save Budget'), findsOneWidget);
  });
}
