<?php

namespace App\Http\Services;

use App\Models\Category;
use App\Models\Post;

class CategoryService
{
    public function getCategories($categoryId = null)
    {
        try {
            if ($categoryId) {
                // جلب التصنيف المطلوب
                $category = Category::findOrFail($categoryId);

                // جلب البوستات المرتبطة باسم التصنيف
                $posts = Post::where('category', $category->name)
                    ->get();
                return [
                    'success' => true,
                    'message' => 'تم جلب البوستات للتصنيف',
                    'data' => [
                        'category' => $category->only(['id', 'name']),
                        'posts' => $posts
                    ]
                ];
            }

            // لو ما بعثت id، يرجع كل التصنيفات بدون بوستات
            $categories = Category::
                orderBy('name')
                ->get();

            return [
                'success' => true,
                'message' => 'تم جلب الفئات',
                'data' => ['categories' => $categories]
            ];
        } catch (\Exception $e) {
            return [
                'success' => false,
                'message' => 'خطأ في جلب الفئات: ' . $e->getMessage()
            ];
        }
    }
}
