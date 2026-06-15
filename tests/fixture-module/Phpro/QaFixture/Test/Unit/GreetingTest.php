<?php

declare(strict_types=1);

namespace Phpro\QaFixture\Test\Unit;

use Phpro\QaFixture\Model\Greeting;
use PHPUnit\Framework\TestCase;

class GreetingTest extends TestCase
{
    public function testGreetReturnsGreeting(): void
    {
        static::assertSame('Hello world', (new Greeting())->greet('world'));
    }
}
