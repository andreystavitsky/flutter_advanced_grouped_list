import 'package:flutter/material.dart';
import 'package:advanced_grouped_list/advanced_grouped_list.dart';

class Element {
  String name;
  String group;

  Element({
    required this.name,
    required this.group,
  });
}

class ToggleStickyHeaderExample extends StatefulWidget {
  const ToggleStickyHeaderExample({super.key});

  @override
  State<ToggleStickyHeaderExample> createState() =>
      _ToggleStickyHeaderExampleState();
}

class _ToggleStickyHeaderExampleState extends State<ToggleStickyHeaderExample> {
  final List<Element> _elements = List.generate(
    100,
    (index) => Element(
      name: 'Item $index',
      group: 'Group ${(index / 10).floor()}',
    ),
  );

  bool _showStickyHeader = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Toggle Sticky Header Example'),
        actions: [
          // Add a button to toggle the sticky header
          IconButton(
            icon: Icon(
                _showStickyHeader ? Icons.visibility_off : Icons.visibility),
            onPressed: () {
              setState(() {
                _showStickyHeader = !_showStickyHeader;
              });
            },
            tooltip:
                _showStickyHeader ? 'Hide sticky header' : 'Show sticky header',
          ),
        ],
      ),
      body: AdvancedGroupedListView<Element, String>(
        elements: _elements,
        groupBy: (element) => element.group,
        groupSeparatorBuilder: (Element element) =>
            _buildGroupSeparator(element),
        itemBuilder: (context, Element element) => _buildItem(element),
        showStickyHeader: _showStickyHeader,
        order: AdvancedGroupedListOrder.ASC,
      ),
    );
  }

  Widget _buildGroupSeparator(Element element) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      color: Colors.blue,
      child: Text(
        element.group,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildItem(Element element) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.all(10),
        title: Text(element.name),
        subtitle: Text('In ${element.group}'),
      ),
    );
  }
}
