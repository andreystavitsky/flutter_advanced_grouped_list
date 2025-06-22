part of 'advanced_grouped_list_library.dart';

/// Controller to jump or scroll to a particular element in the list.
///
/// See [ItemScrollController].
class GroupedItemScrollController extends ItemScrollController {
  AdvancedGroupedListViewState? _stickyGroupedListViewState;

  /// Whether any [AdvancedGroupedListView] objects are attached to this object.
  ///
  /// If `false`, then [jumpTo] and [scrollTo] must not be called.
  @override
  bool get isAttached => _stickyGroupedListViewState != null;

  /// Jumps to the element at [index]. The element will be placed under the
  /// group header.
  /// To set a custom [alignment] set [automaticAlignment] to false.
  /// The [offset] parameter allows fine-tuning the scroll position in pixels.
  /// Negative values move the element up, positive values move it down.
  ///
  /// See [ItemScrollController.jumpTo]
  @override
  void jumpTo({
    required int index,
    double alignment = 0,
    bool automaticAlignment = true,
    double offset = 0.0,
  }) {
    if (automaticAlignment) {
      // For jumpTo, force refresh of header dimensions
      // cache to get accurate measurements
      try {
        final group =
            _stickyGroupedListViewState!.getGroupForElementIndex(index);

        // Force re-measurement of the header for target group
        _stickyGroupedListViewState!
            .getHeaderHeightForGroup(group, forceRefresh: true);

        // Also refresh the current header dimensions if available
        _stickyGroupedListViewState!.refreshCurrentHeaderDimensions();
      } catch (e) {
        developer.log('Error refreshing header cache for jumpTo: $e',
            name: 'StickyGroupedListView');
      }

      alignment = _stickyGroupedListViewState!
          .calculateAlignmentForElement(index, offset: offset);
    }
    super.jumpTo(index: index * 2 + 1, alignment: alignment);

    // Schedule more aggressive corrections for jumpTo
    if (automaticAlignment) {
      _scheduleScrollCorrection(index, alignment, isJump: true, offset: offset);
    }
  }

  /// Scrolls to the element at [index]. The element will be placed under the
  /// group header.
  /// To set a custom [alignment] set [automaticAlignment] to false.
  /// The [offset] parameter allows fine-tuning the scroll position in pixels.
  /// Negative values move the element up, positive values move it down.
  ///
  /// See [ItemScrollController.scrollTo]
  @override
  Future<void> scrollTo({
    required int index,
    required Duration duration,
    double alignment = 0,
    bool automaticAlignment = true,
    Curve curve = Curves.linear,
    List<double> opacityAnimationWeights = const [40, 20, 40],
    double offset = 0.0,
  }) async {
    // Mark that scrollTo is in progress to prevent inaccurate cache updates
    _stickyGroupedListViewState!.isScrollToInProgress = true;

    try {
      if (automaticAlignment) {
        // Force measurement of header for target group
        // before calculating alignment
        try {
          final group =
              _stickyGroupedListViewState!.getGroupForElementIndex(index);

          // Force measurement of the header for target group to ensure
          // accurate alignment calculation on first scrollTo
          _stickyGroupedListViewState!
              .getHeaderHeightForGroup(group, forceRefresh: true);
        } catch (e) {
          developer.log('Error pre-measuring header for scrollTo: $e',
              name: 'StickyGroupedListView');
        }

        alignment = _stickyGroupedListViewState!
            .calculateAlignmentForElement(index, offset: offset);
      }

      await super.scrollTo(
        index: index * 2 + 1,
        alignment: alignment,
        duration: duration,
        curve: curve,
        opacityAnimationWeights: opacityAnimationWeights,
      );

      // Schedule a correction for the next frame to fix any measurement errors
      if (automaticAlignment) {
        _scheduleScrollCorrection(index, alignment,
            isJump: false, curve: curve, offset: offset);
      }
    } finally {
      // Mark scrollTo as completed after a delay to allow for settling
      await Future.delayed(const Duration(milliseconds: 100));
      if (_stickyGroupedListViewState != null) {
        _stickyGroupedListViewState!.isScrollToInProgress = false;
      }
    }
  }

