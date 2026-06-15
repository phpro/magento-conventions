#!/usr/bin/env bash
#
# Simulate — WITHOUT installing anything or touching a real project — whether this
# conventions package resolves on a range of PHP versions, and report which version of
# each QA tool Composer would pick (always the newest allowed by our constraints).
#
# How it works: for each candidate PHP version it writes a throwaway composer.json that
# requires this package via a local path repository, pins `config.platform.php`, and runs
# `composer update --no-install`. That runs the full dependency solver and writes a
# composer.lock, but downloads/installs no code. A non-zero exit = that PHP version cannot
# be satisfied. The resolved `magento/magento-coding-standard` version is the Magento-side
# compatibility signal (it is public on Packagist and tracks Magento releases); it updates
# automatically as new standard releases ship, so new Magento versions need no code change.
#
# No repo.magento.com auth is required: only this package's own dependencies are resolved.
#
# Usage:
#   tests/check-compatibility.sh
#   CHECK_PHP_VERSIONS="8.2 8.3 8.4 8.5 8.6" tests/check-compatibility.sh
#
# Exit code: 0 if every candidate PHP version resolves, 1 if any conflict, 2 on setup error.

set -euo pipefail

CHECKOUT="${GITHUB_WORKSPACE:-$(cd "$(dirname "$0")/.." && pwd)}"
PHP_VERSIONS="${CHECK_PHP_VERSIONS:-8.2 8.3 8.4 8.5}"
QA_TOOLS="phpro/grumphp-shim magento/magento-coding-standard php-cs-fixer/shim phpstan/phpstan phpunit/phpunit squizlabs/php_codesniffer php-parallel-lint/php-parallel-lint"

command -v composer >/dev/null || { echo "composer is required" >&2; exit 2; }
command -v jq >/dev/null || { echo "jq is required" >&2; exit 2; }

# Path is interpolated raw into JSON below; reject anything that would break it.
case "${CHECKOUT}" in
    *[\ \"\\]*) echo "checkout path contains space/quote/backslash: ${CHECKOUT}" >&2; exit 2 ;;
esac

echo "Simulating phpro/magento-conventions resolution (solver only, no install)."
echo "Checkout: ${CHECKOUT}"
echo "PHP versions: ${PHP_VERSIONS}"
echo

fail=0
WORK=""
trap '[ -n "${WORK}" ] && rm -rf "${WORK}" || true' EXIT   # clean the in-flight dir if set -e aborts mid-loop
for PHP in ${PHP_VERSIONS}; do
    WORK="$(mktemp -d)"
    cat > "${WORK}/composer.json" <<JSON
{
    "name": "phpro/compat-probe",
    "require-dev": { "phpro/magento-conventions": "@dev" },
    "repositories": [
        { "type": "path", "url": "${CHECKOUT}", "options": { "symlink": false } }
    ],
    "minimum-stability": "dev",
    "prefer-stable": true,
    "config": {
        "platform": { "php": "${PHP}.99" },
        "allow-plugins": {
            "phpro/grumphp-shim": true,
            "dealerdirect/phpcodesniffer-composer-installer": true
        }
    }
}
JSON

    if composer --working-dir="${WORK}" update --no-install --no-interaction --quiet 2>"${WORK}/err"; then
        echo "=== PHP ${PHP}: OK ==="
        for tool in ${QA_TOOLS}; do
            ver=$(jq -r --arg n "${tool}" \
                '(.packages + .["packages-dev"])[]? | select(.name == $n) | .version' \
                "${WORK}/composer.lock" 2>/dev/null | head -1)
            printf '    %-45s %s\n' "${tool}" "${ver:-not resolved}"
        done
    else
        echo "=== PHP ${PHP}: CONFLICT ==="
        grep -iE "requires|conflict|problem|does not match|your php version" "${WORK}/err" \
            | head -10 | sed 's/^/    /' || cat "${WORK}/err" | sed 's/^/    /'
        fail=1
    fi
    echo
    rm -rf "${WORK}"
done

# Best-effort: newest stable on Packagist for reference. Network failures here are non-fatal.
if command -v curl >/dev/null; then
    echo "Newest stable available on Packagist (for reference):"
    for tool in ${QA_TOOLS}; do
        latest=$(curl -fsSL "https://repo.packagist.org/p2/${tool}.json" 2>/dev/null \
            | jq -r --arg n "${tool}" \
                '[.packages[$n][]?.version | select(test("^v?[0-9]"))] | first // empty' \
            2>/dev/null || true)
        printf '    %-45s %s\n' "${tool}" "${latest:-unknown}"
    done
    echo
fi

if [ "${fail}" -ne 0 ]; then
    echo "RESULT: at least one PHP version cannot be satisfied."
else
    echo "RESULT: all candidate PHP versions resolve."
fi
exit "${fail}"
