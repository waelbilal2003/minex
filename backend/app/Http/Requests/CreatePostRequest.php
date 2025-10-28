<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class CreatePostRequest extends FormRequest
{
    public function authorize(): bool
    {
        // ما في مشكلة نخليها true، لأن التحقق من التوكن رح يكون بالسيرفيس
        return true;
    }

    public function rules(): array
    {
        return [
            'category' => 'required|string|max:255',
            'content'  => 'required|string',
            'price'    => 'nullable|numeric',
            'location' => 'nullable|string|max:255',
            'images.*' => 'nullable|image|mimes:jpg,jpeg,png,gif|max:2048',
            'video'    => 'nullable|mimetypes:video/mp4,video/avi,video/mpeg|max:10240',
        ];
    }

    public function messages(): array
    {
        return [
            'category.required' => 'القسم مطلوب',
            'content.required'  => 'وصف المنشور مطلوب',
            'price.numeric'     => 'السعر يجب أن يكون رقمًا',
            'images.*.image'    => 'الملف المرفوع يجب أن يكون صورة',
            'images.*.mimes'    => 'يجب أن تكون الصورة من نوع: jpg, jpeg, png, gif',
            'images.*.max'      => 'حجم الصورة لا يجب أن يتجاوز 2MB',
            'video.mimetypes'   => 'صيغة الفيديو غير مدعومة',
            'video.max'         => 'حجم الفيديو لا يجب أن يتجاوز 10MB',
        ];
    }
}
