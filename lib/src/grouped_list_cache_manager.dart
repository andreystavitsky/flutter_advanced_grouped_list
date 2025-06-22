part of 'advanced_grouped_list_library.dart';

/// Manages all caching operations for the grouped list view
class GroupedListCacheManager<T, E> {
  /// Cache for groupBy results to avoid repeated function calls
  final Map<T, E> _groupByCache = <T, E>{};

  /// Index mapping groups to their element indices for O(1) lookup
  final Map<E, List<int>> _groupToIndicesMap = <E, List<int>>{};

  /// Cache for element identifier results
  final Map<T, dynamic> _elementIdentifierCache = <T, dynamic>{};

  /// Cache for header dimensions by group
  final Map<E, double> _headerDimensionsCache = <E, double>{};

  /// Cache for trusted header measurements (from accurate measurements,
  /// not sticky header approximations)
  final Map<E, double> _trustedHeaderMeasurements = <E, double>{};

  /// Flag to track if caches need rebuilding
  bool _cachesNeedRebuild = true;

  // Getters
  /// Returns the cache for groupBy results.
  Map<T, E> get groupByCache => _groupByCache;

  /// Returns the index mapping groups to their element indices.
  Map<E, List<int>> get groupToIndicesMap => _groupToIndicesMap;

  /// Returns the cache for element identifier results.
  Map<T, dynamic> get elementIdentifierCache => _elementIdentifierCache;

  /// Returns the cache for header dimensions by group.
  Map<E, double> get headerDimensionsCache => _headerDimensionsCache;

  /// Returns the cache for trusted header measurements.
  Map<E, double> get trustedHeaderMeasurements => _trustedHeaderMeasurements;

  /// Returns whether caches need rebuilding.
  bool get cachesNeedRebuild => _cachesNeedRebuild;

  /// Cached groupBy function to avoid repeated calls
  E getCachedGroupBy(T element, E Function(T) groupByFunction) {
    if (_groupByCache.containsKey(element)) {
      return _groupByCache[element] as E;
    }
    final result = groupByFunction(element);
    _groupByCache[element] = result;
    return result;
  }

  /// Build group index for fast O(1) group operations
  void buildGroupIndex(
    List<T> sortedElements,
    E Function(T) groupByFunction,
    dynamic Function(T)? elementIdentifier,
  ) {
    if (!_cachesNeedRebuild || sortedElements.isEmpty) return;

    _groupByCache.clear();
    _groupToIndicesMap.clear();
    _elementIdentifierCache.clear();

    for (int i = 0; i < sortedElements.length; i++) {
      final element = sortedElements[i];
      final group = getCachedGroupBy(element, groupByFunction);

      // Build group index
      if (!_groupToIndicesMap.containsKey(group)) {
        _groupToIndicesMap[group] = <int>[];
      }
      _groupToIndicesMap[group]!.add(i);

      // Cache identifier if available
      if (elementIdentifier != null) {
        _elementIdentifierCache[element] = elementIdentifier(element);
      }
    }

    _cachesNeedRebuild = false;
  }

  /// Mark caches as needing rebuild
  void markCachesForRebuild() {
    _cachesNeedRebuild = true;
  }

  /// Clear header dimension caches
  void clearHeaderCaches() {
    _headerDimensionsCache.clear();
    _trustedHeaderMeasurements.clear();
  }

  /// Clear all caches
  void clearAllCaches() {
    _groupByCache.clear();
    _groupToIndicesMap.clear();
    _elementIdentifierCache.clear();
    clearHeaderCaches();
    _cachesNeedRebuild = true;
  }

  /// Update header dimension cache
  ///
  /// [group] The group whose header dimension is being updated.
  /// [dimension] The new dimension value.
  /// [trusted] Whether the measurement is trusted (from accurate measurement).
  void updateHeaderDimension(E group, double dimension,
      {bool trusted = false}) {
    _headerDimensionsCache[group] = dimension;
    if (trusted) {
      _trustedHeaderMeasurements[group] = dimension;
    }
  }

  /// Get cached header dimension for group
  ///
  /// [group] The group whose header dimension is requested.
  /// Returns the cached dimension if available, otherwise null.
  double? getCachedHeaderDimension(E group) {
    // Check trusted measurements first
    if (_trustedHeaderMeasurements.containsKey(group)) {
      return _trustedHeaderMeasurements[group];
    }
    return _headerDimensionsCache[group];
  }

  /// Check if header cache should be updated
  ///
  /// [group] The group whose header dimension is being checked.
  /// [newDimension] The new dimension value to compare.
  /// Returns true if the cache should be updated, false otherwise.
  bool shouldUpdateHeaderCache(E group, double newDimension) {
    // Don't update if we have a trusted measurement
    if (_trustedHeaderMeasurements.containsKey(group)) {
      return false;
    }

    // Update if we don't have this group cached
    if (!_headerDimensionsCache.containsKey(group)) {
      return true;
    }

    // Only update if the difference is significant (more than 2px)
    final cachedDimension = _headerDimensionsCache[group]!;
    final difference = (newDimension - cachedDimension).abs();
    return difference > 2.0;
  }

  /// Dispose and clear all resources
  void dispose() {
    clearAllCaches();
  }
}
