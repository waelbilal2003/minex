<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class RegisterRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, \Illuminate\Contracts\Validation\ValidationRule|array<mixed>|string>
     */
public function rules(): array
{
    return [
        'full_name'      => 'required|string|max:100',
        'email_or_phone' => [
            'required',
            'string',
            'max:100',
            function ($attribute, $value, $fail) {
                if (filter_var($value, FILTER_VALIDATE_EMAIL)) {
                    // إذا كان ايميل
                    if (\App\Models\User::where('email', $value)->exists()) {
                        $fail('البريد الإلكتروني مستخدم مسبقًا.');
                    }
                } else {
                    // إذا كان رقم هاتف
                    $phone = preg_replace('/[^0-9]/', '', $value);
                    if (substr($phone, 0, 1) === '0') $phone = substr($phone, 1);
                    if (!str_starts_with($phone, '963')) $phone = '963' . $phone;
                    $phone = '+' . $phone;

                    if (\App\Models\User::where('phone', $phone)->exists()) {
                        $fail('رقم الهاتف مستخدم مسبقًا.');
                    }
                }
            }
        ],
        'password' => 'required|string|min:6',
        'gender'   => 'required|in:ذكر,أنثى',
        'userType'=>'nullable'
    ];
}

}
