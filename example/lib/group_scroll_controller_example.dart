import 'package:flutter/material.dart';
import 'package:advanced_grouped_list/advanced_grouped_list.dart';
import 'dart:developer' as developer;

List<Element> _elements = List.generate(
  50,
  (index) => Element(
    DateTime(2025, 5, 24 + (index ~/ 5)),
    'Item $index',
    Icons.label,
  ),
);

class GroupScrollControllerApp extends StatefulWidget {
  const GroupScrollControllerApp({Key? key}) : super(key: key);

  @override
  State<GroupScrollControllerApp> createState() =>
      _GroupScrollControllerAppState();
}

class _GroupScrollControllerAppState extends State<GroupScrollControllerApp> {
  final GroupedItemScrollController _itemScrollController =
      GroupedItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();
  int? _topVisibleIndex;
  late final VoidCallback _positionsListener;

  @override
  void initState() {
    super.initState();
    _positionsListener = () {
      final idx = _itemPositionsListener.topItemIndex(minVisibility: 0.9) ?? 0;
      if (_topVisibleIndex != idx) {
        _topVisibleIndex = idx;
        developer.log('Top visible item index: $idx',
            name: 'GroupScrollControllerExample');
        setState(() {});
      }
    };
    _itemPositionsListener.itemPositions.addListener(_positionsListener);
  }

  @override
  void dispose() {
    _itemPositionsListener.itemPositions.removeListener(_positionsListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Scroll Controller'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (String value) {
              switch (value) {
                case 'jumpToFirstGroup':
                  _jumpToFirstGroup();
                  break;
                case 'scrollToMiddleGroup':
                  _scrollToMiddleGroup();
                  break;
                case 'jumpToLastGroup':
                  _jumpToLastGroup();
                  break;
                case 'scrollToGroupByElement':
                  _scrollToGroupByElement();
                  break;
                case 'jumpToGroupDirect':
                  _jumpToGroupDirect();
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'jumpToFirstGroup',
                child: Text('Jump to First Group'),
              ),
              const PopupMenuItem<String>(
                value: 'scrollToMiddleGroup',
                child: Text('Scroll to Middle Group'),
              ),
              const PopupMenuItem<String>(
                value: 'jumpToLastGroup',
                child: Text('Jump to Last Group'),
              ),
              const PopupMenuItem<String>(
                value: 'scrollToGroupByElement',
                child: Text('Scroll to Group by Element'),
              ),
              const PopupMenuItem<String>(
                value: 'jumpToGroupDirect',
                child: Text('Jump to Group Direct'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[200],
            child: Row(
              children: [
                Text(
                  'Top visible item: ${_topVisibleIndex ?? 'N/A'}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _scrollToCurrentGroup,
                  child: const Text('Scroll to Current Group'),
                ),
              ],
            ),
          ),
          Expanded(
            child: AdvancedGroupedListView<Element, DateTime>(
              elements: _elements,
              groupBy: (element) => DateTime(
                element.createdDate.year,
                element.createdDate.month,
                element.createdDate.day,
              ),
              groupSeparatorBuilder: (Element element) => Container(
                height: 50,
                color: Colors.amber,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      '${element.createdDate.day}/${element.createdDate.month}/${element.createdDate.year}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              itemBuilder: (context, Element element) => Card(
                elevation: 8.0,
                margin: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 6.0,
                ),
                child: SizedBox(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 10.0,
                    ),
                    leading: Icon(element.icon),
                    title: Text(element.name),
                    subtitle: Text(
                      element.createdDate.toString(),
                    ),
                  ),
                ),
              ),
              itemScrollController: _itemScrollController,
              itemPositionsListener: _itemPositionsListener,
              separator: const SizedBox(height: 5),
              elementIdentifier: (element) => element.name,
              showStickyHeader: false,
            ),
          ),
        ],
      ),
    );
  }

  void _jumpToFirstGroup() {
    if (_elements.isNotEmpty) {
      _itemScrollController.jumpToGroup(index: 0);
      developer.log('Jumped to first group',
          name: 'GroupScrollControllerExample');
    }
  }

  void _scrollToMiddleGroup() {
    if (_elements.length > 25) {
      _itemScrollController.scrollToGroup(
        index: 25,
        duration: const Duration(seconds: 2),
      );
      developer.log('Scrolled to middle group',
          name: 'GroupScrollControllerExample');
    }
  }

  void _jumpToLastGroup() {
    if (_elements.isNotEmpty) {
      _itemScrollController.jumpToGroup(index: _elements.length - 1);
      developer.log('Jumped to last group',
          name: 'GroupScrollControllerExample');
    }
  }

  void _scrollToGroupByElement() {
    if (_elements.length > 15) {
      _itemScrollController.scrollToGroupByElement(
        identifier: 'Item 15',
        duration: const Duration(seconds: 1),
      );
      developer.log('Scrolled to group containing Item 15',
          name: 'GroupScrollControllerExample');
    }
  }

  void _jumpToGroupDirect() {
    if (_elements.isNotEmpty) {
      // Jump to the group of the 30th element (if exists)
      if (_elements.length > 30) {
        final targetGroup = DateTime(
          _elements[30].createdDate.year,
          _elements[30].createdDate.month,
          _elements[30].createdDate.day,
        );
        _itemScrollController.jumpToGroupDirect<DateTime>(group: targetGroup);
        developer.log('Jumped directly to group $targetGroup',
            name: 'GroupScrollControllerExample');
      }
    }
  }

  void _scrollToCurrentGroup() {
    if (_topVisibleIndex != null) {
      _itemScrollController.scrollToGroup(
        index: _topVisibleIndex!,
        duration: const Duration(milliseconds: 500),
      );
      developer.log('Scrolled to current group',
          name: 'GroupScrollControllerExample');
    }
  }
}

class Element {
  DateTime createdDate;
  String name;
  IconData icon;

  Element(this.createdDate, this.name, this.icon);

  @override
  String toString() {
    return name;
  }
}
