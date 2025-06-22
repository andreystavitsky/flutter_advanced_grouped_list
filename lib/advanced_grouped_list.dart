/// This library brings support for a list view in which the items can be
/// grouped together in different sections.
///
/// This library is based on the package [scrollable_positioned_list] which
/// brings the ability to programatically scroll through the list.
///
/// * See https://pub.dev/packages/scrollable_positioned_list
///
/// To use this library in your code:
/// ```
/// import 'package:advanced_grouped_list/advanced_grouped_list.dart';
/// ```
library advanced_grouped_list;

import 'package:flutter/widgets.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

export 'src/advanced_grouped_list_order.dart';

export 'src/advanced_grouped_list_library.dart'
    show
        AdvancedGroupedListView,
        GroupedItemScrollController,
        AdvancedGroupedListViewState;

export 'package:scrollable_positioned_list/scrollable_positioned_list.dart'
    show
        ItemPositionsListener,
        ScrollOffsetController,
        ScrollOffsetListener,
        ItemPosition;

part 'src/item_positions_listener_ext.dart';
