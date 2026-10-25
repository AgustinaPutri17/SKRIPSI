<?php

namespace App\Http\Requests\Auth;

use Illuminate\Foundation\Http\FormRequest;

class LoginRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'identifier' => ['required_without:username', 'string'],
            'username' => ['required_without:identifier', 'string'],
            'password' => ['required', 'string'],
            'role' => ['nullable', 'string', 'in:student,teacher,field_supervisor,admin'],
        ];
    }

    /**
     * Get the resolved login identifier (NIS, teacher code, or username).
     */
    public function getIdentifier(): string
    {
        return (string) ($this->input('identifier') ?? $this->input('username'));
    }
}