  /// Schedule a scroll correction to fix measurement errors from
  /// the first scroll.
  void _scheduleScrollCorrection(
    int index,
    double initialAlignment, {
    required bool isJump,
    Curve? curve,
    double offset = 0.0,
  }) {
    // First correction after the next frame

    Future.delayed(
      const Duration(milliseconds: 80),
      () {
        if (!_stickyGroupedListViewState!.mounted) return;
        _performScrollCorrection(
          index,
          initialAlignment,
          isJump: isJump,
          duration: const Duration(milliseconds: 30),
          curve: curve,
          offset: offset,
        );
      },
    );
  }

  void _performScrollCorrection(
    int index,
    double initialAlignment, {
    required bool isJump,
    Duration? duration,
    Curve? curve,
    double offset = 0.0,
  }) {
    try {
      // Recalculate alignment with offset for more accurate correction
      double correctedAlignment = initialAlignment;
      if (offset != 0.0) {
        correctedAlignment = _stickyGroupedListViewState!
            .calculateAlignmentForElement(index, offset: offset);
      }

      if (isJump) {
        super.jumpTo(index: index * 2 + 1, alignment: correctedAlignment);
      } else if (duration != null) {
        super.scrollTo(
          index: index * 2 + 1,
          alignment: correctedAlignment,
          duration: duration,
          curve: curve ?? Curves.easeOut,
        );
      }
      // }
    } catch (e) {
      developer.log('Error in scroll correction: $e',
          name: 'StickyGroupedListView');
    }
  }

  /// Jumps to the element with the given [identifier].
  ///
  /// The element will be placed under the group header.
  /// To set a custom [alignment],
  /// set [automaticAlignment] to false. The [offset] parameter
  /// allows fine-tuning
  /// the scroll position in pixels. Negative values move the element up,
  /// positive values move it down.
  void jumpToElement({
    required dynamic identifier,
    double alignment = 0,
    bool automaticAlignment = true,
    double offset = 0.0,
  }) {
    return jumpTo(
      index: _findIndexByIdentifier(identifier),
      alignment: alignment,
      automaticAlignment: automaticAlignment,
      offset: offset,
    );
  }

  /// Scrolls to the element with the given [identifier].
  ///
  /// The element will be placed under the group header.
  /// To set a custom [alignment],
  /// set [automaticAlignment] to false. The [offset] parameter allows
  /// fine-tuning
  /// the scroll position in pixels. Negative values move the element up,
  /// positive values move it down.
  Future<void> scrollToElement({
    required dynamic identifier,
    required Duration duration,
    double alignment = 0,
    bool automaticAlignment = true,
    Curve curve = Curves.linear,
    List<double> opacityAnimationWeights = const [40, 20, 40],
    double offset = 0.0,
  }) {
    return scrollTo(
      index: _findIndexByIdentifier(identifier),
      duration: duration,
      alignment: alignment,
      automaticAlignment: automaticAlignment,
      curve: curve,
      opacityAnimationWeights: opacityAnimationWeights,
      offset: offset,
    );
  }

  /// Finds the index of the element with the given [identifier].
  ///
  /// Returns the index if found, otherwise -1.
  int _findIndexByIdentifier(dynamic identifier) {
    final elements = _stickyGroupedListViewState!.sortedElements;

    // Use cached identifier results if available
    for (int i = 0; i < elements.length; i++) {
      final element = elements[i];
      final cachedId =
          _stickyGroupedListViewState!.elementIdentifierCache[element];

      if (cachedId != null) {
        if (cachedId == identifier) {
          return i;
        }
      } else {
        // Fallback to direct call if not cached
        final directId = _stickyGroupedListViewState!.getIdentifier(element);
        if (directId == identifier) {
          return i;
        }
      }
    }
    return -1;
  }

  /// Attaches this controller to the given [AdvancedGroupedListViewState].
  void attachToState(AdvancedGroupedListViewState stickyGroupedListViewState) {
    assert(_stickyGroupedListViewState == null);
    _stickyGroupedListViewState = stickyGroupedListViewState;
  }

  /// Detaches this controller from its [AdvancedGroupedListViewState].
  void detachFromState() {
    _stickyGroupedListViewState = null;
  }

