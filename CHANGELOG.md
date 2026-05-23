## [1.0.4] - 23.05.2026

* Fixed `scrollTo`/`jumpTo` alignment for variable-height group headers,
  including target groups that have not been rendered yet.
* Added internal hidden header measurement and trusted header size caching for
  more accurate automatic alignment under sticky headers.
* Replaced the delayed scroll correction timer with a post-frame correction to
  avoid timing heuristics.
* Fixed reverse-mode `jumpTo`/`scrollTo` target index calculation.
* Fixed `topElementIndex` updates when scrolling between items in the same
  group.
* Improved `elementIdentifier` lookup performance by caching identifier-to-index
  mappings.
* Improved cache invalidation when grouping, sorting, separator builders, or
  scroll direction change.
* Updated tests for variable-height headers, reverse scrolling, same-group
  position updates, and identifier lookup caching.

## [1.0.3] - 22.06.2025

* Linter improvements and a bug fix for sticky header size calculation in scrollTo

## [1.0.0] - 20.06.2025

* Initial release
