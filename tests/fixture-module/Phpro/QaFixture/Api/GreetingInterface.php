<?php

declare(strict_types=1);

namespace Phpro\QaFixture\Api;

interface GreetingInterface
{
    public function greet(string $name): string;
}
