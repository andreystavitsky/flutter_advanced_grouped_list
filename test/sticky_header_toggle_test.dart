import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:advanced_grouped_list/advanced_grouped_list.dart';

void main() {
  final List elements = [
    {'name': 'John', 'group': 'Team A'},
    {'name': 'Miranda', 'group': 'Team B'},
    {'name': 'Danny', 'group': 'Team C'},
  ];

  Widget buildGroupSeparator(dynamic element) {
    return Text(element['group']);
  }

  testWidgets('showStickyHeader can be toggled multiple times',
      (WidgetTester tester) async {
    // Create a StatefulWidget to toggle showStickyHeader
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TestToggleSticky(
            elements: elements,
            buildGroupSeparator: buildGroupSeparator,
          ),
        ),
      ),
    );

    // Initially, sticky header should be visible (SizedBox.shrink is used when not showing)
    expect(find.text('Team A', skipOffstage: false),
        findsNWidgets(2)); // One for regular list, one for sticky header

    // Toggle showStickyHeader to false
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    // Sticky header should be gone
    expect(find.text('Team A', skipOffstage: false),
        findsOneWidget); // Only the one in the regular list

    // Toggle showStickyHeader back to true
    try {
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // This is where the error would occur - the StreamBuilder should be back
      expect(find.text('Team A', skipOffstage: false), findsNWidgets(2));

      // Toggle a few more times to ensure it works reliably
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      expect(find.text('Team A', skipOffstage: false), findsOneWidget);

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Final state should match button presses (true after even number of toggles)
      expect(find.text('Team A', skipOffstage: false), findsNWidgets(2));
    } catch (e) {
      // If we get an error, it confirms the issue exists
      fail('Got exception when toggling showStickyHeader: $e');
    }
  });
}

class TestToggleSticky extends StatefulWidget {
  final List elements;
  final Widget Function(dynamic) buildGroupSeparator;

  const TestToggleSticky({
    super.key,
    required this.elements,
    required this.buildGroupSeparator,
  });

  @override
  State<TestToggleSticky> createState() => _TestToggleStickyState();
}

class _TestToggleStickyState extends State<TestToggleSticky> {
  bool showStickyHeader = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () {
            setState(() {
              showStickyHeader = !showStickyHeader;
            });
          },
          child: Text(
              showStickyHeader ? 'Hide Sticky Header' : 'Show Sticky Header'),
        ),
        Expanded(
          child: AdvancedGroupedListView(
            groupBy: (dynamic element) => element['group'],
            elements: widget.elements,
            groupSeparatorBuilder: widget.buildGroupSeparator,
            itemBuilder: (context, dynamic element) => Text(element['name']),
            showStickyHeader: showStickyHeader,
          ),
        ),
      ],
    );
  }
}
