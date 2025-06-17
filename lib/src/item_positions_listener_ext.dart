import 'package:flutter/widgets.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

/// Extension to get the topmost visible item index or ItemPosition from ItemPositionsListener.
extension ItemPositionsListenerExt on ItemPositionsListener {
  /// Returns the index of the topmost visible element (not separator) in the logical elements list, or null if none.
  ///
  /// This always returns the index in the elements list (i.e., [rawIndex] ~/ 2),
  /// or null if no element is visible.
  ///
  /// Either [minVisibility] or [minViewportOccupied] can be specified, but not both.
  /// - [minVisibility]: Minimum fraction of the item that must be visible (0.0 to 1.0) to be considered visible
  /// - [minViewportOccupied]: Minimum fraction of the viewport that the item must occupy (0.0 to 1.0) to be considered visible
  int? topItemIndex({
    bool reverse = false,
    double minVisibility = 0.0,
    Axis scrollDirection = Axis.vertical,
    TextDirection textDirection = TextDirection.ltr,
    double? minViewportOccupied,
  }) {
    assert(
      minViewportOccupied == null || minVisibility == 0.0,
      'Only one of minVisibility or minViewportOccupied can be specified',
    );

    final item = _getTopVisibleElement(
      reverse: reverse,
      minVisibility: minVisibility,
      scrollDirection: scrollDirection,
      textDirection: textDirection,
      minViewportOccupied: minViewportOccupied,
    );
    return item != null ? item.index ~/ 2 : null;
  }

  /// Returns the ItemPosition of the topmost visible element (not separator), or null if none is visible.
  ///
  /// This always returns the ItemPosition for an element (odd index), or null if no element is visible.
  ///
  /// Either [minVisibility] or [minViewportOccupied] can be specified, but not both.
  /// - [minVisibility]: Minimum fraction of the item that must be visible (0.0 to 1.0)
  /// - [minViewportOccupied]: Minimum fraction of the viewport that the item must occupy (0.0 to 1.0)
  ItemPosition? topItem({
    bool reverse = false,
    double minVisibility = 0.0,
    Axis scrollDirection = Axis.vertical,
    TextDirection textDirection = TextDirection.ltr,
    double? minViewportOccupied,
  }) {
    assert(
      minViewportOccupied == null || minVisibility == 0.0,
      'Only one of minVisibility or minViewportOccupied can be specified',
    );

    return _getTopVisibleElement(
      reverse: reverse,
      minVisibility: minVisibility,
      scrollDirection: scrollDirection,
      textDirection: textDirection,
      minViewportOccupied: minViewportOccupied,
    );
  }

  /// Returns the index of the topmost visible separator in the widget list, or null if none.
  ///
  /// This always returns the index in the separators list (i.e., [rawIndex] ~/ 2),
  /// or null if the topmost visible item is not a separator.
  ///
  /// Either [minVisibility] or [minViewportOccupied] can be specified, but not both.
  /// - [minVisibility]: Minimum fraction of the item that must be visible (0.0 to 1.0)
  /// - [minViewportOccupied]: Minimum fraction of the viewport that the item must occupy (0.0 to 1.0)
  int? topSeparatorIndex({
    bool reverse = false,
    double minVisibility = 0.0,
    Axis scrollDirection = Axis.vertical,
    TextDirection textDirection = TextDirection.ltr,
    double? minViewportOccupied,
  }) {
    assert(
      minViewportOccupied == null || minVisibility == 0.0,
      'Only one of minVisibility or minViewportOccupied can be specified',
    );

    final item = _getTopVisibleItem(
      reverse: reverse,
      minVisibility: minVisibility,
      scrollDirection: scrollDirection,
      textDirection: textDirection,
      minViewportOccupied: minViewportOccupied,
    );
    if (item == null) return null;
    // Even indices are separators (0, 2, 4, ...)
    if (item.index % 2 == 0) {
      return item.index ~/ 2;
    }
    return null;
  }

