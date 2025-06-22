part of 'advanced_grouped_list_library.dart';

/// Manages header-related operations for the grouped list view
class GroupedListHeaderManager<T, E> {
  /// Caches header dimensions and related data for grouped list performance.
  final GroupedListCacheManager<T, E> cacheManager;
  final GlobalKey _groupHeaderKey = GlobalKey();

  RenderBox? _headerBox;
  RenderBox? _listBox;

  /// Creates a [GroupedListHeaderManager] with the given [cacheManager].
  GroupedListHeaderManager(this.cacheManager);

  /// Returns the [GlobalKey] associated with the group header.
  GlobalKey get groupHeaderKey => _groupHeaderKey;

  /// Calculate the header height for a specific group
  double getHeaderHeightForGroup(
    E group,
    List<T> sortedElements,
    E Function(T) groupByFunction,
    Widget Function(T) groupSeparatorBuilder,
    Axis scrollDirection,
    BuildContext context, {
    bool forceRefresh = false,
    int topElementIndex = 0,
    bool isScrollToInProgress = false,
  }) {
    // Check trusted measurements first
    if (!forceRefresh) {
      final cachedDimension = cacheManager.getCachedHeaderDimension(group);
      if (cachedDimension != null) {
        return cachedDimension;
      }
    }

    // Find first element of this group to create the widget
    T? groupElement;
    for (T element in sortedElements) {
      final elementGroup = groupByFunction(element);
      if (elementGroup == group) {
        groupElement = element;
        break;
      }
    }

    if (groupElement == null) {
      return 0.0;
    }

    // Try to use current sticky header size if available and
    // it's the same group
    if (_headerBox != null && !isScrollToInProgress) {
      try {
        final currentGroup =
            topElementIndex >= 0 && topElementIndex < sortedElements.length
                ? groupByFunction(sortedElements[topElementIndex])
                : null;

        if (currentGroup == group) {
          final currentHeaderSize = scrollDirection == Axis.vertical
              ? _headerBox!.size.height
              : _headerBox!.size.width;

          // Mark this as a trusted measurement
          cacheManager.updateHeaderDimension(group, currentHeaderSize,
              trusted: true);
          return currentHeaderSize;
        }
      } catch (e) {
        // Continue to other methods
      }
    }

    // Use widget estimation
    final Widget separatorWidget = groupSeparatorBuilder(groupElement);
    double estimatedHeight = _estimateWidgetHeight(separatorWidget);

    // If we have other cached headers, use them for better estimation
    final cachedHeights = cacheManager.headerDimensionsCache.values;
    if (cachedHeights.isNotEmpty) {
      final avgHeight =
          cachedHeights.reduce((a, b) => a + b) / cachedHeights.length;
      estimatedHeight = (estimatedHeight + avgHeight) / 2;
    }

    cacheManager.updateHeaderDimension(group, estimatedHeight);
    return estimatedHeight;
  }

  /// Estimate widget height based on widget type and content
  double _estimateWidgetHeight(Widget widget) {
    if (widget is Container) {
      final constraints = widget.constraints;
      final padding = widget.padding;

      double height = 48.0; // Default

      if (constraints != null && constraints.minHeight > 0) {
        height = constraints.minHeight;
      }

      if (padding != null) {
        height += padding.vertical;
      }

      return height;
    } else if (widget is SizedBox) {
      return widget.height ?? 48.0;
    } else if (widget is Padding) {
      return 48.0 + widget.padding.vertical;
    }

    return _analyzeWidgetForHeight(widget);
  }

  /// Recursively analyze widget structure to estimate height
  double _analyzeWidgetForHeight(Widget widget) {
    if (widget is Text) {
      final style = widget.style ?? const TextStyle();
      final fontSize = style.fontSize ?? 14.0;
      return fontSize * 1.5; // Approximate line height with padding
    } else if (widget is RichText) {
      return 20.0; // Approximate rich text height
    }

    return 48.0; // Final fallback - typical header height
  }

  /// Update header box references
  void updateHeaderBox(BuildContext context) {
    _headerBox ??=
        _groupHeaderKey.currentContext?.findRenderObject() as RenderBox?;
    _listBox ??= context.findRenderObject() as RenderBox?;
  }

  /// Get current header dimension ratio
  double? getCurrentHeaderDimension() {
    if (_headerBox == null || _listBox == null) return null;

    final headerHeight = _headerBox!.size.height;
    final listHeight = _listBox!.size.height;

    return listHeight > 0 ? headerHeight / listHeight : 0;
  }

  /// Force refresh of current header dimensions
  void refreshCurrentHeaderDimensions(
    BuildContext context,
    List<T> sortedElements,
    E Function(T) groupByFunction,
    int topElementIndex,
  ) {
    try {
      updateHeaderBox(context);

      if (_headerBox != null) {
        final headerHeight = _headerBox!.size.height;

        // Update cache for current group if we know what it is
        if (topElementIndex >= 0 && topElementIndex < sortedElements.length) {
          final currentGroup = groupByFunction(sortedElements[topElementIndex]);
          if (headerHeight > 0) {
            // Mark this as trusted since it's from actual rendered header
            cacheManager.updateHeaderDimension(currentGroup, headerHeight,
                trusted: true);
          }
        }
      }
    } catch (e) {
      developer.log('Error refreshing current header dimensions: $e',
          name: 'StickyGroupedListView');
    }
  }

