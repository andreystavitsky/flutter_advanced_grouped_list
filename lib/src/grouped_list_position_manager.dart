part of 'advanced_grouped_list_library.dart';

/// Manages position and scroll operations for the grouped list view
class GroupedListPositionManager<T, E> {
  /// The cache manager for grouped list data
  final GroupedListCacheManager<T, E> cacheManager;

  /// The header manager for grouped list headers
  final GroupedListHeaderManager<T, E> headerManager;

  /// The element manager for grouped list elements
  final GroupedListElementManager<T, E> elementManager;

  final StreamController<int> _streamController =
      StreamController<int>.broadcast();
  int _topElementIndex = 0;

  /// Tracks when scrollTo operations are in progress to avoid
  /// caching inaccurate measurements
  bool isScrollToInProgress = false;

  /// Creates a [GroupedListPositionManager] with the required managers.
  GroupedListPositionManager(
      this.cacheManager, this.headerManager, this.elementManager);

  /// A stream that emits the index of the top element when it changes.
  Stream<int> get stream => _streamController.stream;

  /// The index of the topmost visible element.
  int get topElementIndex => _topElementIndex;

  /// Position listener for tracking scroll position.
  ///
  /// [listener] is the item positions listener.
  /// [sortedElements] is the list of sorted elements.
  /// [groupByFunction] is the function to group elements.
  /// [isSeparator] is an optional function to check if an index is a separator.
  /// [reverse] indicates if the list is reversed.
  /// [onGroupChanged] is an optional callback for group changes.
  /// [hasCustomGroupBy] indicates if a custom groupBy is used.
  /// [context] is the build context.
  void positionListener(
    ItemPositionsListener listener,
    List<T> sortedElements,
    E Function(T) groupByFunction,
    bool Function(int)? isSeparator,
    bool reverse,
    void Function(E)? onGroupChanged,
    bool hasCustomGroupBy,
    BuildContext context,
  ) {
    headerManager.updateHeaderBox(context);
    final headerDimension = headerManager.getCurrentHeaderDimension();

    final group = listener.itemPositions.value;

    ItemPosition reducePositions(ItemPosition pos, ItemPosition current) {
      if (reverse) {
        return current.itemTrailingEdge > pos.itemTrailingEdge ? current : pos;
      }
      return current.itemTrailingEdge < pos.itemTrailingEdge ? current : pos;
    }

    if (group.isNotEmpty) {
      final ItemPosition currentItem = group.reduce(reducePositions);
      final int index = currentItem.index ~/ 2;

      if (_topElementIndex != index) {
        if (index < 0 || index >= sortedElements.length) {
          developer.log('index $index out of bounds for sortedElements',
              name: 'StickyGroupedListView');
          return;
        }

        // Use cached groupBy results if available, otherwise fallback
        // to direct call
        final E curr = hasCustomGroupBy && cacheManager.groupByCache.isNotEmpty
            ? cacheManager.getCachedGroupBy(
                sortedElements[index], groupByFunction)
            : groupByFunction(sortedElements[index]);

        final E prev = index >= 0 &&
                _topElementIndex >= 0 &&
                _topElementIndex < sortedElements.length
            ? (hasCustomGroupBy && cacheManager.groupByCache.isNotEmpty
                ? cacheManager.getCachedGroupBy(
                    sortedElements[_topElementIndex], groupByFunction)
                : groupByFunction(sortedElements[_topElementIndex]))
            : curr; // fallback to curr if bounds check fails

        // Cache the header size for the current group when it becomes visible
        _updateHeaderCache(curr, headerDimension);

        if (prev != curr) {
          _topElementIndex = index;
          _streamController.add(_topElementIndex);

          // Only call onGroupChanged if callback is provided and
          // we have custom groupBy
          if (onGroupChanged != null && hasCustomGroupBy) {
            onGroupChanged(curr);
          }
        }
      }
    }
  }

  /// Update header cache based on current measurements.
  ///
  /// [currentGroup] is the current group key.
  /// [headerDimension] is the measured header dimension.
  void _updateHeaderCache(E currentGroup, double? headerDimension) {
    if (headerDimension != null &&
        headerDimension > 0 &&
        !isScrollToInProgress) {
      // Check if we should update the cache
      if (cacheManager.shouldUpdateHeaderCache(currentGroup, headerDimension)) {
        cacheManager.updateHeaderDimension(currentGroup, headerDimension);
      }
    }
  }

  /// Returns the index of the topmost visible element (not separator).
  ///
  /// [listener] is the item positions listener.
  /// [sortedElements] is the list of sorted elements.
  /// [isSeparator] is an optional function to check if an index is a separator.
  /// [reverse] indicates if the list is reversed.
  int? getTopVisibleElementIndex(
    ItemPositionsListener listener,
    List<T> sortedElements,
    bool Function(int)? isSeparator,
    bool reverse,
  ) {
    final positions = listener.itemPositions.value;
    if (positions.isEmpty) return null;

    // Filter for visible items that are actually visible on screen
    final visible = positions
        .where((pos) => pos.itemTrailingEdge > 0 && pos.itemLeadingEdge < 1);

    if (visible.isEmpty) return null;

    // Find the topmost item based on reverse setting
    final topItem = reverse
        ? visible.reduce((max, pos) =>
            pos.itemTrailingEdge > max.itemTrailingEdge ? pos : max)
        : visible.reduce((min, pos) =>
            pos.itemTrailingEdge < min.itemTrailingEdge ? pos : min);

    // Convert raw index to element index
    final rawIndex = topItem.index;

    // Handle separator vs element index
    if (isSeparator?.call(rawIndex) == true) {
      // If it's a separator, get the associated element
      final elementRawIndex = reverse
          ? (rawIndex > 0 ? rawIndex - 1 : 0)
          : (rawIndex + 1 < sortedElements.length * 2
              ? rawIndex + 1
              : rawIndex - 1);

      final elementIndex = elementRawIndex ~/ 2;
      return (elementIndex >= 0 && elementIndex < sortedElements.length)
          ? elementIndex
          : null;
    } else {
      // It's an element, convert to element index
      final elementIndex = rawIndex ~/ 2;
      return (elementIndex >= 0 && elementIndex < sortedElements.length)
          ? elementIndex
          : null;
    }
  }

  /// Set scroll operation state.
  ///
  /// [inProgress] indicates if a scroll operation is in progress.
  void setScrollToInProgress(bool inProgress) {
    isScrollToInProgress = inProgress;
  }

  /// Update top element index.
  ///
  /// [index] is the new top element index.
  void updateTopElementIndex(int index) {
    if (_topElementIndex != index) {
      _topElementIndex = index;
      _streamController.add(_topElementIndex);
    }
  }

  /// Dispose resources used by this manager.
  void dispose() {
    _streamController.close();
  }
}