  /// Returns the ItemPosition of the last visible element (not separator), or null if none is visible.
  ///
  /// This always returns the ItemPosition for an element (odd index), or null if no element is visible.
  ///
  /// Either [minVisibility] or [minViewportOccupied] can be specified, but not both.
  /// - [minVisibility]: Minimum fraction of the item that must be visible (0.0 to 1.0) to be considered visible
  /// - [minViewportOccupied]: Minimum fraction of the viewport that the item must occupy (0.0 to 1.0) to be considered visible
  ItemPosition? lastItem({
    bool reverse = false,
    double minVisibility = 0.0,
    Axis scrollDirection = Axis.vertical,
    TextDirection textDirection = TextDirection.ltr,
    double? minViewportOccupied,
  }) {
    assert(
      minViewportOccupied == null || minVisibility == 0.0,
      'Only one of minVisibility or minViewportOccupied can be specified',
    );

    return _getLastVisibleElement(
      reverse: reverse,
      minVisibility: minVisibility,
      scrollDirection: scrollDirection,
      textDirection: textDirection,
      minViewportOccupied: minViewportOccupied,
    );
  }

  /// Returns the index of the last visible element (not separator) in the logical elements list, or null if none.
  ///
  /// This always returns the index in the elements list (i.e., [rawIndex] ~/ 2),
  /// or null if no element is visible.
  ///
  /// Either [minVisibility] or [minViewportOccupied] can be specified, but not both.
  /// - [minVisibility]: Minimum fraction of the item that must be visible (0.0 to 1.0) to be considered visible
  /// - [minViewportOccupied]: Minimum fraction of the viewport that the item must occupy (0.0 to 1.0) to be considered visible
  int? lastItemIndex({
    bool reverse = false,
    double minVisibility = 0.0,
    Axis scrollDirection = Axis.vertical,
    TextDirection textDirection = TextDirection.ltr,
    double? minViewportOccupied,
  }) {
    assert(
      minViewportOccupied == null || minVisibility == 0.0,
      'Only one of minVisibility or minViewportOccupied can be specified',
    );

    final item = _getLastVisibleElement(
      reverse: reverse,
      minVisibility: minVisibility,
      scrollDirection: scrollDirection,
      textDirection: textDirection,
      minViewportOccupied: minViewportOccupied,
    );
    return item != null ? item.index ~/ 2 : null;
  }

