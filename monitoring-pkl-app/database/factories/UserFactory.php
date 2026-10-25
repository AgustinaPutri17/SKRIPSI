<?php

namespace Database\Factories;

use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

/**
 * @extends Factory<User>
 */
class UserFactory extends Factory
{
    protected static ?string $password;

    public function definition(): array
    {
        return [
            'name' => fake()->name(),
            'username' => fake()->unique()->userName(),
            'email' => fake()->unique()->safeEmail(),
            'email_verified_at' => now(),
            'password' => static::$password ??= Hash::make('password'),
            'role' => 'student',
            'is_active' => true,
            'remember_token' => Str::random(10),
        ];
    }

    public function admin(): static
    {
        return $this->state(fn(array $attrs) => ['role' => 'admin']);
    }

    public function teacher(): static
    {
        return $this->state(fn(array $attrs) => ['role' => 'teacher']);
    }

    public function student(): static
    {
        return $this->state(fn(array $attrs) => ['role' => 'student']);
    }

    public function fieldSupervisor(): static
    {
        return $this->state(fn(array $attrs) => ['role' => 'field_supervisor']);
    }

    public function inactive(): static
    {
        return $this->state(fn(array $attrs) => ['is_active' => false]);
    }

    public function unverified(): static
    {
        return $this->state(fn(array $attrs) => ['email_verified_at' => null]);
    }
}
