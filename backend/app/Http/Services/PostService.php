<?php

namespace App\Http\Services;

use App\Models\Post;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

class PostService
{
        public function __construct(protected TokenService $service){
    }
    public function createPost($request)
    {
        $token = $this->service->getBearerToken($request);
        if (!$token) {
            return ['success' => false, 'message' => 'التوكن مطلوب'];
        }

        $record =  $this->service->validateToken($token);
        if (!$record) {
            return ['success' => false, 'message' => 'التوكن غير صالح أو منتهي الصلاحية'];
        }

        $user = User::find($record->id);
        if (!$user) {
            return ['success' => false, 'message' => 'المستخدم غير موجود'];
        }

        // تحديث النشاط
        $user->update(['last_activity' => now()]);
// dd( $user);
        // رفع الصور
        $images = [];
        if ($request->hasFile('images')) {
            foreach ($request->file('images') as $image) {
                $path = $image->store('uploads/posts', 'public');
                $images[] = $path;
            }
        }

        // رفع الفيديو
        $videoPath = null;
        if ($request->hasFile('video')) {
            $videoPath = $request->file('video')->store('uploads/videos', 'public');
        }

        // إنشاء البوست
        $post = Post::create([
            'user_id'   => $user->id,
            'title'     => $request->title,
            'category'  => $request->category,
            'content'   => $request->content,
            'price'     => $request->price,
            'location'  => $request->location,
            'images'    => !empty($images) ? json_encode($images) : null,
            'video_url' => $videoPath,
        ]);

        return [
            'success' => true,
            'message' => 'تم إنشاء المنشور بنجاح',
            'data'    => ['post_id' => $post->id]
        ];
    }
public function getPosts($request)
{
    $token = $this->service->getBearerToken($request);
    $userId = null;

    if ($token) {
        $records = DB::table('user_tokens')->get();
        foreach ($records as $record) {
            if (Hash::check($token, $record->token)) {
                $userId = $record->user_id;
                $user = User::find($userId);

                if ($user) {
                    $user->update(['last_activity' => now()]);
                }
                break;
            }
        }
    }

    // جلب آخر 20 منشور
    $posts = Post::with('user:id,full_name,gender,user_type')
        ->orderByDesc('created_at')
        ->limit(20)
        ->get();

    $posts = $posts->map(function ($post) use ($userId) {
        return [
            'id'              => $post->id,
            'title'           => $post->title,
            'content'         => $post->content,
            'category'        => $post->category,
            'price'           => $post->price,
            'location'        => $post->location,
            'likes_count'     => $post->likes_count,
            'comments_count'  => $post->comments_count,

            'created_at'      => $post->created_at->toISOString(),
            'is_liked_by_user'=> false,

            // الصور
            'images' => !empty($post->images)
                ? collect(json_decode($post->images, true))->map(fn($img) => url('storage/' . $img))->toArray()
                : [],

            // الفيديو
            'video' => $post->video_url ? [
                'video_path'      => url('storage/' . $post->video_url),
            ] : null,

            // بيانات المستخدم
            'user' => [
                'id'        => $post->user->id ?? null,
                'full_name' => $post->user->full_name ?? 'مستخدم',
                'gender'    => $post->user->gender ?? null,
                'user_type' => $post->user->user_type ?? null,
            ]
        ];
    });

    return [
        'success' => true,
        'data'    => $posts
    ];
}


public function getAllPosts($request)
{
    $token = $this->service->getBearerToken($request);
    if (!$token) {
        return ['success' => false, 'message' => 'التوكن مطلوب'];
    }

    $record =  $this->service->validateToken($token);
    // dd($token);
    if (!$record) {
        return ['success' => false, 'message' => 'التوكن غير صالح'];
    }

    $user = User::find($record->id);
    if (!$user || !$user->is_admin) {
        return ['success' => false, 'message' => 'ليس لديك صلاحيات إدارية'];
    }

    try {
        $posts = Post::with('user:id,full_name')
            ->orderBy('created_at', 'desc')
            ->get();

        $posts->transform(function ($post) {
            $post->images = $post->images ? json_decode($post->images, true) : [];
            $post->user_name = $post->user->full_name ?? 'مستخدم';
            unset($post->user);
            return $post;
        });

        return [
            'success' => true,
            'message' => 'تم جلب جميع المنشورات',
            'data'    => ['posts' => $posts]
        ];
    } catch (\Exception $e) {
        return [
            'success' => false,
            'message' => 'خطأ في جلب المنشورات: ' . $e->getMessage()
        ];
    }
}
public function deletePost($request)
{
    $token = $this->service->getBearerToken($request);
    if (!$token) {
        return ['success' => false, 'message' => 'التوكن مطلوب'];
    }

    $record =  $this->service->validateToken($token);
    if (!$record) {
        return ['success' => false, 'message' => 'التوكن غير صالح'];
    }

    $user = User::find($record->id);
    if (!$user) {
        return ['success' => false, 'message' => 'المستخدم غير موجود'];
    }

    $postId = $request->post_id;
    if (!$postId) {
        return ['success' => false, 'message' => 'معرف المنشور مطلوب'];
    }

    $post = Post::find($postId);
    if (!$post) {
        return ['success' => false, 'message' => 'المنشور غير موجود'];
    }

    // التحقق إذا كان المستخدم هو صاحب المنشور أو أدمن
    $isOwner = ($post->user_id == $user->id);
    $isAdmin = $user->is_admin;

    if (!$isOwner && !$isAdmin) {
        return ['success' => false, 'message' => 'ليس لديك صلاحية لحذف هذا المنشور'];
    }

    try {
        $post->delete();
        return ['success' => true, 'message' => 'تم حذف المنشور بنجاح'];
    } catch (\Exception $e) {
        return ['success' => false, 'message' => 'خطأ في حذف المنشور: ' . $e->getMessage()];
    }
}


public function toggleLike($request)
{
    $token = $this->service->getBearerToken($request);
    if (!$token) {
        return ['success' => false, 'message' => 'التوكن مطلوب'];
    }

    $record = $this->service->validateToken($token);
    if (!$record) {
        return ['success' => false, 'message' => 'التوكن غير صالح'];
    }

    $user = User::find($record->id);
    if (!$user) {
        return ['success' => false, 'message' => 'المستخدم غير موجود'];
    }

    $post = Post::find($request->post_id);
    if (!$post) {
        return ['success' => false, 'message' => 'المنشور غير موجود'];
    }

    // التحقق إذا المستخدم عامل لايك مسبقاً
   $alreadyLiked = DB::table('post_likes')
        ->where('post_id', $post->id)
        ->where('user_id', $user->id)
        ->exists();

    if ($alreadyLiked) {
        DB::table('post_likes')
            ->where('post_id', $post->id)
            ->where('user_id', $user->id)
            ->delete();

        $post->decrement('likes_count');

        return [
            'success' => true,
            'message' => 'تم تحديث الإعجاب بنجاح',
            'isLiked' => false,
            'likes_count' => $post->likes_count
        ];
    } else {
        DB::table('post_likes')->insert([
            'post_id' => $post->id,
            'user_id' => $user->id,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $post->increment('likes_count');

        return [
            'success' => true,
            'message' => 'تم تحديث الإعجاب بنجاح',
            'isLiked' => true,
            'likes_count' => $post->likes_count
        ];
    }}

}