# GitHub Actions

This repo is a config-only GrumPHP convention for Magento 2 projects. The workflows prove
the package stays **installable** and **executable** (GrumPHP runs) across the supported
Magento × PHP matrix, and catch incompatibilities before they reach a real project — without
testing against an actual project checkout.

Workflows live in [`.github/workflows/`](.github/workflows/); the scripts they run live in
[`tests/`](tests/). PHP is provisioned with `shivammathur/setup-php` (any 8.2–8.5, plus the
`pcov` coverage driver), so no custom Docker images are needed.

## Prerequisites

| Secret | Used by | Notes |
| --- | --- | --- |
| `MAGE_USER` | `full-check`, `full-check-all`, `lint-package` | repo.magento.com public key |
| `MAGE_PASS` | same | repo.magento.com private key |

Add them under **Settings → Secrets and variables → Actions**. `compatibility-simulation`
needs no secrets. `lint-package` authenticates only if the secret is present (so fork PRs
still run, falling back to Packagist for the public coding standard).

## Overview

| Workflow | Trigger | Auth | Magento download | Purpose |
| --- | --- | --- | --- | --- |
| `lint-package` | push / PR | optional | no | fast self-lint of this repo |
| `compatibility-simulation` | dispatch / weekly | no | no | simulate which PHP/tool versions resolve |
| `full-check` | dispatch (inputs) | yes | yes (1×) | full install + GrumPHP run for one chosen combo |
| `full-check-all` | dispatch / weekly | yes | yes (6×) | full install + GrumPHP run across all supported pairs |

---

## `lint-package` — self-lint (automatic, every push/PR)

Installs this package's own dependencies and runs the repo-agnostic GrumPHP tasks:

```
composer install --prefer-dist --ignore-platform-reqs --no-interaction
grumphp run --tasks=composer,file_size
```

Only `composer` + `file_size` run: this package ships no `app/code`, so the `Magento2`
phpcs standard and the static-analysis tasks have nothing to lint. Fast signal, not the
compatibility test.

---

## `compatibility-simulation` — version compatibility simulation (auth-free)

Runs [`tests/check-compatibility.sh`](tests/check-compatibility.sh). For each candidate PHP
version it writes a throwaway `composer.json` requiring this package via a local path
repository, pins `config.platform.php`, and runs `composer update --no-install` — the full
dependency solver writes a lockfile, **nothing is installed, no Magento is downloaded, no
project is created**. It prints the version of each QA tool Composer would pick (always the
newest the constraints allow) plus the newest available on Packagist for reference.

`magento/magento-coding-standard` is public on Packagist, so its resolved version is the
Magento-side compatibility signal — and it updates automatically, so new Magento/tool
versions need no code change here.

- Dispatch input `php_versions` (default `8.2 8.3 8.4 8.5`); also runs weekly.
- Exit non-zero if any candidate PHP version cannot resolve.

Run locally:

```bash
bash tests/check-compatibility.sh
CHECK_PHP_VERSIONS="8.4" bash tests/check-compatibility.sh
```

---

## `full-check` — on-demand single combination (full install)

Pick a Magento version and PHP version (workflow inputs) and run the **full** install +
GrumPHP test for that one combination. Runs [`tests/run-matrix-job.sh`](tests/run-matrix-job.sh).

| Input | Default | Meaning |
| --- | --- | --- |
| `magento_version` | `2.4.8` | free text — any version, incl. unreleased (e.g. `2.4.10`) |
| `php_version` | `8.3` | provisioned by setup-php |

**Run from the UI:** Actions → *full-check* → Run workflow → set inputs → Run.

**Run via API / `gh`:**

```bash
gh workflow run full-check.yml -f magento_version=2.4.9 -f php_version=8.4
```

---

## `full-check-all` — full supported matrix (heavy)

Six matrix jobs, each creating a real Magento CE project, installing this package against
the full dependency tree, and running GrumPHP against a compliant fixture module. Manual or
weekly (`fail-fast: false`, so one red cell doesn't cancel the rest).

| Magento | PHP |
| --- | --- |
| 2.4.7 | 8.2, 8.3 |
| 2.4.8 | 8.3, 8.4 |
| 2.4.9 | 8.4, 8.5 |

These are the officially-supported PHP × Magento pairs. To add a new PHP line, add a row to
the `matrix.include` list (and, for single runs, it's already available via `full-check`).

---

## What a matrix job (`run-matrix-job.sh`) actually does

`full-check` and `full-check-all` both run `tests/run-matrix-job.sh`:

1. Authenticate against repo.magento.com (`MAGE_USER` / `MAGE_PASS`).
2. `composer create-project --no-install magento/project-community-edition=$MAGENTO_VERSION`.
3. Wire this checkout as a Composer path repository; ignore advisories + abandoned packages
   so the solve isn't blocked by Magento's known dev-dependency state.
4. **Install proof:** `composer require --dev phpro/magento-conventions:@dev` — resolves
   this package against the full Magento tree. Failure = not installable.
5. Set up PHPUnit (bootstrap, a version-appropriate `phpunit.xml`, a coverage driver) so the
   `phpunit` + `clover_coverage` tasks can run.
6. Commit a compliant fixture module so GrumPHP has files to lint.
7. **Negative pre-check:** confirm GrumPHP *fails* on a deliberately-bad file (guards against
   tasks silently being skipped and reporting a false pass).
8. **Execution proof:** `grumphp run` over the convention's tasks; exit 0 = pass.

### Tasks the matrix runs vs. skips

- **Runs:** `phpcs`, `phpcsfixer`, `phplint`, `phpstan`, `file_size`, `phpunit`,
  `clover_coverage`.
- **Skipped by design:**
  - `composer` — step 3 adds a path repository, which the convention's
    `composer.no_local_repository: true` rejects (covered by `lint-package` instead).
  - `git_blacklist` / `git_branch_name` / `git_commit_message` — pre-commit-only; GrumPHP
    filters them out of `grumphp run`.

## Known upstream caps

Some tools cannot reach their absolute-latest release because an upstream dependency caps
them — not the convention. `compatibility-simulation` surfaces these the moment the upstream
constraint loosens:

- **PHPUnit 13** — blocked on Magento 2.4.9 by Magento's own `phpunit/phpunit ^12.0` pin.
- **php_codesniffer 4** — blocked by `magento/magento-coding-standard` (`^3.10.2`).