  /// Create sticky header widget
  Widget createStickyHeader(
    T element,
    Widget Function(T) groupSeparatorBuilder,
    bool floatingHeader,
    Color? stickyHeaderBackgroundColor,
    BuildContext context,
    E currentGroup,
  ) {
    final Widget headerWidget = Container(
      key: _groupHeaderKey,
      color: floatingHeader ? null : stickyHeaderBackgroundColor,
      width: floatingHeader ? null : MediaQuery.of(context).size.width,
      child: groupSeparatorBuilder(element),
    );

    // Schedule a measurement update after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_headerBox != null) {
        final headerSize = _headerBox!.size.height;
        if (headerSize > 0) {
          cacheManager.updateHeaderDimension(currentGroup, headerSize);
        }
      }
    });

    return headerWidget;
  }

  /// Calculate proper alignment for scrollTo/jumpTo operations
  double calculateAlignmentForElement(
    int elementIndex,
    List<T> sortedElements,
    E Function(T) groupByFunction,
    BuildContext context,
    Axis scrollDirection,
    bool showStickyHeader, {
    double offset = 0.0,
  }) {
    if (!showStickyHeader) {
      return _calculateOffsetAlignment(offset, context, scrollDirection);
    }

    try {
      if (elementIndex >= 0 && elementIndex < sortedElements.length) {
        final group = groupByFunction(sortedElements[elementIndex]);
        final cachedHeight = cacheManager.getCachedHeaderDimension(group);

        if (cachedHeight != null) {
          final RenderBox? listRenderBox =
              context.findRenderObject() as RenderBox?;
          if (listRenderBox != null) {
            final viewportHeight = scrollDirection == Axis.vertical
                ? listRenderBox.size.height
                : listRenderBox.size.width;

            if (viewportHeight > 0) {
              final baseAlignment = cachedHeight / viewportHeight;
              final offsetAlignment = offset / viewportHeight;
              return (baseAlignment + offsetAlignment).clamp(-1.0, 1.0);
            }
          }
        }
      }
    } catch (e) {
      developer.log('Error calculating alignment for element $elementIndex: $e',
          name: 'StickyGroupedListView');
    }

    return _calculateFallbackAlignment(offset, context, scrollDirection);
  }

  /// Calculate offset-only alignment when sticky headers are disabled
  double _calculateOffsetAlignment(
      double offset, BuildContext context, Axis scrollDirection) {
    if (offset == 0.0) return 0.0;

    try {
      final RenderBox? listRenderBox = context.findRenderObject() as RenderBox?;
      if (listRenderBox != null) {
        final viewportHeight = scrollDirection == Axis.vertical
            ? listRenderBox.size.height
            : listRenderBox.size.width;

        if (viewportHeight > 0) {
          return (offset / viewportHeight).clamp(-1.0, 1.0);
        }
      }
    } catch (e) {
      developer.log('Error calculating offset alignment: $e',
          name: 'StickyGroupedListView');
    }

    return 0.0;
  }

  /// Calculate fallback alignment with offset applied
  double _calculateFallbackAlignment(
      double offset, BuildContext context, Axis scrollDirection) {
    double fallbackAlignment = 0.05; // Default 5% of viewport height

    try {
      final cachedHeights = cacheManager.headerDimensionsCache.values;
      if (cachedHeights.isNotEmpty) {
        final averageHeight =
            cachedHeights.reduce((a, b) => a + b) / cachedHeights.length;

        final RenderBox? listRenderBox =
            context.findRenderObject() as RenderBox?;
        if (listRenderBox != null) {
          final viewportHeight = scrollDirection == Axis.vertical
              ? listRenderBox.size.height
              : listRenderBox.size.width;

          if (viewportHeight > 0) {
            final baseAlignment =
                (averageHeight / viewportHeight).clamp(0.0, 0.3);
            final offsetAlignment = offset / viewportHeight;
            fallbackAlignment = baseAlignment + offsetAlignment;
          }
        }
      } else {
        // Apply offset to default alignment
        final RenderBox? listRenderBox =
            context.findRenderObject() as RenderBox?;
        if (listRenderBox != null) {
          final viewportHeight = scrollDirection == Axis.vertical
              ? listRenderBox.size.height
              : listRenderBox.size.width;
          if (viewportHeight > 0) {
            final offsetAlignment = offset / viewportHeight;
            fallbackAlignment = 0.05 + offsetAlignment;
          }
        }
      }
    } catch (e) {
      developer.log('Error in fallback alignment calculation: $e',
          name: 'StickyGroupedListView');
    }

    return fallbackAlignment.clamp(-1.0, 1.0);
  }

  /// Dispose resources
  void dispose() {
    _headerBox = null;
    _listBox = null;
  }
}
