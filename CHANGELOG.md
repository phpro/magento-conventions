# Changelog
## [0.4.2]
### Added
- Added `treatPhpDocTypesAsCertain: false` to the PHPStan config
- Added `/Test/` to the default `phpcs.ignore_patterns`
- Added `app/bootstrap.php` and `.php-cs-fixer.php` to the default `phpstan.ignore_patterns`

### Changed
- Raised the default `phpstan.level` from 5 to 9

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
