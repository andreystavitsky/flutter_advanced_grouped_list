[![pub package](https://img.shields.io/pub/v/advanced_grouped_list.svg)](https://pub.dev/packages/advanced_grouped_list)
[![package publisher](https://img.shields.io/pub/publisher/advanced_grouped_list.svg)](https://pub.dev/packages/advanced_grouped_list)
![build](https://github.com/andreystavitsky/flutter_advanced_grouped_list/actions/workflows/main.yaml/badge.svg??branch=main)

---

**Acknowledgements**

This package is originally based on the excellent work from [Dimibe/sticky_grouped_list](https://github.com/Dimibe/sticky_grouped_list) (which has not been updated for over a year) and also incorporates changes from [th8m0z/sticky_grouped_list](https://github.com/th8m0z/sticky_grouped_list). We would like to express our sincere respect and gratitude to the original authors and contributors of these repositories.

**Key Features and Enhancements Added in This Package:**

- Added `onGroupChanged` callback to `StickyGroupedListView` for tracking group changes during scrolling.
- `groupSeparatorBuilder` is now an optional parameter, allowing for more flexible usage.
- Extended `ItemPositionsListener` with `topItemIndex` and `lastItemIndex` support for advanced scroll tracking.
- Improved performance.
- Variable item and group separator heights now supported.

---

A `ListView` in which list items can be grouped to sections. Based on [scrollable_positioned_list](https://pub.dev/packages/scrollable_positioned_list), which enables programatically scrolling of the list.

<img src="https://raw.githubusercontent.com/andreystavitsky/flutter_advanced_grouped_list/master/assets/new-screenshot-for-readme.png" width="300"> <img src="https://raw.githubusercontent.com/andreystavitsky/flutter_advanced_grouped_list/master/assets/chat.png" width="300">

### Features
* Easy creation of chat-like interfaces. 
* List items can be separated in groups.
* For the groups an individual header can be set.
* Sticky headers with floating option. 
* All fields from `ScrollablePositionedList` available.

## Getting Started

 Add the package to your pubspec.yaml:

 ```yaml
advanced_grouped_list: ^1.0.3
 ```
 
 In your dart file, import the library:

 ```Dart
import 'package:advanced_grouped_list/advanced_grouped_list.dart';
 ``` 
 
 Create a `AdvancedGroupedListView` Widget:
 
 ```Dart
  final GroupedItemScrollController itemScrollController = GroupedItemScrollController();
  final ItemPositionsListener itemPositionsListener = ItemPositionsListener.create();

  AdvancedGroupedListView<dynamic, String>(
    elements: _elements,
    // groupBy is now optional
    // You can omit it if you don't need group headers
    groupBy: (dynamic element) => element['group'],
    // groupSeparatorBuilder is now optional
    // You can omit it if you don't need group headers
    groupSeparatorBuilder: (dynamic element) => Text(element['group']),
    itemBuilder: (context, dynamic element) => Text(element['name']),
    itemComparator: (e1, e2) => e1['name'].compareTo(e2['name']), // optional
    elementIdentifier: (element) => element.name, // optional - see below for usage
    itemScrollController: itemScrollController, // optional
    itemPositionsListener: itemPositionsListener, // optional
    order: AdvancedGroupedListOrder.ASC, // optional
    // New: onGroupChanged callback
    onGroupChanged: (group) {
      // Called when the top visible group changes
      print('Current group: $group');
    },
  );
```

If you are using the `GroupedItemScrollController` you can scroll or jump to an specific position in the list programatically:

1. By using the index, which will scroll to the element at position [index]:
```dart
  itemScrollController.scrollTo(index: 4, duration: Duration(seconds: 2));
  itemScrollController.jumpTo(index: 4);
```

2. By using a pre defined element identifier. The identifier is defined by a `Function` which takes one element and returns a unique identifier of any type.
The methods `scrollToElement` and `jumpToElement` can be used to jump to an element by providing the elements identifier instead of the index: 
```dart
  final GroupedItemScrollController itemScrollController = GroupedItemScrollController();

  AdvancedGroupedListView<dynamic, String>(
    elements: _elements,
    elementIdentifier: (element) => element.name
    itemScrollController: itemScrollController, 
    [...]
  );

  itemScrollController.scrollToElement(identifier: 'item-1', duration: Duration(seconds: 2));
  itemScrollController.jumpToElement(identifier: 'item-2');
```

**Example: Using `topItemIndex` and `lastItemIndex` with `minVisibility`**

```dart
final topIndex = itemPositionsListener.topItemIndex();
final lastIndex = itemPositionsListener.lastItemIndex(minVisibility: 0.5); // consider as visible if at least 50% of the item is visible on the screen
```

### Parameters:
| Name | Description | Required | Default value |
|----|----|----|----|
|`elements`| A list of the data you want to display in the list | required | - |
|`itemBuilder` / `indexedItemBuilder`| Function which returns a Widget which defines the item. `indexedItemBuilder` provides the current index as well. If both are defined `indexedItemBuilder` is preferred| yes, either of them | - |
|`groupBy` |Function which maps an element to its grouped value.  **Now optional** | no | - |
|`groupSeparatorBuilder`| Function which gets an element and returns a Widget which defines the group header separator. **Now optional** | no | - |
|`separator` | A Widget which defines a separator between items inside a group | no | no separator |
|`floatingHeader` | When set to `true` the sticky header will float over the list | no | `false` |
|`stickyHeaderBackgroundColor` | Defines the background color of the sticky header | no | `Color(0xffF7F7F7)` |
|`itemScrollController`| Instead of an `ItemScrollController` a `GroupedItemScrollController` needs to be provided. | no | - |
|`elementIdentifier`| Used by `itemScrollController` and defines the unique identifier for each element. | no | - |
|`order` | Change to `StickyGroupedListOrder.DESC` to reverse the group sorting | no | `StickyGroupedListOrder.ASC` |
|`groupComparator` | Can be used to define a custom sorting for the groups. Otherwise the natural sorting order is used | no | - |
|`itemComparator` | Can be used to define a custom sorting for the elements inside each group. Otherwise the natural sorting order is used | no | - |
|`reverse`| Scrolls in opposite from reading direction (Starting at bottom and scrolling up). Same as in scrollable_positioned_list. | no | false |
|`onGroupChanged`| Callback that is called when the top visible group changes. Receives the group value as a parameter. | no | - |
|`scrollOffsetController`| Controller to programmatically control and listen to the scroll offset of the list. | no | - |
|`scrollOffsetListener`| Listener that receives updates about the current scroll offset. | no | - |
|`itemPositionsListener`| Provides access to the current item positions in the list. Enables advanced scroll tracking, including `topItemIndex` and `lastItemIndex` with optional `minVisibility`. | no | - |

*`GroupedItemScrollController.srollTo()` and `GroupedItemScrollController.jumpTo()` automatically set the `alignment` so that the item is fully visible aligned under the group header. Both methods take `automaticAlignment` as an additional optional parameter which needs to be set to true if `alignment` is specified.*

**Also the fields from `ScrollablePositionedList.builder` can be used.**

## Highlight - Chat Dialog

Easy creation of chat-like dialogs.
Just set the option `reverse` to `true` and the option `order` to `AdvancedGroupedListOrder.DESC`. A full example can be found in the examples.
The list will be scrolled to the end in the initial state and therefore scrolling will be against redeaing direction. 



## Used packages: 
| Package name | Copyright | License |
|----|----|----|
|[scrollable_positioned_list](https://pub.dev/packages/scrollable_positioned_list) | Copyright 2018 the Dart project authors, Inc. All rights reserved | [BSD 3-Clause "New" or "Revised" License](https://github.com/google/flutter.widgets/blob/master/packages/scrollable_positioned_list/LICENSE) |
|[sticky_grouped_list](https://pub.dev/packages/sticky_grouped_list) | Copyright 2022 Dimitrios Begnis. All rights reserved | [BSD 3-Clause "New" or "Revised" License](https://github.com/andreystavitsky/flutter_advanced_grouped_list/blob/master/LICENSE) |
