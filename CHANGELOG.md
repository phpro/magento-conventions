# Changelog
## [Unreleased]
### Added
- GitHub Actions: `compatibility-simulation` (auth-free resolution simulation), `full-check`
  (single Magento × PHP combo) and `full-check-all` (supported matrix), plus a `lint-package`
  workflow and a `tests/` harness (compatibility script + Magento install/GrumPHP runner +
  fixture module). See `GITHUB_ACTIONS.md`.

### Changed
- Allowed PHPUnit `^12` for Magento 2.4.9 compatibility.
- Excluded `Magento2.PHP.FinalImplementation` so `final` classes are permitted.

### Fixed
- `git_blacklist` keywords: unescaped the remaining parentheses (`exit(`, `phpinfo(`,
  `print_r(`, `var_dump(`) so `git grep` (POSIX basic regex) no longer fails with
  "Unmatched \(".

## [0.4.1]
### Fixed
- Fixed php-cs-fixer config to only search in existing directories

## [0.4.0]
### Added
- Updated php-cs-fixer finder directories to use both `./app/code` and `./src`

## [0.3.0]
### Added
- Added ParallelConfig to php-cs-fixer

## [0.2.0]
### Added
- Fixed some dependencies

## [0.1.0]
### Added
- Added GrumPHP conventions used on Magento projects 
