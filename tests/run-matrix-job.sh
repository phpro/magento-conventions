#!/usr/bin/env bash
#
# Per-job matrix runner: proves this package is INSTALLABLE into a real Magento 2.4.x
# project and that `grumphp run` is EXECUTABLE against a convention-compliant module.
#
# Required env:
#   MAGENTO_VERSION   e.g. 2.4.7 / 2.4.8 / 2.4.9
#   MAGE_USER         repo.magento.com public key  (GitHub Actions secret)
#   MAGE_PASS         repo.magento.com private key (GitHub Actions secret)
# Provided by GitHub Actions:
#   GITHUB_WORKSPACE  path to this checkout (the package under test)
#
# Any failing step fails the job (set -euo pipefail).

set -euo pipefail

: "${MAGE_USER:?MAGE_USER is not set — required for repo.magento.com auth}"
: "${MAGE_PASS:?MAGE_PASS is not set — required for repo.magento.com auth}"

CHECKOUT="${GITHUB_WORKSPACE:-$(pwd)}"
PROJECT="$(mktemp -d)/magento"

# The checkout path is interpolated raw into the composer path-repo JSON below; reject
# anything that would break that JSON rather than fail later with a cryptic parse error.
case "${CHECKOUT}" in
    *[\ \"\\]*) echo "!!! checkout path contains space/quote/backslash: ${CHECKOUT}" >&2; exit 1 ;;
esac

# Tasks that define the convention and run meaningfully under `grumphp run` (a RunContext).
# git_blacklist / git_branch_name / git_commit_message are pre-commit-only and are silently
# filtered out of `grumphp run`, so they are intentionally NOT listed here.
# 'composer' is excluded too: step 3 adds a path repository to the project, which the
# convention's `composer.no_local_repository: true` rejects. The composer task is covered
# by the lint-package workflow (no path repo there) instead.
# phpunit + clover_coverage are included; the fixture ships a real test + phpunit.xml and
# the CI provides a coverage driver (pcov) so phpunit emits .clover.xml for the clover task.
TASKS="phpcs,phpcsfixer,phplint,phpstan,file_size,phpunit,clover_coverage"

echo ">>> Magento ${MAGENTO_VERSION} | PHP $(php -r 'echo PHP_VERSION;') | checkout ${CHECKOUT}"

# 1. Authenticate against repo.magento.com.
composer config --global http-basic.repo.magento.com "${MAGE_USER}" "${MAGE_PASS}"

# 2. Create the project skeleton without installing, so a single later solve resolves
#    Magento + this package together.
composer create-project --no-install --no-interaction \
    --repository=https://repo.magento.com/ \
    "magento/project-community-edition=${MAGENTO_VERSION}" "${PROJECT}"

cd "${PROJECT}"

# 3. Wire the working-tree checkout as a Composer path repository and relax stability
#    enough for the untagged dev checkout to resolve.
composer config minimum-stability dev
composer config prefer-stable true
composer config repositories.qa-conventions \
    "{\"type\":\"path\",\"url\":\"${CHECKOUT}\",\"options\":{\"symlink\":false}}"
composer config --no-plugins allow-plugins.phpro/grumphp-shim true
composer config --no-plugins allow-plugins.dealerdirect/phpcodesniffer-composer-installer true
# Magento depends on abandoned packages; do not let the audit task fail on that.
composer config audit.abandoned ignore
# Base Magento versions are often flagged by security advisories during the solve. This is
# an install-compatibility test (not a prod audit), so don't block resolution on advisories.
composer config policy.advisories.block false

# 4. GOAL (a): install. Resolves this package against the full Magento dependency tree.
#    Failure here = the package is not installable for this Magento/PHP pair.
composer require --dev --no-interaction --no-progress --ignore-platform-reqs \
    "phpro/magento-conventions:@dev"

# 5. Drop in the consumer grumphp.yml + the compliant fixture module.
cp "${CHECKOUT}/tests/grumphp.fixture.yml" grumphp.yml
mkdir -p app/code
cp -R "${CHECKOUT}/tests/fixture-module/." app/code/

# 5b. Wire PHPUnit so the phpunit + clover_coverage tasks pass: a bootstrap that autoloads
#     the fixture namespace, a version-appropriate phpunit.xml emitting clover, and a code
#     coverage driver. These live at the project root (not under app/code), so they are not
#     linted by the convention.
cat > phpunit.bootstrap.php <<'PHP'
<?php

declare(strict_types=1);

require __DIR__ . '/vendor/autoload.php';

spl_autoload_register(static function (string $class): void {
    $prefix = 'Phpro\\QaFixture\\';
    if (strncmp($class, $prefix, strlen($prefix)) !== 0) {
        return;
    }
    $path = __DIR__ . '/app/code/Phpro/QaFixture/'
        . str_replace('\\', '/', substr($class, strlen($prefix))) . '.php';
    if (is_file($path)) {
        require $path;
    }
});
PHP

PHPUNIT_MAJOR="$(php vendor/bin/phpunit --version | awk '{print $2}' | cut -d. -f1)"
case "${PHPUNIT_MAJOR}" in
    ''|*[!0-9]*) echo "!!! could not parse PHPUnit major version: '${PHPUNIT_MAJOR}'" >&2; exit 1 ;;
