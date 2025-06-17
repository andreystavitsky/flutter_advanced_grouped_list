import 'package:flutter/material.dart';
import 'package:advanced_grouped_list/advanced_grouped_list.dart';
import 'dart:developer' as developer;
import 'dart:async';

List<Element> _elements = List.generate(
  50,
  (index) => Element(
    DateTime(2025, 5, 24 + (index ~/ 5)),
    'Item $index',
    Icons.label,
  ),
);

class ScrollOffsetControllerApp extends StatefulWidget {
  const ScrollOffsetControllerApp({Key? key}) : super(key: key);

  @override
  State<ScrollOffsetControllerApp> createState() =>
      _ScrollOffsetControllerAppState();
}

class _ScrollOffsetControllerAppState extends State<ScrollOffsetControllerApp> {
  final ScrollOffsetController _scrollOffsetController =
      ScrollOffsetController();
  final ScrollOffsetListener _scrollOffsetListener =
      ScrollOffsetListener.create(recordProgrammaticScrolls: true);
  StreamSubscription<double>? _offsetSubscription;
  double _lastScrolledOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _offsetSubscription = _scrollOffsetListener.changes.listen((delta) {
      setState(() {
        _lastScrolledOffset += delta;
      });
      developer.log('Scroll offset delta: $delta, total: $_lastScrolledOffset',
          name: 'ScrollOffsetControllerExample');
    });
  }

  @override
  void dispose() {
    _offsetSubscription?.cancel();
    super.dispose();
  }

  void _scrollToOffset(double offset) {
    double delta = offset;
    // If target is 0, scroll by -_lastScrolledOffset to reach the top
    if (offset == 0.0) {
      delta = -_lastScrolledOffset;
    }
    _scrollOffsetController.animateScroll(
      offset: delta,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
    developer.log('Animated scroll to offset: $delta',
        name: 'ScrollOffsetControllerExample');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ScrollOffsetController Example',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: Scaffold(
        appBar: AppBar(
          leading: Navigator.canPop(context)
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).maybePop(),
                )
              : null,
          title: const Text('ScrollOffsetController Example'),
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
                      onPressed: () => _scrollToOffset(0),
                      child: const Text('Scroll to Top'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () => _scrollToOffset(500),
                      child: const Text('Scroll to Offset 500'),
                    ),
                    const SizedBox(width: 10),
                    Text(
                        'Last offset: ${_lastScrolledOffset.toStringAsFixed(1)}'),
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
                scrollOffsetController: _scrollOffsetController,
                scrollOffsetListener: _scrollOffsetListener,
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
