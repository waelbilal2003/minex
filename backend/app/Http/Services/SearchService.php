<?php

namespace App\Http\Services;

use App\Models\Post;
use App\Models\User;

class SearchService
{
    public function search($query)
    {
        $results = [
            'users' => [],
            'posts' => []
        ];

        // البحث عن المستخدمين
        $results['users'] = User::where(function($q) use ($query) {
                $q->where('full_name', 'LIKE', "%$query%")
                  ->orWhere('email', 'LIKE', "%$query%")
                  ->orWhere('phone', 'LIKE', "%$query%");
            })
            ->where('is_active', 1)
            ->orderBy('full_name')
            ->limit(10)
            ->get(['id','full_name','email','phone']);

        // البحث عن المنشورات
        $posts = Post::with('user:id,full_name')
            ->where(function($q) use ($query) {
                $q->where('title', 'LIKE', "%$query%")
                  ->orWhere('content', 'LIKE', "%$query%")
                  ->orWhere('category', 'LIKE', "%$query%")
                  ->orWhere('location', 'LIKE', "%$query%");
            })
            ->where('is_active', 1)
            ->whereHas('user', function($q) {
                $q->where('is_active', 1);
            })
            ->orderByDesc('created_at')
            ->limit(20)
            ->get();

        // معالجة الصور والفيديو
        $results['posts'] = $posts->map(function($post) {
            $postArray = $post->toArray();

            // تحويل كل الصور إلى روابط asset صالحة
            $postArray['images'] = [];
            if (!empty($post->images)) {
                $images = json_decode($post->images, true);
                if (is_array($images)) {
                    foreach ($images as $img) {
                        $postArray['images'][] = url('storage/' . $img);
                    }
                }
            }

            // رابط الفيديو
            if (!empty($postArray['video_url']) && !preg_match('/^http/', $postArray['video_url'])) {
                $postArray['video_url'] = url('storage/' . $postArray['video_url']);
            }

            $postArray['user_name'] = $post->user->full_name ?? 'مستخدم';
            unset($postArray['user']); // إزالة العلاقة الأصلية

            return $postArray;
        });

        $totalResults = count($results['users']) + count($results['posts']);
        $message = $totalResults > 0 ? "تم العثور على $totalResults نتيجة" : 'لا توجد نتائج للبحث';

        return [
            'success' => true,
            'message' => $message,
            'data' => $results
        ];
    }
}