esac
if [ "${PHPUNIT_MAJOR}" -ge 10 ]; then
    # PHPUnit 10+: coverage include/exclude moved to a top-level <source> element.
    cat > phpunit.xml <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<phpunit bootstrap="phpunit.bootstrap.php" colors="true">
    <testsuites>
        <testsuite name="unit">
            <directory>app/code/Phpro/QaFixture/Test/Unit</directory>
        </testsuite>
    </testsuites>
    <source>
        <include>
            <directory suffix=".php">app/code/Phpro/QaFixture/Model</directory>
        </include>
    </source>
    <coverage>
        <report>
            <clover outputFile="./.clover.xml"/>
        </report>
    </coverage>
</phpunit>
XML
else
    # PHPUnit 9.x: coverage include lives inside <coverage>.
    cat > phpunit.xml <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<phpunit bootstrap="phpunit.bootstrap.php" colors="true">
    <testsuites>
        <testsuite name="unit">
            <directory>app/code/Phpro/QaFixture/Test/Unit</directory>
        </testsuite>
    </testsuites>
    <coverage>
        <include>
            <directory suffix=".php">app/code/Phpro/QaFixture/Model</directory>
        </include>
        <report>
            <clover outputFile="./.clover.xml"/>
        </report>
    </coverage>
</phpunit>
XML
fi

# Coverage driver: prefer pcov, fall back to xdebug; clover_coverage needs a generated report.
CONF_DIR="$(php -i | sed -n 's/^Scan this dir for additional .ini files => //p' | head -1)"
if php -m | grep -qi pcov; then
    [ -n "${CONF_DIR}" ] && [ "${CONF_DIR}" != "(none)" ] \
        && printf 'pcov.enabled=1\npcov.directory=.\n' > "${CONF_DIR}/zz-coverage.ini"
elif php -m | grep -qi xdebug; then
    export XDEBUG_MODE=coverage
else
    echo "!!! no pcov/xdebug coverage driver available; clover_coverage will fail" >&2
fi

# 6. The convention's root_conventions_dir expects the package at this path; assert it resolved there.
test -f vendor/phpro/magento-conventions/grumphp-convention.yml
test -x vendor/bin/grumphp

# 7. GrumPHP derives its file list from git. Track ONLY the fixture + config so the
#    non-whitelisted tasks (phplint/phpcsfixer/phpstan) lint the fixture, not Magento core.
git init -q -b feature/QA-0
git config user.email ci@phpro.be
git config user.name ci
git add app/code grumphp.yml
git commit -q -m "QA-0 fixture commit"

# 8. Negative pre-check: prove the toolchain actually executes by confirming grumphp FAILS
#    on a known-bad file. A SKIPPED task would otherwise pass silently (false green).
cp "${CHECKOUT}/tests/negative-fixture/BadCode.php" app/code/Phpro/QaFixture/Model/BadCode.php
git add app/code/Phpro/QaFixture/Model/BadCode.php
if php vendor/bin/grumphp run --no-interaction --tasks=phpcsfixer,phpstan; then
    echo "!!! grumphp passed on a known-bad fixture; toolchain not wired correctly" >&2
    exit 1
fi
echo ">>> negative pre-check OK (grumphp failed on bad fixture as expected)"
git rm -q -f app/code/Phpro/QaFixture/Model/BadCode.php
git commit -q -m "QA-0 drop negative fixture"

# 9. GOAL (b): grumphp executable + convention passes on compliant code.
php vendor/bin/grumphp run --no-interaction --tasks="${TASKS}"
echo ">>> PASS: Magento ${MAGENTO_VERSION} on PHP $(php -r 'echo PHP_VERSION;')"
