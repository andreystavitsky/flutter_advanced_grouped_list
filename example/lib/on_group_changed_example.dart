import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:advanced_grouped_list/advanced_grouped_list.dart';

class OnGroupChangedExample extends StatefulWidget {
  const OnGroupChangedExample({super.key});

  @override
  State<OnGroupChangedExample> createState() => _OnGroupChangedExampleState();
}

class _OnGroupChangedExampleState extends State<OnGroupChangedExample> {
  final GroupedItemScrollController _controller = GroupedItemScrollController();
  late final List<Map<String, String>> elements;

  @override
  void initState() {
    super.initState();
    elements = List.generate(
      30,
      (i) => {
        'name': 'Item $i',
        'group': 'Group ${i ~/ 5 + 1}',
      },
    );
  }

  void _jumpToGroup(int groupNumber) {
    final idx =
        elements.indexWhere((el) => el['group'] == 'Group $groupNumber');
    if (idx != -1) {
      _controller.jumpToGroup(index: idx);
    }
  }

  void _scrollToGroup(int groupNumber) {
    final idx =
        elements.indexWhere((el) => el['group'] == 'Group $groupNumber');
    if (idx != -1) {
      _controller.scrollToGroup(
          index: idx, duration: const Duration(milliseconds: 500));
    }
  }

  void _jumpToStart() {
    _controller.jumpTo(index: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('onGroupChanged Example')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: () => _jumpToGroup(1),
                    child: const Text('Jump to Group 1'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _scrollToGroup(2),
                    child: const Text('Scroll to Group 2'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _jumpToGroup(3),
                    child: const Text('Jump to Group 3'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _jumpToStart,
                    child: const Text('Jump to Start'),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: AdvancedGroupedListView<Map<String, String>, String>(
              elements: elements,
              groupBy: (el) => el['group']!,
              groupSeparatorBuilder: (el) => Container(
                color: Colors.blue[100],
                padding: const EdgeInsets.all(12),
                child: Text(el['group']!,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              itemBuilder: (context, el) => ListTile(title: Text(el['name']!)),
              itemScrollController: _controller,
              onGroupChanged: (String group) {
                developer.log('Current group: $group',
                    name: 'StickyGroupedListView');
              },
            ),
          ),
        ],
      ),
    );
  }
}