  /// Internal implementation for finding the topmost visible element (odd index).
  ItemPosition? _getTopVisibleElement({
    bool reverse = false,
    double minVisibility = 0.0,
    Axis scrollDirection = Axis.vertical,
    TextDirection textDirection = TextDirection.ltr,
    double? minViewportOccupied,
  }) {
    assert(
      minViewportOccupied == null || minVisibility == 0.0,
      'Only one of minVisibility or minViewportOccupied can be specified',
    );

    final positions = itemPositions.value;
    if (positions.isEmpty) return null;
    // Only consider elements (odd indices)
    final elementPositions = positions.where((pos) => pos.index % 2 == 1);
    if (elementPositions.isEmpty) return null;
    // Use the same logic as _getTopVisibleItem for filtering and picking the topmost
    final visible = elementPositions.where((pos) {
      final isTrailingVisible = pos.itemTrailingEdge > 0;
      final isLeadingVisible = pos.itemLeadingEdge < 1;

      // Total item size (may be larger than viewport)
      final itemSize = pos.itemTrailingEdge - pos.itemLeadingEdge;

      // Visible part of the item within viewport boundaries
      final visiblePart = (pos.itemTrailingEdge.clamp(0.0, 1.0) -
              pos.itemLeadingEdge.clamp(0.0, 1.0))
          .clamp(0.0, 1.0);

      // Calculate what fraction of the item is visible
      final percentVisible = itemSize > 0 ? visiblePart / itemSize : 0.0;

      // Calculate what fraction of the viewport the item occupies
      final viewportOccupied = visiblePart;

      final hasSufficientVisibility =
          minVisibility > 0.0 ? percentVisible >= minVisibility : true;

      final hasSufficientViewportOccupation = minViewportOccupied != null
          ? viewportOccupied >= minViewportOccupied
          : true;

      return isTrailingVisible &&
          isLeadingVisible &&
          hasSufficientVisibility &&
          hasSufficientViewportOccupation;
    });
    if (visible.isEmpty) return null;
    bool useTrailingEdge = true;
    if (scrollDirection == Axis.horizontal) {
      final isRtl = textDirection == TextDirection.rtl;
      useTrailingEdge = !((reverse && !isRtl) || (!reverse && isRtl));
    } else {
      useTrailingEdge = !reverse;
    }
    return visible.reduce((candidate, pos) {
      if (useTrailingEdge) {
        if (reverse) {
          // For reverse, pick the one with the largest trailingEdge
          if (pos.itemTrailingEdge > candidate.itemTrailingEdge) return pos;
          if (pos.itemTrailingEdge == candidate.itemTrailingEdge) {
            final candidateVisibility =
                (candidate.itemTrailingEdge.clamp(0.0, 1.0) -
                        candidate.itemLeadingEdge.clamp(0.0, 1.0))
                    .clamp(0.0, 1.0);
            final posVisibility = (pos.itemTrailingEdge.clamp(0.0, 1.0) -
                    pos.itemLeadingEdge.clamp(0.0, 1.0))
                .clamp(0.0, 1.0);
            if (posVisibility > candidateVisibility) return pos;
            if (posVisibility < candidateVisibility) return candidate;
            return pos.index < candidate.index ? pos : candidate;
          }
          return candidate;
        } else {
          // For normal, pick the one with the smallest trailingEdge
          if (pos.itemTrailingEdge < candidate.itemTrailingEdge) return pos;
          if (pos.itemTrailingEdge == candidate.itemTrailingEdge) {
            final candidateVisibility =
                (candidate.itemTrailingEdge.clamp(0.0, 1.0) -
                        candidate.itemLeadingEdge.clamp(0.0, 1.0))
                    .clamp(0.0, 1.0);
            final posVisibility = (pos.itemTrailingEdge.clamp(0.0, 1.0) -
                    pos.itemLeadingEdge.clamp(0.0, 1.0))
                .clamp(0.0, 1.0);
            if (posVisibility > candidateVisibility) return pos;
            if (posVisibility < candidateVisibility) return candidate;
            return pos.index < candidate.index ? pos : candidate;
          }
          return candidate;
        }
      } else {
        if (pos.itemLeadingEdge > candidate.itemLeadingEdge) return pos;
        if (pos.itemLeadingEdge == candidate.itemLeadingEdge) {
          final candidateVisibility =
              (candidate.itemTrailingEdge.clamp(0.0, 1.0) -
                      candidate.itemLeadingEdge.clamp(0.0, 1.0))
                  .clamp(0.0, 1.0);
          final posVisibility = (pos.itemTrailingEdge.clamp(0.0, 1.0) -
                  pos.itemLeadingEdge.clamp(0.0, 1.0))
              .clamp(0.0, 1.0);
          if (posVisibility > candidateVisibility) return pos;
          if (posVisibility < candidateVisibility) return candidate;
          return pos.index < candidate.index ? pos : candidate;
        }
        return candidate;
      }
    });
  }

