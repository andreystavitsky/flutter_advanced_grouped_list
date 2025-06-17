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

class ItemScrollControllerApp extends StatefulWidget {
  const ItemScrollControllerApp({Key? key}) : super(key: key);

  @override
  State<ItemScrollControllerApp> createState() =>
      _ItemScrollControllerAppState();
}

class _ItemScrollControllerAppState extends State<ItemScrollControllerApp> {
  final GroupedItemScrollController _itemScrollController =
      GroupedItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();
  int? _topVisibleIndex;
  int? _lastVisibleIndex;
  late final VoidCallback _positionsListener;

  @override
  void initState() {
    super.initState();
    _positionsListener = () {
      final idx = _itemPositionsListener.topItemIndex(minVisibility: 0.9) ?? 0;
      final lastIdx =
          _itemPositionsListener.lastItemIndex(minVisibility: 0.9) ?? 0;
      bool changed = false;
      if (_topVisibleIndex != idx) {
        _topVisibleIndex = idx;
        developer.log('Top visible item index: $idx',
            name: 'ItemScrollControllerExample');
        changed = true;
      }
      if (_lastVisibleIndex != lastIdx) {
        _lastVisibleIndex = lastIdx;
        developer.log('Last visible item index: $lastIdx',
            name: 'ItemScrollControllerExample');
        changed = true;
      }
      if (changed) setState(() {});
    };
    _itemPositionsListener.itemPositions.addListener(_positionsListener);
  }

  @override
  void dispose() {
    _itemPositionsListener.itemPositions.removeListener(_positionsListener);
    super.dispose();
  }

  void _scrollToIndex(int index) {
    if (_itemScrollController.isAttached) {
      _itemScrollController.scrollTo(
        index: index,
        duration: const Duration(milliseconds: 500),
      );
      developer.log('Scrolled to index: $index',
          name: 'ItemScrollControllerExample');
    } else {
      developer.log('Controller not attached',
          name: 'ItemScrollControllerExample');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ItemScrollController Example',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: Scaffold(
        appBar: AppBar(
          leading: Navigator.canPop(context)
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).maybePop(),
                )
              : null,
          title: const Text('ItemScrollController Example'),
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
                      onPressed: () => _scrollToIndex(0),
                      child: const Text('Scroll to Top'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () => _scrollToIndex(20),
                      child: const Text('Scroll to Index 20'),
                    ),
                    const SizedBox(width: 10),
                    Text(
                        'Top index: ${_topVisibleIndex != null && _elements.isNotEmpty && _topVisibleIndex! < _elements.length ? _topVisibleIndex : "-"}'),
                    const SizedBox(width: 10),
                    Text(
                        'Last index: ${_lastVisibleIndex != null && _elements.isNotEmpty && _lastVisibleIndex! < _elements.length ? _lastVisibleIndex : "-"}'),
                  ],
                ),
              ),
            ),
            Expanded(
              child: AdvancedGroupedListView<Element, DateTime>(
                elements: _elements,
                groupBy: (Element element) => DateTime(
                  element.date.year,
                  element.date.month,
                  element.date.day,
                ),
                groupSeparatorBuilder: _getGroupSeparator,
                itemBuilder: _getItem,
                itemScrollController: _itemScrollController,
                itemPositionsListener: _itemPositionsListener,
                floatingHeader: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getGroupSeparator(Element element) {
    return SizedBox(
      height: 40,
      child: Align(
        alignment: Alignment.center,
        child: Container(
          width: 120,
          decoration: BoxDecoration(
            color: Colors.blue[300],
            border: Border.all(
              color: Colors.blue[300]!,
            ),
            borderRadius: const BorderRadius.all(Radius.circular(20.0)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              '${element.date.day}.${element.date.month}.${element.date.year}',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  Widget _getItem(BuildContext ctx, Element element) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6.0),
      ),
      elevation: 4.0,
      margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        leading: Icon(element.icon),
        title: Text(element.name),
        trailing: Text('${element.date.hour}:00'),
      ),
    );
  }
}

class Element {
  DateTime date;
  String name;
  IconData icon;
  Element(this.date, this.name, this.icon);
}
