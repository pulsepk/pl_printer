# Changelog

## [2026-10-07] - Image URL validation

### Fixed
- `insertImageData` now rejects image URLs over 512 chars and anything without an `http(s)` scheme before storing them.
