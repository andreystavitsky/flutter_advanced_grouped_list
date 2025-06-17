import 'package:flutter/material.dart';
import 'package:advanced_grouped_list/advanced_grouped_list.dart';
import 'dart:developer' as developer;

/// Example demonstrating the FIXED scrollTo/jumpTo behavior when elements have different heights
/// This example shows that elements are now positioned correctly under the sticky header
/// regardless of their varying heights and group separator heights.
class VariableHeightExample extends StatefulWidget {
  const VariableHeightExample({Key? key}) : super(key: key);

  @override
  State<VariableHeightExample> createState() => _VariableHeightExampleState();
}

class _VariableHeightExampleState extends State<VariableHeightExample> {
  final GroupedItemScrollController _controller = GroupedItemScrollController();
  final ItemPositionsListener _positionsListener =
      ItemPositionsListener.create();

  // Create elements with different heights
  final List<ElementWithHeight> elements = [
    // Group 1 - varying item heights
    ElementWithHeight('Item 1-1', 'Group 1', 50.0),
    ElementWithHeight('Item 1-2', 'Group 1', 80.0),
    ElementWithHeight('Item 1-3', 'Group 1', 120.0),

    // Group 2 - different item heights
    ElementWithHeight('Item 2-1', 'Group 2', 60.0),
    ElementWithHeight('Item 2-2', 'Group 2', 100.0),
    ElementWithHeight('Item 2-3', 'Group 2', 40.0),
    ElementWithHeight('Item 2-4', 'Group 2', 90.0),

    // Group 3 - more varying heights
    ElementWithHeight('Item 3-1', 'Group 3', 70.0),
    ElementWithHeight('Item 3-2', 'Group 3', 110.0),
    ElementWithHeight('Item 3-3', 'Group 3', 45.0),
    ElementWithHeight('Item 3-4', 'Group 3', 85.0),
    ElementWithHeight('Item 3-5', 'Group 3', 130.0),

    ElementWithHeight('Item 4-1', 'Group 4', 70.0),
    ElementWithHeight('Item 4-2', 'Group 4', 110.0),
    ElementWithHeight('Item 4-3', 'Group 4', 45.0),
    ElementWithHeight('Item 4-4', 'Group 4', 85.0),
    ElementWithHeight('Item 4-5', 'Group 4', 130.0),
    ElementWithHeight('Item 4-6', 'Group 4', 230.0),
    ElementWithHeight('Item 4-7', 'Group 4', 170.0),
    ElementWithHeight('Item 4-8', 'Group 4', 30.0),
    ElementWithHeight('Item 4-9', 'Group 4', 300.0),
  ];

  void _scrollToIndex(int index) {
    if (_controller.isAttached) {
      final element = elements[index];
      developer.log(
          'Scrolling to index: $index - ${element.name} (${element.group}, ${element.height}px)',
          name: 'VariableHeightExample');
      _controller.scrollTo(
        index: index,
        duration: const Duration(milliseconds: 800),
      );
    }
  }

  void _jumpToIndex(int index) {
    if (_controller.isAttached) {
      final element = elements[index];
      developer.log(
          'Jumping to index: $index - ${element.name} (${element.group}, ${element.height}px)',
          name: 'VariableHeightExample');
      _controller.jumpTo(index: index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Variable Height Elements'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: () => _jumpToIndex(0),
                    child: const Text('Jump to 0\n(Item 1-1)'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _scrollToIndex(5),
                    child: const Text('Scroll to 5\n(Item 2-3)'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _jumpToIndex(10),
                    child: const Text('Jump to 10\n(Item 3-4)'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _scrollToIndex(9),
                    child: const Text('Scroll to 9\n(Item 3-3)'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _scrollToIndex(elements.length - 1),
                    child: const Text('Scroll to Last'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      developer.log(
                          'Element at index 5: ${elements[5].name} - ${elements[5].group}',
                          name: 'Debug');
                    },
                    child: const Text('Debug Index 5'),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: AdvancedGroupedListView<ElementWithHeight, String>(
              elements: elements,
              groupBy: (element) => element.group,
              groupSeparatorBuilder: (element) => _buildGroupSeparator(element),
              itemBuilder: (context, element) => _buildItem(element),
              itemScrollController: _controller,
              itemPositionsListener: _positionsListener,
              showStickyHeader: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupSeparator(ElementWithHeight element) {
    // Different heights for different groups to demonstrate the issue
    double height;
    Color color;
    switch (element.group) {
      case 'Group 1':
        height = 60.0;
        color = Colors.blue[100]!;
        break;
      case 'Group 2':
        height = 80.0;
        color = Colors.green[100]!;
        break;
      case 'Group 3':
        height = 100.0;
        color = Colors.orange[100]!;
        break;
      case 'Group 4':
        height = 150.0;
        color = Colors.purple[100]!;
        break;
      default:
        height = 50.0;
        color = Colors.grey[100]!;
    }

    return Container(
      height: height,
      color: color,
      width: double.infinity,
      child: Center(
        child: Text(
          element.group,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildItem(ElementWithHeight element) {
    // Ensure minimum height for proper text display
    final displayHeight = element.height < 60 ? 60.0 : element.height;

    return Container(
      height: displayHeight,
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              element.name,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Height: ${element.height}px',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            if (displayHeight != element.height)
              Text(
                '(min: 60px)',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.red[400],
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ElementWithHeight {
  final String name;
  final String group;
  final double height;

  ElementWithHeight(this.name, this.group, this.height);
}
