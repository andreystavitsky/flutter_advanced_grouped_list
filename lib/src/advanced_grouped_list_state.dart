part of 'advanced_grouped_list.dart';

class AdvancedGroupedListViewState<T, E>
    extends State<AdvancedGroupedListView<T, E>> {
  /// Used within [GroupedItemScrollController].
  @protected
  List<T> sortedElements = [];

  /// Used within [GroupedItemScrollController].
  @protected
  double? headerDimension;

  late ItemPositionsListener _listener;
  late GroupedItemScrollController _controller;
  bool Function(int)? _isSeparator;

  // Managers for different aspects of functionality
  late GroupedListCacheManager<T, E> _cacheManager;
  late GroupedListHeaderManager<T, E> _headerManager;
  late GroupedListElementManager<T, E> _elementManager;
  late GroupedListPositionManager<T, E> _positionManager;

  // Getters for controller access
  Map<T, dynamic> get elementIdentifierCache =>
      _cacheManager.elementIdentifierCache;
  bool get isScrollToInProgress => _positionManager.isScrollToInProgress;

  // Setter for scroll controller
  set isScrollToInProgress(bool value) {
    _positionManager.setScrollToInProgress(value);
  }

  // Default groupBy: all elements in one group, safe for any E (throws for non-nullable types)
  E _defaultGroupBy(T element) {
    // If E is nullable, return null as E
    if (null is E) return null as E;
    // Otherwise, throw informative error for any non-nullable E
    throw UnsupportedError(
      'StickyGroupedListView: Cannot use plain list mode with '
      'non-nullable group type E = '
      '$E. Please specify groupBy or use a nullable type for E '
      '(e.g., E = Object?, String?, int?).',
    );
  }

  // Default groupSeparatorBuilder: no separator
  Widget _defaultGroupSeparatorBuilder(T element) => const SizedBox.shrink();

  @override
  void initState() {
    super.initState();

    // Initialize managers
    _cacheManager = GroupedListCacheManager<T, E>();
    _headerManager = GroupedListHeaderManager<T, E>(_cacheManager);
    _elementManager = GroupedListElementManager<T, E>(_cacheManager);
    _positionManager = GroupedListPositionManager<T, E>(
        _cacheManager, _headerManager, _elementManager);

    _controller = widget.itemScrollController ?? GroupedItemScrollController();
    _controller.attachToState(this);
    _listener = widget.itemPositionsListener ?? ItemPositionsListener.create();
    _listener.itemPositions.addListener(_positionListener);
  }

  @override
  void dispose() {
    _listener.itemPositions.removeListener(_positionListener);
    _positionManager.dispose();
    _headerManager.dispose();
    _elementManager.dispose();
    _cacheManager.dispose();
    super.dispose();
  }

  @override
  void deactivate() {
    _controller.detachFromState();
    super.deactivate();
  }

  @override
  void didUpdateWidget(AdvancedGroupedListView<T, E> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.itemScrollController != null &&
        oldWidget.itemScrollController!.isAttached) {
      oldWidget.itemScrollController!.detachFromState();
    }
    if (widget.itemScrollController != null &&
        !widget.itemScrollController!.isAttached) {
      widget.itemScrollController!.attachToState(this);
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupBy = widget.groupBy ?? _defaultGroupBy;
    final groupSeparatorBuilder =
        widget.groupSeparatorBuilder ?? _defaultGroupSeparatorBuilder;

    // Use memoized version and build index only when needed
    final newSortedElements = _elementManager.memoizedSortElements(
      widget.elements,
      widget.order,
      groupBy,
      widget.groupComparator,
      widget.itemComparator,
    );

    if (sortedElements != newSortedElements) {
      sortedElements = newSortedElements;
      _cacheManager.markCachesForRebuild();
    }

    // Build group index for fast lookups - only if we have custom groupBy
    if (widget.groupBy != null) {
      _cacheManager.buildGroupIndex(
          sortedElements, groupBy, widget.elementIdentifier);
    }

    var hiddenIndex = widget.reverse ? sortedElements.length * 2 - 1 : 0;
    _isSeparator = widget.reverse ? (int i) => i.isOdd : (int i) => i.isEven;

    return Stack(
      key: widget.key,
      alignment: Alignment.topCenter,
      children: <Widget>[
        ScrollablePositionedList.builder(
          scrollDirection: widget.scrollDirection,
          itemScrollController: _controller,
          itemPositionsListener: _listener,
          scrollOffsetController: widget.scrollOffsetController,
          scrollOffsetListener: widget.scrollOffsetListener,
          physics: widget.physics,
          initialAlignment: widget.initialAlignment,
          initialScrollIndex: widget.initialScrollIndex * 2,
          minCacheExtent: widget.minCacheExtent,
          semanticChildCount: widget.semanticChildCount,
          padding: widget.padding,
          reverse: widget.reverse,
          itemCount: sortedElements.length * 2,
          addAutomaticKeepAlives: widget.addAutomaticKeepAlives,
          addRepaintBoundaries: widget.addRepaintBoundaries,
          addSemanticIndexes: widget.addSemanticIndexes,
          shrinkWrap: widget.shrinkWrap,
          itemBuilder: (context, index) {
            int actualIndex = index ~/ 2;

            if (index == hiddenIndex) {
              if (widget.showStickyHeader == true) {
                return Opacity(
                  opacity: 0,
                  child: groupSeparatorBuilder(sortedElements[actualIndex]),
                );
              } else {
                return groupSeparatorBuilder(sortedElements[actualIndex]);
              }
            }

            if (_isSeparator!(index)) {
              int prevIndex = actualIndex + (widget.reverse ? 1 : -1);
              if (prevIndex < 0 || prevIndex >= sortedElements.length) {
                return widget.separator;
              }

              // Use cached groupBy results if available, otherwise direct call
              E curr, prev;
              if (widget.groupBy != null &&
                  _cacheManager.groupByCache.isNotEmpty) {
                curr = _cacheManager.getCachedGroupBy(
                    sortedElements[actualIndex], groupBy);
                prev = _cacheManager.getCachedGroupBy(
                    sortedElements[prevIndex], groupBy);
              } else {
                curr = groupBy(sortedElements[actualIndex]);
                prev = groupBy(sortedElements[prevIndex]);
              }

              if (prev != curr) {
                return groupSeparatorBuilder(sortedElements[actualIndex]);
              }
              return widget.separator;
            }
            return _buildItem(context, actualIndex);
          },
        ),
        widget.showStickyHeader
            ? StreamBuilder<int>(
                stream: _positionManager.stream,
                initialData: _positionManager.topElementIndex,
                builder: (_, snapshot) {
                  // Only show sticky header when we have custom groupBy
                  if (widget.groupBy != null &&
                      widget.groupSeparatorBuilder != null) {
                    return _showFixedGroupHeader(
                        snapshot.data!, groupSeparatorBuilder);
                  } else {
                    return SizedBox.shrink();
                  }
                },
              )
            : SizedBox.shrink(),
      ],
    );
  }

  /// Returns the index of the topmost visible element (not separator).
  /// Optimized version with simplified logic.
  int? get topVisibleElementIndex {
    return _positionManager.getTopVisibleElementIndex(
        _listener, sortedElements, _isSeparator, widget.reverse);
  }

  Widget _buildItem(context, int actualIndex) {
    if (actualIndex < 0 || actualIndex >= sortedElements.length) {
      developer.log('actualIndex $actualIndex out of bounds for sortedElements',
          name: 'StickyGroupedListView');
      return const SizedBox.shrink();
    }
    return widget.indexedItemBuilder == null
        ? widget.itemBuilder!(context, sortedElements[actualIndex])
        : widget.indexedItemBuilder!(
            context, sortedElements[actualIndex], actualIndex);
  }

  _positionListener() {
    final groupBy = widget.groupBy ?? _defaultGroupBy;
    headerDimension = _headerManager.getCurrentHeaderDimension();

    _positionManager.positionListener(
      _listener,
      sortedElements,
      groupBy,
      _isSeparator,
      widget.reverse,
      widget.onGroupChanged,
      widget.groupBy != null && widget.groupSeparatorBuilder != null,
      context,
    );
  }

  /// Get the group for a given element index (optimized with cache)
  E getGroupForElementIndex(int elementIndex) {
    final groupBy = widget.groupBy ?? _defaultGroupBy;
    return _elementManager.getGroupForElementIndex(
        elementIndex, sortedElements, groupBy);
  }

  /// Find the index of the first element in the specified group
  int getFirstElementIndexForGroup(E group) {
    final groupBy = widget.groupBy ?? _defaultGroupBy;
    return _elementManager.getFirstElementIndexForGroup(
        group, sortedElements, groupBy);
  }

  /// Find the list index of the group header for the specified group
  int getGroupHeaderIndexForGroup(E group) {
    final groupBy = widget.groupBy ?? _defaultGroupBy;
    return _elementManager.getGroupHeaderIndexForGroup(
        group, sortedElements, groupBy);
  }

  /// Find the list index of the group header for the group that contains
  /// the element at the given index
  int getGroupHeaderIndexForElementIndex(int elementIndex) {
    final groupBy = widget.groupBy ?? _defaultGroupBy;
    return _elementManager.getGroupHeaderIndexForElementIndex(
        elementIndex, sortedElements, groupBy);
  }

  /// Find the list index of the group header for the group that contains
  /// the element with the given identifier
  int getGroupHeaderIndexForGroupByIdentifier(dynamic identifier) {
    final groupBy = widget.groupBy ?? _defaultGroupBy;
    return _elementManager.getGroupHeaderIndexForGroupByIdentifier(
        identifier, sortedElements, groupBy, widget.elementIdentifier);
  }

  /// Find the index of the first element of the group that contains
  /// the element with the given identifier
  int getFirstElementIndexForGroupByIdentifier(dynamic identifier) {
    final groupBy = widget.groupBy ?? _defaultGroupBy;
    return _elementManager.getFirstElementIndexForGroupByIdentifier(
        identifier, sortedElements, groupBy, widget.elementIdentifier);
  }

  /// Check if a group exists in the current elements (optimized O(1))
  bool groupExists(E group) {
    final groupBy = widget.groupBy ?? _defaultGroupBy;
    return _elementManager.groupExists(group, sortedElements, groupBy);
  }

  Widget _showFixedGroupHeader(
      int index, Widget Function(T) groupSeparatorBuilder) {
    if (widget.elements.isNotEmpty && index < sortedElements.length) {
      // Use cached result if available, otherwise direct call
      final groupBy = widget.groupBy ?? _defaultGroupBy;
      final currentGroup =
          widget.groupBy != null && _cacheManager.groupByCache.isNotEmpty
              ? _cacheManager.getCachedGroupBy(sortedElements[index], groupBy)
              : groupBy(sortedElements[index]);

      return _headerManager.createStickyHeader(
        sortedElements[index],
        groupSeparatorBuilder,
        widget.floatingHeader,
        widget.stickyHeaderBackgroundColor,
        context,
        currentGroup,
      );
    }
    return Container();
  }

  /// The purpose of this method is to wrap [widget.elementIdentifier] and
  /// type cast the provided [element] to [T].
  dynamic getIdentifier(dynamic element) {
    return _elementManager.getIdentifier(element, widget.elementIdentifier!);
  }

  /// Calculate the header height for a specific group
  double getHeaderHeightForGroup(E group, {bool forceRefresh = false}) {
    final groupBy = widget.groupBy ?? _defaultGroupBy;
    final groupSeparatorBuilder =
        widget.groupSeparatorBuilder ?? _defaultGroupSeparatorBuilder;

    return _headerManager.getHeaderHeightForGroup(
      group,
      sortedElements,
      groupBy,
      groupSeparatorBuilder,
      widget.scrollDirection,
      context,
      forceRefresh: forceRefresh,
      topElementIndex: _positionManager.topElementIndex,
      isScrollToInProgress: _positionManager.isScrollToInProgress,
    );
  }

  /// Force refresh of current header dimensions
  void refreshCurrentHeaderDimensions() {
    final groupBy = widget.groupBy ?? _defaultGroupBy;
    _headerManager.refreshCurrentHeaderDimensions(
      context,
      sortedElements,
      groupBy,
      _positionManager.topElementIndex,
    );
    headerDimension = _headerManager.getCurrentHeaderDimension();
  }

  /// Calculate proper alignment for scrollTo/jumpTo operations
  double calculateAlignmentForElement(int elementIndex, {double offset = 0.0}) {
    final groupBy = widget.groupBy ?? _defaultGroupBy;
    return _headerManager.calculateAlignmentForElement(
      elementIndex,
      sortedElements,
      groupBy,
      context,
      widget.scrollDirection,
      widget.showStickyHeader,
      offset: offset,
    );
  }
}
