part of 'advanced_grouped_list.dart';

/// A groupable list of widgets similar to [ScrollablePositionedList], except
/// that the items can be sectioned into groups.
///
/// See [ScrollablePositionedList]
class AdvancedGroupedListView<T, E> extends StatefulWidget {
  /// Items of which [itemBuilder] or [indexedItemBuilder] produce the list.
  final List<T> elements;

  /// Defines which elements are grouped together.
  ///
  /// Function is called for each element in the list, when equal for two
  /// elements, those two belong to the same group.
  /// If null, all elements are considered in a single group.
  final E Function(T element)? groupBy;

  /// Can be used to define a custom sorting for the groups.
  ///
  /// If not set groups will be sorted with their natural sorting order or their
  /// specific [Comparable] implementation.
  final int Function(E value1, E value2)? groupComparator;

  /// Can be used to define a custom sorting for the elements inside each group.
  ///
  /// If not set elements will be sorted with their natural sorting order or
  /// their specific [Comparable] implementation.
  final int Function(T element1, T element2)? itemComparator;

  /// Called to build group separators for each group.
  /// element is always the first element of the group.
  /// If null, no group separator is shown.
  final Widget Function(T element)? groupSeparatorBuilder;

  /// Called to build children for the list with
  /// 0 <= element < elements.length.
  final Widget Function(BuildContext context, T element)? itemBuilder;

  /// Called to build children for the list with
  /// 0 <= element, index < elements.length
  final Widget Function(BuildContext context, T element, int index)?
      indexedItemBuilder;

  /// Used to clearly identify an element. The returned value can be of any
  /// type but must be unique for each element.
  ///
  /// Used by [GroupedItemScrollController] to scroll and jump to a specific
  /// element.
  final dynamic Function(T element)? elementIdentifier;

  /// Whether the sorting of the list is ascending or descending.
  ///
  /// Defaults to ASC.
  final AdvancedGroupedListOrder order;

  /// Called to build separators for between each item in the list.
  final Widget separator;

  /// Whether the group headers float over the list or occupy their own space.
  final bool floatingHeader;

  /// Background color of the sticky header.
  /// Only used if [floatingHeader] is false.
  final Color stickyHeaderBackgroundColor;

  /// Controller for jumping or scrolling to an item.
  final GroupedItemScrollController? itemScrollController;

  /// Notifier that reports the items laid out in the list after each frame.
  final ItemPositionsListener? itemPositionsListener;

  /// Controller for tracking and controlling scroll
  /// offset (from scrollable_positioned_list).
  final ScrollOffsetController? scrollOffsetController;

  /// Listener for scroll offset changes (from scrollable_positioned_list).
  final ScrollOffsetListener? scrollOffsetListener;

  /// The axis along which the scroll view scrolls.
  ///
  /// Defaults to [Axis.vertical].
  final Axis scrollDirection;

  /// How the scroll view should respond to user input.
  ///
  /// See [ScrollView.physics].
  final ScrollPhysics? physics;

  /// The amount of space by which to inset the children.
  final EdgeInsets? padding;

  /// Whether the view scrolls in the reading direction.
  ///
  /// Defaults to false.
  ///
  /// See [ScrollView.reverse].
  final bool reverse;

  /// Whether the extent of the scroll view in the [scrollDirection] should be
  /// determined by the contents being viewed.
  ///
  ///  Defaults to false.
  ///
  /// See [ScrollView.shrinkWrap].
  final bool shrinkWrap;

  /// Whether to wrap each child in an [AutomaticKeepAlive].
  ///
  /// See [SliverChildBuilderDelegate.addAutomaticKeepAlives].
  final bool addAutomaticKeepAlives;

  /// Whether to wrap each child in a [RepaintBoundary].
  ///
  /// See [SliverChildBuilderDelegate.addRepaintBoundaries].
  final bool addRepaintBoundaries;

  /// Whether to wrap each child in an [IndexedSemantics].
  ///
  /// See [SliverChildBuilderDelegate.addSemanticIndexes].
  final bool addSemanticIndexes;

  /// The minimum cache extent used by the underlying scroll lists.
  /// See [ScrollView.cacheExtent].
  ///
  /// Note that the [ScrollablePositionedList] uses two lists to simulate long
  /// scrolls, so using the [ScrollController.scrollTo] method may result
  /// in builds of widgets that would otherwise already be built in the
  /// cache extent.
  final double? minCacheExtent;

  /// The number of children that will contribute semantic information.
  ///
  /// See [ScrollView.semanticChildCount] for more information.
  final int? semanticChildCount;

  /// Index of an item to initially align within the viewport.
  final int initialScrollIndex;

  /// Determines where the leading edge of the item at [initialScrollIndex]
  /// should be placed.
  final double initialAlignment;

  /// Show sticky header
  final bool showStickyHeader;

  /// Called when the visible group changes
  /// (i.e., when the list crosses a group separator).
  ///
  /// Only works if [groupBy] and [groupSeparatorBuilder] are provided.
  final void Function(E group)? onGroupChanged;

  /// Creates a [AdvancedGroupedListView].
  ///
  /// If [groupBy] and [groupSeparatorBuilder] are not provided,
  /// the widget behaves as a plain ScrollablePositionedList.
  const AdvancedGroupedListView({
    super.key,
    required this.elements,
    this.groupBy,
    this.groupSeparatorBuilder,
    this.groupComparator,
    this.itemBuilder,
    this.indexedItemBuilder,
    this.itemComparator,
    this.elementIdentifier,
    this.order = AdvancedGroupedListOrder.ASC,
    this.separator = const SizedBox.shrink(),
    this.floatingHeader = false,
    this.stickyHeaderBackgroundColor = const Color(0xffF7F7F7),
    this.scrollDirection = Axis.vertical,
    this.itemScrollController,
    this.itemPositionsListener,
    this.scrollOffsetController,
    this.scrollOffsetListener,
    this.physics,
    this.padding,
    this.reverse = false,
    this.addAutomaticKeepAlives = true,
    this.addRepaintBoundaries = true,
    this.addSemanticIndexes = true,
    this.minCacheExtent,
    this.semanticChildCount,
    this.initialAlignment = 0,
    this.initialScrollIndex = 0,
    this.shrinkWrap = false,
    this.showStickyHeader = true,
    this.onGroupChanged,
  })  : assert(itemBuilder != null || indexedItemBuilder != null),
        assert(
            onGroupChanged == null ||
                (groupBy != null && groupSeparatorBuilder != null),
            'onGroupChanged requires both groupBy and '
            'groupSeparatorBuilder to be provided.'),
        assert(
            (groupBy == null && groupSeparatorBuilder == null) ||
                (groupBy != null && groupSeparatorBuilder != null),
            'groupBy and groupSeparatorBuilder must either '
            'both be provided or both be null.');

  @override
  State<StatefulWidget> createState() => AdvancedGroupedListViewState<T, E>();
}
