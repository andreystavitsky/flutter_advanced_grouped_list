part of 'advanced_grouped_list_library.dart';

/// Manages element and group operations for the grouped list view
class GroupedListElementManager<T, E> {
  /// The cache manager used for caching group and element data.
  final GroupedListCacheManager<T, E> cacheManager;

  List<T>? _lastElements;
  int? _lastOrderHash;
  List<T>? _lastSortedElements;

  /// Creates a [GroupedListElementManager] with the provided [cacheManager].
  GroupedListElementManager(this.cacheManager);

  /// Get the group for a given element index
  E getGroupForElementIndex(
    int elementIndex,
    List<T> sortedElements,
    E Function(T) groupByFunction,
  ) {
    if (elementIndex >= 0 && elementIndex < sortedElements.length) {
      // Use cache if available, otherwise fallback to direct call
      if (cacheManager.groupByCache.isNotEmpty) {
        return cacheManager.getCachedGroupBy(
            sortedElements[elementIndex], groupByFunction);
      } else {
        return groupByFunction(sortedElements[elementIndex]);
      }
    }
    throw RangeError.index(elementIndex, sortedElements, 'elementIndex');
  }

  /// Find the index of the first element in the specified group
  int getFirstElementIndexForGroup(
      E group, List<T> sortedElements, E Function(T) groupByFunction) {
    // Use optimized index if available
    if (cacheManager.groupToIndicesMap.isNotEmpty) {
      final indices = cacheManager.groupToIndicesMap[group];
      return indices?.isNotEmpty == true ? indices!.first : -1;
    }

    // Fallback to linear search
    for (int i = 0; i < sortedElements.length; i++) {
      if (groupByFunction(sortedElements[i]) == group) {
        return i;
      }
    }
    return -1; // Group not found
  }

  /// Find the list index of the group header for the specified group
  int getGroupHeaderIndexForGroup(
      E group, List<T> sortedElements, E Function(T) groupByFunction) {
    final firstElementIndex =
        getFirstElementIndexForGroup(group, sortedElements, groupByFunction);
    if (firstElementIndex == -1) {
      return -1; // Group not found
    }
    // Group header is at even index: firstElementIndex * 2
    return firstElementIndex * 2;
  }

  /// Find the list index of the group header for the group that contains
  /// the element at the given index
  int getGroupHeaderIndexForElementIndex(
    int elementIndex,
    List<T> sortedElements,
    E Function(T) groupByFunction,
  ) {
    final group =
        getGroupForElementIndex(elementIndex, sortedElements, groupByFunction);
    return getGroupHeaderIndexForGroup(group, sortedElements, groupByFunction);
  }

  /// Find the list index of the group header for the group that contains
  /// the element with the given identifier
  int getGroupHeaderIndexForGroupByIdentifier(
    dynamic identifier,
    List<T> sortedElements,
    E Function(T) groupByFunction,
    dynamic Function(T)? elementIdentifier,
  ) {
    final firstElementIndex = getFirstElementIndexForGroupByIdentifier(
      identifier,
      sortedElements,
      groupByFunction,
      elementIdentifier,
    );
    if (firstElementIndex == -1) {
      return -1; // Element not found
    }
    return firstElementIndex * 2;
  }

  /// Find the index of the first element of the group that contains
  /// the element with the given identifier
  int getFirstElementIndexForGroupByIdentifier(
    dynamic identifier,
    List<T> sortedElements,
    E Function(T) groupByFunction,
    dynamic Function(T)? elementIdentifier,
  ) {
    if (elementIdentifier == null) {
      throw StateError('elementIdentifier must be provided to use this method');
    }

    // Use cached identifier results for faster lookup
    for (int i = 0; i < sortedElements.length; i++) {
      final element = sortedElements[i];
      final cachedId = cacheManager.elementIdentifierCache[element] ??
          elementIdentifier(element);
      if (cachedId == identifier) {
        // Get the group of this element and return first index for that group
        final group = cacheManager.getCachedGroupBy(element, groupByFunction);
        return getFirstElementIndexForGroup(
            group, sortedElements, groupByFunction);
      }
    }
    return -1; // Element not found
  }

  /// Check if a group exists in the current elements (optimized O(1))
  bool groupExists(
      E group, List<T> sortedElements, E Function(T) groupByFunction) {
    // Use optimized index if available
    if (cacheManager.groupToIndicesMap.isNotEmpty) {
      return cacheManager.groupToIndicesMap.containsKey(group);
    }

    // Fallback to linear search
    return sortedElements.any((element) => groupByFunction(element) == group);
  }

  /// Memoized element sorting with caching
  List<T> memoizedSortElements(
    List<T> elements,
    AdvancedGroupedListOrder order,
    E Function(T) groupByFunction,
    int Function(E, E)? groupComparator,
    int Function(T, T)? itemComparator,
  ) {
    // Memoize based on elements and order hash
    final orderHash = Object.hashAll(elements) ^ order.hashCode;

    if (_lastElements == elements &&
        _lastOrderHash == orderHash &&
        _lastSortedElements != null) {
      return _lastSortedElements!;
    }

    // Clear caches only when elements or order actually change
    if (_lastElements != elements || _lastOrderHash != orderHash) {
      cacheManager.clearHeaderCaches();
      cacheManager.markCachesForRebuild();
    }

    final sorted = _sortElements(
      elements,
      order,
      groupByFunction,
      groupComparator,
      itemComparator,
    );

    _lastElements = elements;
    _lastOrderHash = orderHash;
    _lastSortedElements = sorted;
    return sorted;
  }

  /// Sort elements by group and item comparators
  List<T> _sortElements(
    List<T> elements,
    AdvancedGroupedListOrder order,
    E Function(T) groupByFunction,
    int Function(E, E)? groupComparator,
    int Function(T, T)? itemComparator,
  ) {
    List<T> sortedElements = List<T>.from(elements);

    if (sortedElements.isNotEmpty) {
      sortedElements.sort((e1, e2) {
        int? compareResult;

        // Compare groups
        if (groupComparator != null) {
          compareResult =
              groupComparator(groupByFunction(e1), groupByFunction(e2));
        } else if (groupByFunction(e1) is Comparable) {
          compareResult = (groupByFunction(e1) as Comparable)
              .compareTo(groupByFunction(e2) as Comparable);
        }

        // Compare elements inside group
        if (compareResult == null || compareResult == 0) {
          if (itemComparator != null) {
            compareResult = itemComparator(e1, e2);
          } else if (e1 is Comparable) {
            compareResult = e1.compareTo(e2);
          }
        }

        return compareResult ?? 0;
      });
    }

    if (order == AdvancedGroupedListOrder.desc) {
      sortedElements = sortedElements.reversed.toList();
    }

    return sortedElements;
  }

  /// Get element identifier (wrapper for type casting)
  dynamic getIdentifier(
      dynamic element, dynamic Function(T) elementIdentifier) {
    return elementIdentifier(element as T);
  }

  /// Dispose resources
  void dispose() {
    _lastElements = null;
    _lastOrderHash = null;
    _lastSortedElements = null;
  }
}