  /// Jumps to the group header of the group that contains
  /// the element at [index].
  /// The group header will be placed according to the [alignment].
  void jumpToGroup({
    required int index,
    double alignment = 0,
  }) {
    final groupHeaderIndex =
        _stickyGroupedListViewState!.getGroupHeaderIndexForElementIndex(index);

    if (groupHeaderIndex == -1) {
      throw StateError('Group not found for element at index $index');
    }

    // Jump directly to the group header using the raw list index
    super.jumpTo(
      index: groupHeaderIndex,
      alignment: alignment,
    );
  }

  /// Scrolls to the group header of the group that contains
  /// the element at [index].
  /// The group header will be placed according to the [alignment].
  Future<void> scrollToGroup({
    required int index,
    required Duration duration,
    double alignment = 0,
    Curve curve = Curves.linear,
    List<double> opacityAnimationWeights = const [40, 20, 40],
  }) async {
    final groupHeaderIndex =
        _stickyGroupedListViewState!.getGroupHeaderIndexForElementIndex(index);

    if (groupHeaderIndex == -1) {
      throw StateError('Group not found for element at index $index');
    }

    // Scroll directly to the group header using the raw list index
    return super.scrollTo(
      index: groupHeaderIndex,
      duration: duration,
      alignment: alignment,
      curve: curve,
      opacityAnimationWeights: opacityAnimationWeights,
    );
  }

  /// Jumps to the group header of the group that contains
  /// the element with the given [identifier].
  /// The group header will be placed according to the [alignment].
  void jumpToGroupByElement({
    required dynamic identifier,
    double alignment = 0,
  }) {
    final groupHeaderIndex = _stickyGroupedListViewState!
        .getGroupHeaderIndexForGroupByIdentifier(identifier);

    if (groupHeaderIndex == -1) {
      throw StateError('Element with identifier $identifier not found');
    }

    // Jump directly to the group header using the raw list index
    super.jumpTo(
      index: groupHeaderIndex,
      alignment: alignment,
    );
  }

  /// Scrolls to the group header of the group that contains
  /// the element with the given [identifier].
  /// The group header will be placed according to the [alignment].
  /// To set a custom [alignment] set [automaticAlignment] to false.
  Future<void> scrollToGroupByElement({
    required dynamic identifier,
    required Duration duration,
    double alignment = 0,
    bool automaticAlignment = true,
    Curve curve = Curves.linear,
    List<double> opacityAnimationWeights = const [40, 20, 40],
  }) async {
    final groupHeaderIndex = _stickyGroupedListViewState!
        .getGroupHeaderIndexForGroupByIdentifier(identifier);

    if (groupHeaderIndex == -1) {
      throw StateError('Element with identifier $identifier not found');
    }

    // Scroll directly to the group header using the raw list index
    return super.scrollTo(
      index: groupHeaderIndex,
      duration: duration,
      alignment: alignment,
      curve: curve,
      opacityAnimationWeights: opacityAnimationWeights,
    );
  }

  /// Jumps directly to the group header of the specified [group].
  /// The group header will be placed according to the [alignment].
  void jumpToGroupDirect<E>({
    required E group,
    double alignment = 0,
  }) {
    if (!_stickyGroupedListViewState!.groupExists(group)) {
      throw StateError('Group $group does not exist');
    }

    final groupHeaderIndex =
        _stickyGroupedListViewState!.getGroupHeaderIndexForGroup(group);

    if (groupHeaderIndex == -1) {
      throw StateError('Group $group not found');
    }

    // Jump directly to the group header using the raw list index
    super.jumpTo(
      index: groupHeaderIndex,
      alignment: alignment,
    );
  }

  /// Scrolls directly to the group header of the specified [group].
  /// The group header will be placed according to the [alignment].
  Future<void> scrollToGroupDirect<E>({
    required E group,
    required Duration duration,
    double alignment = 0,
    Curve curve = Curves.linear,
    List<double> opacityAnimationWeights = const [40, 20, 40],
  }) async {
    if (!_stickyGroupedListViewState!.groupExists(group)) {
      throw StateError('Group $group does not exist');
    }

    final groupHeaderIndex =
        _stickyGroupedListViewState!.getGroupHeaderIndexForGroup(group);

    if (groupHeaderIndex == -1) {
      throw StateError('Group $group not found');
    }

    // Scroll directly to the group header using the raw list index
    return super.scrollTo(
      index: groupHeaderIndex,
      duration: duration,
      alignment: alignment,
      curve: curve,
      opacityAnimationWeights: opacityAnimationWeights,
    );
  }
}
