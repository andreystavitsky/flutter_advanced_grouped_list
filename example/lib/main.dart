import 'package:flutter/material.dart';
import 'chat_example.dart' as chat_example;
import 'example.dart' as basic_example;
import 'scroll_example.dart' as scroll_example;
import 'item_scroll_controller_example.dart';
import 'scroll_offset_controller_example.dart';
import 'on_group_changed_example.dart' as on_group_changed_example;
import 'toggle_sticky_header_example.dart';
import 'variable_height_example.dart';
import 'group_scroll_controller_example.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sticky Grouped ListView Examples',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: Scaffold(
        appBar: AppBar(title: const Text('Sticky Grouped ListView Examples')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _ExampleTile(
              title: 'Toggle Sticky Header Example',
              builder: (context) => const ToggleStickyHeaderExample(),
            ),
            _ExampleTile(
              title: 'Basic Example',
              builder: (context) => const basic_example.MyApp(),
            ),
            _ExampleTile(
              title: 'Chat Example',
              builder: (context) => const chat_example.MyApp(),
            ),
            _ExampleTile(
              title: 'Scroll Example',
              builder: (context) => scroll_example.MyApp(),
            ),
            _ExampleTile(
              title: 'Item Scroll Controller Example',
              builder: (context) => const ItemScrollControllerApp(),
            ),
            _ExampleTile(
              title: 'Group Scroll Controller Example',
              builder: (context) => const GroupScrollControllerApp(),
            ),
            _ExampleTile(
              title: 'Scroll Offset Controller Example',
              builder: (context) => const ScrollOffsetControllerApp(),
            ),
            _ExampleTile(
              title: 'onGroupChanged Example',
              builder: (context) =>
                  const on_group_changed_example.OnGroupChangedExample(),
            ),
            _ExampleTile(
              title: 'Variable Height Example',
              builder: (context) => const VariableHeightExample(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExampleTile extends StatelessWidget {
  final String title;
  final WidgetBuilder builder;
  const _ExampleTile({required this.title, required this.builder, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: builder),
        ),
        child: Text(title),
      ),
    );
  }
}
