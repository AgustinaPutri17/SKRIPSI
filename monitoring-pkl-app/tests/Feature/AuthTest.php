<?php

namespace Tests\Feature;

use Illuminate\Support\Facades\Hash;
use Tests\CreatesTestData;
use Tests\TestCase;

class AuthTest extends TestCase
{
    use CreatesTestData;

    // ── Login tests ────────────────────────────────

    public function test_user_can_login_with_correct_credentials(): void
    {
        $this->createAdmin();

        $response = $this->postJson('/api/login', [
            'username' => 'test.admin',
            'password' => 'password',
        ]);

        $response->assertStatus(200)
            ->assertJsonStructure([
                'success',
                'message',
                'data' => [
                    'user' => ['id', 'username', 'role'],
                    'token',
                ],
            ])
            ->assertJson(['success' => true]);
    }

    public function test_login_fails_with_wrong_password(): void
    {
        $this->createAdmin();

        $response = $this->postJson('/api/login', [
            'username' => 'test.admin',
            'password' => 'wrongpassword',
        ]);

        $response->assertStatus(401)
            ->assertJson(['success' => false]);
    }

    public function test_login_fails_with_nonexistent_user(): void
    {
        $response = $this->postJson('/api/login', [
            'username' => 'nobody',
            'password' => 'password',
        ]);

        $response->assertStatus(401)
            ->assertJson(['success' => false]);
    }

    public function test_inactive_user_cannot_login(): void
    {
        $admin = $this->createAdmin();
        $admin->update(['is_active' => false]);

        $response = $this->postJson('/api/login', [
            'username' => 'test.admin',
            'password' => 'password',
        ]);

        $response->assertStatus(403)
            ->assertJson(['success' => false]);
    }

    public function test_login_validation_requires_username_and_password(): void
    {
        $response = $this->postJson('/api/login', []);

        $response->assertStatus(422)
            ->assertJsonStructure(['errors' => ['username', 'password']]);
    }

    // ── Logout tests ───────────────────────────────

    public function test_authenticated_user_can_logout(): void
    {
        $admin = $this->createAdmin();
        $token = $admin->createToken('test')->plainTextToken;

        $response = $this->withToken($token)->postJson('/api/logout');

        $response->assertStatus(200)
            ->assertJson(['success' => true]);
    }

    public function test_unauthenticated_user_gets_401(): void
    {
        $response = $this->postJson('/api/logout');
        $response->assertStatus(401);
    }

    // ── /me tests ──────────────────────────────────

    public function test_me_returns_authenticated_user_data(): void
    {
        $admin = $this->createAdmin();
        $token = $admin->createToken('test')->plainTextToken;

        $response = $this->withToken($token)->getJson('/api/me');

        $response->assertStatus(200)
            ->assertJsonPath('data.username', 'test.admin')
            ->assertJsonPath('data.role', 'admin')
            ->assertJsonMissing(['password']);
    }
}
