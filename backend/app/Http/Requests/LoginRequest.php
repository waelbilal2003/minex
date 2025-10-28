<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class LoginRequest extends FormRequest
{
    public function authorize()
    {
        return true; // السماح بالطلب
    }

    public function rules()
    {
        return [
            'email_or_phone' => 'required|string',
            'password' => 'required|string|min:6',
        ];
    }

    public function messages()
    {
        return [
            'email_or_phone.required' => 'البريد الإلكتروني/الهاتف مطلوب',
            'password.required' => 'كلمة المرور مطلوبة',
            'password.min' => 'كلمة المرور قصيرة جداً',
        ];
    }
}