  /// Internal implementation for finding the last visible element (odd index).
  ItemPosition? _getLastVisibleElement({
    bool reverse = false,
    double minVisibility = 0.0,
    Axis scrollDirection = Axis.vertical,
    TextDirection textDirection = TextDirection.ltr,
    double? minViewportOccupied,
  }) {
    assert(
      minViewportOccupied == null || minVisibility == 0.0,
      'Only one of minVisibility or minViewportOccupied can be specified',
    );

    final positions = itemPositions.value;
    if (positions.isEmpty) return null;
    // Only consider elements (odd indices)
    final elementPositions = positions.where((pos) => pos.index % 2 == 1);
    if (elementPositions.isEmpty) return null;
    // Use the same logic as _getTopVisibleElement for filtering and picking the last visible
    final visible = elementPositions.where((pos) {
      final isTrailingVisible = pos.itemTrailingEdge > 0;
      final isLeadingVisible = pos.itemLeadingEdge < 1;

      // Total item size (may be larger than viewport)
      final itemSize = pos.itemTrailingEdge - pos.itemLeadingEdge;

      // Visible part of the item within viewport boundaries
      final visiblePart = (pos.itemTrailingEdge.clamp(0.0, 1.0) -
              pos.itemLeadingEdge.clamp(0.0, 1.0))
          .clamp(0.0, 1.0);

      // Calculate what fraction of the item is visible
      final percentVisible = itemSize > 0 ? visiblePart / itemSize : 0.0;

      // Calculate what fraction of the viewport the item occupies
      final viewportOccupied = visiblePart;

      final hasSufficientVisibility =
          minVisibility > 0.0 ? percentVisible >= minVisibility : true;

      final hasSufficientViewportOccupation = minViewportOccupied != null
          ? viewportOccupied >= minViewportOccupied
          : true;

      return isTrailingVisible &&
          isLeadingVisible &&
          hasSufficientVisibility &&
          hasSufficientViewportOccupation;
    });
    if (visible.isEmpty) return null;
    bool useMinLeadingEdge = false;
    if (scrollDirection == Axis.horizontal) {
      final isRtl = textDirection == TextDirection.rtl;
      useMinLeadingEdge = (reverse && !isRtl) || (!reverse && isRtl);
    } else {
      useMinLeadingEdge = reverse;
    }
    // For the last visible element, find the maximum or minimum leadingEdge depending on direction
    return visible.reduce((candidate, pos) {
      if (!useMinLeadingEdge) {
        // Normal: maximum leadingEdge is the last one
        if (pos.itemLeadingEdge > candidate.itemLeadingEdge) return pos;
        if (pos.itemLeadingEdge == candidate.itemLeadingEdge) {
          final candidateVisibility =
              (candidate.itemTrailingEdge.clamp(0.0, 1.0) -
                      candidate.itemLeadingEdge.clamp(0.0, 1.0))
                  .clamp(0.0, 1.0);
          final posVisibility = (pos.itemTrailingEdge.clamp(0.0, 1.0) -
                  pos.itemLeadingEdge.clamp(0.0, 1.0))
              .clamp(0.0, 1.0);
          if (posVisibility > candidateVisibility) return pos;
          if (posVisibility < candidateVisibility) return candidate;
          return pos.index > candidate.index ? pos : candidate;
        }
        return candidate;
      } else {
        // Reverse/RTL: minimum leadingEdge is the last one
        if (pos.itemLeadingEdge < candidate.itemLeadingEdge) return pos;
        if (pos.itemLeadingEdge == candidate.itemLeadingEdge) {
          final candidateVisibility =
              (candidate.itemTrailingEdge.clamp(0.0, 1.0) -
                      candidate.itemLeadingEdge.clamp(0.0, 1.0))
                  .clamp(0.0, 1.0);
          final posVisibility = (pos.itemTrailingEdge.clamp(0.0, 1.0) -
                  pos.itemLeadingEdge.clamp(0.0, 1.0))
              .clamp(0.0, 1.0);
          if (posVisibility > candidateVisibility) return pos;
          if (posVisibility < candidateVisibility) return candidate;
          return pos.index < candidate.index ? pos : candidate;
        }
        return candidate;
      }
    });
  }

