<?php

declare(strict_types=1);

namespace Phpro\QaFixture\Model;

use Phpro\QaFixture\Api\GreetingInterface;

final class Greeting implements GreetingInterface
{
    public function greet(string $name): string
    {
        return 'Hello ' . $name;
    }
}
