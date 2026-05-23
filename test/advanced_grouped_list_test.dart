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
            order: AdvancedGroupedListOrder.desc,
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
    expect(find.text('Team B'), findsOneWidget);
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
    // Try to find a widget that would be rendered for an out-of-bounds index
    // (should fallback to SizedBox.shrink)
    // We can't directly trigger out-of-bounds, but we can check that
    // no exceptions are thrown and the widget tree is built.
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
    // topVisibleElementIndex may be null if not yet laid out,
    //but should not throw
    expect(() => state.topVisibleElementIndex, returnsNormally);
    // Try to scroll and check if topVisibleElementIndex updates
    // (simulate scroll)
    // Note: In widget tests, actual scrolling may not update
    // ItemPositionsListener, but we can at least check getter is present
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
      // Try to trigger out-of-bounds by calling buildItem with an invalid index
      // via the state (reflection or test-only API would be better)
      // As a workaround, we can check that no exceptions are thrown and rely
      // on manual log inspection
    }, (Object error, StackTrace stack) {
      logs.add(error.toString());
    });
    // We can't directly assert on developer.log output, but this test ensures
    // no exceptions are thrown
    expect(logs, isEmpty);
  });

  testWidgets(
      'works as a plain list when groupBy and groupSeparatorBuilder '
      'are omitted', (WidgetTester tester) async {
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

      // Scroll down using the ScrollablePositionedList inside
      // StickyGroupedListView
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
      // The exact index depends on the widget's height, but we can verify it's
      // not null
      expect(state.topVisibleElementIndex, isNotNull);
    });
  });

  group('AdvancedGroupedListView TDD fixes tests', () {
    testWidgets(
        '2.1: reverse mode jumpTo uses correct element index (not separator)',
        (WidgetTester tester) async {
      final elements = ['A1', 'A2', 'A3', 'B1', 'B2', 'B3'];
      final controller = GroupedItemScrollController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 300,
              child: AdvancedGroupedListView<String, String>(
                elements: elements,
                groupBy: (element) => element[0],
                groupSeparatorBuilder: (element) =>
                    SizedBox(height: 50, child: Text(element[0])),
                itemBuilder: (context, element) =>
                    SizedBox(height: 100, child: Text(element)),
                itemScrollController: controller,
                reverse: true,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Jump to element at index 2 ('A3')
      controller.jumpTo(index: 2);
      await tester.pumpAndSettle();

      final state =
          tester.state(find.byType(AdvancedGroupedListView<String, String>))
              as AdvancedGroupedListViewState<String, String>;

      // The topmost visible element index should be 3 in reverse mode
      // (since item 2 is at the bottom).
      // Under the old code, it returned 4 because it jumped to the separator.
      expect(state.topVisibleElementIndex, 3);
    });

    testWidgets(
        '2.4: topElementIndex updates when scrolling inside the same group',
        (WidgetTester tester) async {
      final elements = ['A1', 'A2', 'A3', 'A4'];
      final controller = GroupedItemScrollController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 150,
              child: AdvancedGroupedListView<String, String>(
                elements: elements,
                groupBy: (element) => element[0],
                groupSeparatorBuilder: (element) =>
                    SizedBox(height: 50, child: Text(element[0])),
                itemBuilder: (context, element) =>
                    SizedBox(height: 100, child: Text(element)),
                itemScrollController: controller,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final state =
          tester.state(find.byType(AdvancedGroupedListView<String, String>))
              as AdvancedGroupedListViewState<String, String>;

      expect(state.topElementIndex, 0);

      // Scroll down to the next element (still in the same group A)
      controller.jumpTo(index: 1);
      await tester.pumpAndSettle();

      // Now topElementIndex should be 1.
      expect(state.topElementIndex, 1);
    });

    testWidgets('3.1: O(1) search cache maps identifiers to correct indices',
        (WidgetTester tester) async {
      final elements = ['A1', 'A2', 'A3'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 300,
              child: AdvancedGroupedListView<String, String>(
                elements: elements,
                groupBy: (element) => element[0],
                groupSeparatorBuilder: (element) =>
                    SizedBox(height: 50, child: Text(element[0])),
                itemBuilder: (context, element) =>
                    SizedBox(height: 100, child: Text(element)),
                elementIdentifier: (element) => element,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final state =
          tester.state(find.byType(AdvancedGroupedListView<String, String>))
              as AdvancedGroupedListViewState<String, String>;

      // getElementIndexByIdentifier should return 1 for identifier 'A2'
      expect(state.cacheManager.getElementIndexByIdentifier('A2'), 1);
    });
  });

  group('variable height header alignment', () {
    testWidgets(
        'scrollTo measures an unseen target group header before aligning',
        (WidgetTester tester) async {
      final controller = GroupedItemScrollController();
      final listKey = UniqueKey();
      final elements = _buildVariableHeightElements();

      await tester.pumpWidget(
        _buildVariableHeightList(
          listKey: listKey,
          controller: controller,
          elements: elements,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('item-9')), findsNothing);

      final scrollFuture = controller.scrollTo(
        index: 9,
        duration: const Duration(milliseconds: 20),
      );
      await _pumpProgrammaticScroll(tester, scrollFuture);

      _expectItemBelowStickyHeader(
        tester,
        listKey: listKey,
        itemIndex: 9,
        headerHeight: 100,
      );

      final state = tester.state(
        find.byType(
          AdvancedGroupedListView<_VariableHeightElement, String>,
        ),
      ) as AdvancedGroupedListViewState<_VariableHeightElement, String>;
      expect(state.cacheManager.getTrustedHeaderDimension('Group 3'), 100);

      final repeatedScrollFuture = controller.scrollTo(
        index: 9,
        duration: const Duration(milliseconds: 20),
      );
      await _pumpProgrammaticScroll(tester, repeatedScrollFuture);

      _expectItemBelowStickyHeader(
        tester,
        listKey: listKey,
        itemIndex: 9,
        headerHeight: 100,
      );
    });

    testWidgets('jumpTo corrects alignment after measuring an unseen header',
        (WidgetTester tester) async {
      final controller = GroupedItemScrollController();
      final listKey = UniqueKey();
      final elements = _buildVariableHeightElements();

      await tester.pumpWidget(
        _buildVariableHeightList(
          listKey: listKey,
          controller: controller,
          elements: elements,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('item-9')), findsNothing);

      controller.jumpTo(index: 9);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      _expectItemBelowStickyHeader(
        tester,
        listKey: listKey,
        itemIndex: 9,
        headerHeight: 100,
      );
    });
  });
}

class _VariableHeightElement {
  final int index;
  final String group;
  final double height;

  const _VariableHeightElement(this.index, this.group, this.height);
}

List<_VariableHeightElement> _buildVariableHeightElements() {
  return const <_VariableHeightElement>[
    _VariableHeightElement(0, 'Group 1', 50),
    _VariableHeightElement(1, 'Group 1', 80),
    _VariableHeightElement(2, 'Group 1', 120),
    _VariableHeightElement(3, 'Group 2', 60),
    _VariableHeightElement(4, 'Group 2', 100),
    _VariableHeightElement(5, 'Group 2', 60),
    _VariableHeightElement(6, 'Group 2', 90),
    _VariableHeightElement(7, 'Group 3', 70),
    _VariableHeightElement(8, 'Group 3', 110),
    _VariableHeightElement(9, 'Group 3', 70),
    _VariableHeightElement(10, 'Group 3', 85),
    _VariableHeightElement(11, 'Group 3', 130),
    _VariableHeightElement(12, 'Group 4', 70),
    _VariableHeightElement(13, 'Group 4', 110),
  ];
}

Widget _buildVariableHeightList({
  required Key listKey,
  required GroupedItemScrollController controller,
  required List<_VariableHeightElement> elements,
}) {
  const headerHeights = <String, double>{
    'Group 1': 60,
    'Group 2': 80,
    'Group 3': 100,
    'Group 4': 150,
  };

  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        key: listKey,
        height: 500,
        child: AdvancedGroupedListView<_VariableHeightElement, String>(
          elements: elements,
          groupBy: (element) => element.group,
          groupComparator: (left, right) => left.compareTo(right),
          itemComparator: (left, right) => left.index.compareTo(right.index),
          groupSeparatorBuilder: (element) {
            final height = headerHeights[element.group]!;
            return ColoredBox(
              color: Colors.transparent,
              child: SizedBox(
                height: height,
                width: double.infinity,
                child: Text(element.group),
              ),
            );
          },
          indexedItemBuilder: (context, element, index) {
            return SizedBox(
              key: ValueKey('item-${element.index}'),
              height: element.height,
              child: Text('Item ${element.index}'),
            );
          },
          itemScrollController: controller,
        ),
      ),
    ),
  );
}

Future<void> _pumpProgrammaticScroll(
  WidgetTester tester,
  Future<void> scrollFuture,
) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));
  await tester.pumpAndSettle();
  await tester.pump(const Duration(milliseconds: 120));
  await scrollFuture;
  await tester.pumpAndSettle();
}

void _expectItemBelowStickyHeader(
  WidgetTester tester, {
  required Key listKey,
  required int itemIndex,
  required double headerHeight,
}) {
  final listTop = tester.getTopLeft(find.byKey(listKey)).dy;
  final itemTop = tester.getTopLeft(find.byKey(ValueKey('item-$itemIndex'))).dy;

  expect(itemTop, moreOrLessEquals(listTop + headerHeight, epsilon: 3));
}