  /// Internal implementation for both topVisibleItemIndex and topVisibleItem
  ItemPosition? _getTopVisibleItem({
    bool reverse = false,
    double minVisibility = 0.0,
    Axis scrollDirection = Axis.vertical,
    TextDirection textDirection = TextDirection.ltr,
    double? minViewportOccupied,
  }) {
    assert(
      minViewportOccupied == null || minVisibility == 0.0,
      'Only one of minVisibility or minViewportOccupied can be specified',
    );

    final positions = itemPositions.value;
    if (positions.isEmpty) return null;

    // Filter for visible items with enhanced criteria
    final visible = positions.where((pos) {
      // Item must have its trailing edge visible
      final isTrailingVisible = pos.itemTrailingEdge > 0;

      // Item must have its leading edge not past the viewport
      final isLeadingVisible = pos.itemLeadingEdge < 1;

      // Calculate how much of the item is actually visible in the viewport
      final visiblePart = (pos.itemTrailingEdge.clamp(0.0, 1.0) -
              pos.itemLeadingEdge.clamp(0.0, 1.0))
          .clamp(0.0, 1.0);

      // Total item size (may be larger than viewport)
      final itemSize = pos.itemTrailingEdge - pos.itemLeadingEdge;

      // Calculate what fraction of the item is visible
      final percentVisible = itemSize > 0 ? visiblePart / itemSize : 0.0;

      // Calculate what fraction of the viewport the item occupies
      final viewportOccupied = visiblePart;

      // Item must have at least minVisibility of its extent visible
      final hasSufficientVisibility =
          minVisibility > 0.0 ? percentVisible >= minVisibility : true;

      final hasSufficientViewportOccupation = minViewportOccupied != null
          ? viewportOccupied >= minViewportOccupied
          : true;

      return isTrailingVisible &&
          isLeadingVisible &&
          hasSufficientVisibility &&
          hasSufficientViewportOccupation;
    });

    if (visible.isEmpty) return null;

    // Determine which edge to use for comparison based on scroll direction and settings
    bool useTrailingEdge = true;
    if (scrollDirection == Axis.horizontal) {
      // For horizontal lists, adjust based on text direction and reverse
      final isRtl = textDirection == TextDirection.rtl;
      useTrailingEdge = !((reverse && !isRtl) || (!reverse && isRtl));
    } else {
      // For vertical lists, adjust based on reverse only
      useTrailingEdge = !reverse;
    }

    // Find the topmost item based on the appropriate edge
    return visible.reduce((candidate, pos) {
      if (useTrailingEdge) {
        // Use trailing edge (default for top-to-bottom/LTR lists)
        if (pos.itemTrailingEdge < candidate.itemTrailingEdge) return pos;
        // If equal trailing edges, use index as tiebreaker (lower index = higher in list)
        if (pos.itemTrailingEdge == candidate.itemTrailingEdge) {
          // If items have same trailing edge, prefer the one with more visibility
          final candidateVisibility =
              (candidate.itemTrailingEdge.clamp(0.0, 1.0) -
                      candidate.itemLeadingEdge.clamp(0.0, 1.0))
                  .clamp(0.0, 1.0);
          final posVisibility = (pos.itemTrailingEdge.clamp(0.0, 1.0) -
                  pos.itemLeadingEdge.clamp(0.0, 1.0))
              .clamp(0.0, 1.0);

          if (posVisibility > candidateVisibility) return pos;
          if (posVisibility < candidateVisibility) return candidate;

          // If same visibility too, use index as final tiebreaker
          return pos.index < candidate.index ? pos : candidate;
        }
        return candidate;
      } else {
        // Use leading edge (for reversed/RTL lists)
        if (pos.itemLeadingEdge > candidate.itemLeadingEdge) return pos;
        // If equal leading edges, apply similar tiebreaking logic
        if (pos.itemLeadingEdge == candidate.itemLeadingEdge) {
          // If items have same leading edge, prefer the one with more visibility
          final candidateVisibility =
              (candidate.itemTrailingEdge.clamp(0.0, 1.0) -
                      candidate.itemLeadingEdge.clamp(0.0, 1.0))
                  .clamp(0.0, 1.0);
          final posVisibility = (pos.itemTrailingEdge.clamp(0.0, 1.0) -
                  pos.itemLeadingEdge.clamp(0.0, 1.0))
              .clamp(0.0, 1.0);

          if (posVisibility > candidateVisibility) return pos;
          if (posVisibility < candidateVisibility) return candidate;

          // If same visibility too, use index as final tiebreaker
          return pos.index < candidate.index ? pos : candidate;
        }
        return candidate;
      }
    });
  }
}
