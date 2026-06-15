<?php

// Intentionally NON-compliant fixture used by tests/run-matrix-job.sh to prove the
// toolchain actually runs: it must make `grumphp run` FAIL. It omits the required
// declare(strict_types=1) (phpcsfixer) and returns a string from an int method (phpstan).

namespace Phpro\QaFixture\Model;

class BadCode
{
    public function run(): int
    {
        return 'not an int';
    }
}
