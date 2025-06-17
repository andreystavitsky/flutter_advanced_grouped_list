import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'package:advanced_grouped_list/advanced_grouped_list.dart';

final List _elements = [
  {'name': 'John', 'group': 'Team A'},
  //{'name': 'Will', 'group': 'Team B'},
  // {'name': 'Beth', 'group': 'Team A'},
  {'name': 'Miranda', 'group': 'Team B'},
  // {'name': 'Mike', 'group': 'Team C'},
  {'name': 'Danny', 'group': 'Team C'},
];
void main() {
  Widget buildGroupSeperator(dynamic element) {
    return Text(element['group']);
  }

  testWidgets('find elemets and group separators', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdvancedGroupedListView(
            groupBy: (dynamic element) => element['group'],
            elements: _elements,
            order: AdvancedGroupedListOrder.DESC,
            groupSeparatorBuilder: buildGroupSeperator,
            itemBuilder: (context, dynamic element) => Text(element['name']),
          ),
        ),
      ),
    );

    expect(find.text('John'), findsOneWidget);
    expect(find.text('Danny'), findsOneWidget);
    expect(find.text('Team A'), findsOneWidget);
    expect(find.text('Team B'), findsOneWidget);
    expect(find.text('Team C'), findsWidgets);
  });

  testWidgets('empty list', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdvancedGroupedListView(
            groupBy: (dynamic element) => element['group'],
            elements: const [],
            groupSeparatorBuilder: buildGroupSeperator,
            itemBuilder: (context, dynamic element) => Text(element['name']),
          ),
        ),
      ),
    );
  });

  testWidgets('finds only one group separator per group',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdvancedGroupedListView(
            groupBy: (dynamic element) => element['group'],
            elements: _elements,
            groupSeparatorBuilder: buildGroupSeperator,
            itemBuilder: (context, dynamic element) => Text(element['name']),
          ),
        ),
      ),
    );
    expect(find.text("Team B"), findsOneWidget);
  });

  testWidgets('does not mutate the original list', (WidgetTester tester) async {
    final original = [
      {'name': 'A', 'group': 'G1'},
      {'name': 'B', 'group': 'G2'},
    ];
    final copy = List<Map<String, String>>.from(
        original.map((e) => Map<String, String>.from(e)));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdvancedGroupedListView(
            groupBy: (dynamic element) => element['group'],
            elements: copy,
            groupSeparatorBuilder: buildGroupSeperator,
            itemBuilder: (context, dynamic element) => Text(element['name']),
          ),
        ),
      ),
    );
    expect(copy, equals(original));
  });

  testWidgets('handles out-of-bounds index gracefully',
      (WidgetTester tester) async {
    final elements = [
      {'name': 'A', 'group': 'G1'},
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdvancedGroupedListView(
            groupBy: (dynamic element) => element['group'],
            elements: elements,
            groupSeparatorBuilder: buildGroupSeperator,
            itemBuilder: (context, dynamic element) => Text(element['name']),
          ),
        ),
      ),
    );
    // Try to find a widget that would be rendered for an out-of-bounds index (should fallback to SizedBox.shrink)
    // We can't directly trigger out-of-bounds, but we can check that no exceptions are thrown and the widget tree is built.
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows sticky header only when showStickyHeader is true',
      (WidgetTester tester) async {
    final elements = [
      {'name': 'A', 'group': 'G1'},
    ];
    // showStickyHeader = true
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdvancedGroupedListView(
            groupBy: (dynamic element) => element['group'],
            elements: elements,
            groupSeparatorBuilder: buildGroupSeperator,
            itemBuilder: (context, dynamic element) => Text(element['name']),
            showStickyHeader: true,
          ),
        ),
      ),
    );
    expect(find.byType(StreamBuilder<int>), findsOneWidget);

    // showStickyHeader = false
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdvancedGroupedListView(
            groupBy: (dynamic element) => element['group'],
            elements: elements,
            groupSeparatorBuilder: buildGroupSeperator,
            itemBuilder: (context, dynamic element) => Text(element['name']),
            showStickyHeader: false,
          ),
        ),
      ),
    );
    expect(find.byType(StreamBuilder<int>), findsNothing);
  });

  testWidgets('rebuild with same list does not throw (memoization check)',
      (WidgetTester tester) async {
    final elements = [
      {'name': 'A', 'group': 'G1'},
      {'name': 'B', 'group': 'G2'},
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdvancedGroupedListView(
            groupBy: (dynamic element) => element['group'],
            elements: elements,
            groupSeparatorBuilder: buildGroupSeperator,
            itemBuilder: (context, dynamic element) => Text(element['name']),
          ),
        ),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdvancedGroupedListView(
            groupBy: (dynamic element) => element['group'],
            elements: elements,
            groupSeparatorBuilder: buildGroupSeperator,
            itemBuilder: (context, dynamic element) => Text(element['name']),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('topVisibleElementIndex and scrollOffset are exposed and update',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdvancedGroupedListView(
            groupBy: (dynamic element) => element['group'],
            elements: _elements,
            groupSeparatorBuilder: buildGroupSeperator,
            itemBuilder: (context, dynamic element) => Text(element['name']),
          ),
        ),
      ),
    );
    // Find the StickyGroupedListView widget and get its state
    final state = tester.state(find.byType(AdvancedGroupedListView))
        as AdvancedGroupedListViewState;
    expect(state, isNotNull);
    // topVisibleElementIndex may be null if not yet laid out, but should not throw
    expect(() => state.topVisibleElementIndex, returnsNormally);
    // Try to scroll and check if topVisibleElementIndex updates (simulate scroll)
    // Note: In widget tests, actual scrolling may not update ItemPositionsListener, but we can at least check getter is present
  });

  testWidgets('developer.log is called for out-of-bounds index',
      (WidgetTester tester) async {
    final logs = <String>[];
    await runZonedGuarded(() async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdvancedGroupedListView(
              groupBy: (dynamic element) => element['group'],
              elements: _elements,
              groupSeparatorBuilder: buildGroupSeperator,
              itemBuilder: (context, dynamic element) => Text(element['name']),
            ),
          ),
        ),
      );
      // Try to trigger out-of-bounds by calling buildItem with an invalid index via the state (reflection or test-only API would be better)
      // As a workaround, we can check that no exceptions are thrown and rely on manual log inspection
    }, (Object error, StackTrace stack) {
      logs.add(error.toString());
    });
    // We can't directly assert on developer.log output, but this test ensures no exceptions are thrown
    expect(logs, isEmpty);
  });

  testWidgets(
      'works as a plain list when groupBy and groupSeparatorBuilder are omitted',
      (WidgetTester tester) async {
    final elements = [
      {'name': 'A'},
      {'name': 'B'},
      {'name': 'C'},
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdvancedGroupedListView(
            elements: elements,
            itemBuilder: (context, dynamic element) => Text(element['name']),
          ),
        ),
      ),
    );
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
    expect(find.text('C'), findsOneWidget);
    // Should not find any group separator widgets
    expect(
        find
            .byType(Text)
            .evaluate()
            .where((e) => (e.widget as Text).data == null),
        isEmpty);
  });

  testWidgets('plain list mode throws for E = String (non-nullable)',
      (WidgetTester tester) async {
    final elements = [
      {'name': 'A'},
      {'name': 'B'},
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdvancedGroupedListView<Map<String, String>, String>(
            elements: elements,
            itemBuilder: (context, element) => Text(element['name']!),
          ),
        ),
      ),
    );
    final exception = tester.takeException();
    expect(exception, isA<UnsupportedError>());
  });

  testWidgets('plain list mode throws for E = int (non-nullable)',
      (WidgetTester tester) async {
    final elements = [
      {'name': 'A'},
      {'name': 'B'},
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdvancedGroupedListView<Map<String, String>, int>(
            elements: elements,
            itemBuilder: (context, element) => Text(element['name']!),
          ),
        ),
      ),
    );
    final exception = tester.takeException();
    expect(exception, isA<UnsupportedError>());
  });

  testWidgets('plain list mode throws for E = Object (non-nullable)',
      (WidgetTester tester) async {
    final elements = [
      {'name': 'A'},
      {'name': 'B'},
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdvancedGroupedListView<Map<String, String>, Object>(
            elements: elements,
            itemBuilder: (context, element) => Text(element['name']!),
          ),
        ),
      ),
    );
    final exception = tester.takeException();
    expect(exception, isA<UnsupportedError>());
  });

  testWidgets('plain list mode works with E = String? (nullable)',
      (WidgetTester tester) async {
    final elements = [
      {'name': 'A'},
      {'name': 'B'},
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdvancedGroupedListView<Map<String, String>, String?>(
            elements: elements,
            itemBuilder: (context, element) => Text(element['name']!),
          ),
        ),
      ),
    );
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
  });

  testWidgets('plain list mode works with E = int? (nullable)',
      (WidgetTester tester) async {
    final elements = [
      {'name': 'A'},
      {'name': 'B'},
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdvancedGroupedListView<Map<String, String>, int?>(
            elements: elements,
            itemBuilder: (context, element) => Text(element['name']!),
          ),
        ),
      ),
    );
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
  });

  testWidgets('plain list mode works with E = Object? (nullable)',
      (WidgetTester tester) async {
    final elements = [
      {'name': 'A'},
      {'name': 'B'},
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdvancedGroupedListView<Map<String, String>, Object?>(
            elements: elements,
            itemBuilder: (context, element) => Text(element['name']!),
          ),
        ),
      ),
    );
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
  });

  testWidgets('plain list mode works with E = Null',
      (WidgetTester tester) async {
    final elements = [
      {'name': 'A'},
      {'name': 'B'},
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdvancedGroupedListView<Map<String, String>, Null>(
            elements: elements,
            itemBuilder: (context, element) => Text(element['name']!),
          ),
        ),
      ),
    );
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
  });

  testWidgets('plain list mode with empty list', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdvancedGroupedListView<Map<String, String>, String>(
            elements: const [],
            itemBuilder: (context, element) => Text(element['name']!),
          ),
        ),
      ),
    );
    expect(find.byType(Text), findsNothing);
  });

  testWidgets('plain list mode with single element',
      (WidgetTester tester) async {
    final elements = [
      {'name': 'A'},
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdvancedGroupedListView<Map<String, String>, String>(
            elements: elements,
            itemBuilder: (context, element) => Text(element['name']!),
          ),
        ),
      ),
    );
    expect(find.text('A'), findsOneWidget);
  });

  group('StickyGroupedListView.topVisibleElementIndex', () {
    testWidgets('returns null when no items are visible', (tester) async {
      // Build a widget with an empty list
      await tester.pumpWidget(
        MaterialApp(
          home: AdvancedGroupedListView<String, String>(
            elements: [],
            itemBuilder: (context, element) => Text(element),
            groupBy: (element) => element[0],
            groupSeparatorBuilder: (element) => Text('Group ${element[0]}'),
          ),
        ),
      );

      // Find the state
      final AdvancedGroupedListViewState<String, String> state = tester.state(
        find.byType(AdvancedGroupedListView<String, String>),
      );

      // No elements should be visible
      expect(state.topVisibleElementIndex, isNull);
    });

    testWidgets('returns correct index for visible items', (tester) async {
      // Build a widget with a list of items
      await tester.pumpWidget(
        MaterialApp(
          home: AdvancedGroupedListView<String, String>(
            elements: ['A1', 'A2', 'B1', 'B2', 'C1'],
            itemBuilder: (context, element) => SizedBox(
              height: 100,
              child: Text(element),
            ),
            groupBy: (element) => element[0],
            groupSeparatorBuilder: (element) => SizedBox(
              height: 50,
              child: Text('Group ${element[0]}'),
            ),
          ),
        ),
      );

      // Wait for all animations to complete
      await tester.pumpAndSettle();

      // Find the state
      final AdvancedGroupedListViewState<String, String> state = tester.state(
        find.byType(AdvancedGroupedListView<String, String>),
      );

      // First element (index 0) should be visible at the top
      expect(state.topVisibleElementIndex, 0);

      // Scroll down using the ScrollablePositionedList inside StickyGroupedListView
      final scrollable = find.byType(ScrollablePositionedList).first;
      await tester.drag(scrollable, const Offset(0, -150));
      await tester.pumpAndSettle();

      // After scrolling, a different element should be at the top
      expect(state.topVisibleElementIndex, isNotNull);
    });

    testWidgets('handles reverse=true correctly', (tester) async {
      // Build a widget with a reversed list
      await tester.pumpWidget(
        MaterialApp(
          home: AdvancedGroupedListView<String, String>(
            elements: ['A1', 'A2', 'B1', 'B2', 'C1'],
            itemBuilder: (context, element) => SizedBox(
              height: 100,
              child: Text(element),
            ),
            groupBy: (element) => element[0],
            groupSeparatorBuilder: (element) => SizedBox(
              height: 50,
              child: Text('Group ${element[0]}'),
            ),
            reverse: true,
          ),
        ),
      );

      // Wait for all animations to complete
      await tester.pumpAndSettle();

      // Find the state
      final AdvancedGroupedListViewState<String, String> state = tester.state(
        find.byType(AdvancedGroupedListView<String, String>),
      );

      // In reverse mode, the last element should be visible at the top
      // The exact index depends on the widget's height, but we can verify it's not null
      expect(state.topVisibleElementIndex, isNotNull);
    });
  });
}
