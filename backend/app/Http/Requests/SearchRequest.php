<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class SearchRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true; 
    }

    public function rules(): array
    {
        return [
            'query' => 'required|string|min:2',
        ];
    }

    public function messages(): array
    {
        return [
            'query.required' => 'كلمة البحث مطلوبة',
            'query.min' => 'كلمة البحث يجب أن تحتوي على حرفين على الأقل',
        ];
    }
}
