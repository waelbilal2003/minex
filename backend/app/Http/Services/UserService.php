<?php

namespace App\Http\Services;

use App\Models\Post;
use App\Models\User;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Auth;

class UserService
{
    public function __construct(protected TokenService $service){
    }
    public function getProfile(string $token)
    {
        $userId = $this->service->validateToken($token);
        // dd($userId);
        if (!$userId) {
            return ['success' => false, 'message' => 'التوكن غير صالح'];
        }
        DB::table('users')->where('id', $userId->id)->update(['updated_at' => now()]);
        $user = DB::table('users')->select('id', 'full_name', 'email', 'phone', 'gender', 'is_admin','user_type')->where('id', $userId->id)->first();

        if (!$user) {
            return ['success' => false, 'message' => 'المستخدم غير موجود'];
        }

        return ['success' => true, 'message' => 'تم جلب الملف الشخصي', 'data' => $user];
    }



    public function updateProfile(string $token, array $data)
    {
        $userId = $this->service->validateToken($token);
        if (!$userId) {
            return ['success' => false, 'message' => 'التوكن غير صالح'];
        }

        $fullName = $data['full_name'] ?? null;
        $gender = $data['gender'] ?? null; // 'male' أو 'female'

        if (!$fullName) {
            return ['success' => false, 'message' => 'الاسم الكامل مطلوب'];
        }

        $updateData = ['full_name' => $fullName];

        if ($gender) {
            $genderArabic = $this->convertGenderToArabic($gender);
            if (!in_array($genderArabic, ['ذكر', 'أنثى'])) {
                return ['success' => false, 'message' => 'قيمة الجنس غير صالحة'];
            }
            $updateData['gender'] = $genderArabic;
        }

        // تحديث المستخدم
        DB::table('users')->where('id', $userId->id)->update($updateData + ['updated_at' => now()]);

        // جلب البيانات المحدثة
        $user = DB::table('users')
            ->select('id', 'full_name', 'email', 'phone', 'gender', 'is_admin','user_type')
            ->where('id', $userId->id)
            ->first();

        // إضافة التوكن الحالي
        $userData = (array) $user;
        $userData['token'] = $token;
        $userData['user_id'] = $user->id;
        $userData['user_type'] = $user->user_type;
        $message = count($updateData) > 1 ? 'تم تحديث الملف الشخصي بنجاح' : 'لم يتم تغيير أي بيانات';
        return ['success' => true, 'message' => $message, 'data' => $userData];
    }


    private function convertGenderToArabic(string $gender)
    {
        return match (strtolower($gender)) {
            'male' => 'ذكر',
            'female' => 'أنثى',
            default => '',
        };
    }

    public function getAllUsers($token)
    {
        if (!$token) {
            return [
                'success' => false,
                'message' => 'التوكن مطلوب'
            ];
        }

        // التحقق من صلاحية التوكن وجلب المستخدم
        $record = $this->service->validateToken($token);
        if (!$record) {
            return [
                'success' => false,
                'message' => 'التوكن غير صالح'
            ];
        }
        $user = User::find($record->id);

        if (!$user || !$user->is_admin) {
            return [
                'success' => false,
                'message' => 'ليس لديك صلاحيات إدارية'
            ];
        }

        try {
            $users = User::select('id', 'full_name', 'email', 'phone', 'gender', 'is_active', 'is_admin', 'created_at')
                ->orderBy('created_at', 'desc')
                ->get();

            return [
                'success' => true,
                'message' => 'تم جلب المستخدمين بنجاح',
                'data' => ['users' => $users]
            ];
        } catch (\Exception $e) {
            return [
                'success' => false,
                'message' => 'خطأ في جلب المستخدمين: ' . $e->getMessage()
            ];
        }
    }

    public function toggleUserStatus($token, $data)
    {
        if (!$token) {
            return [
                'success' => false,
                'message' => 'التوكن مطلوب'
            ];
        }

        // التحقق من صلاحية التوكن وجلب المستخدم
        $record = $this->service->validateToken($token);

        if (!$record) {
            return [
                'success' => false,
                'message' => 'التوكن غير صالح'
            ];
        }

        $user = User::find($record->id);

        if (!$user || !$user->is_admin) {
            return [
                'success' => false,
                'message' => 'ليس لديك صلاحيات إدارية'
            ];
        }

        $targetUserId = $data['id'] ?? 0;

        if (!$targetUserId) {
            return [
                'success' => false,
                'message' => 'معرف المستخدم مطلوب'
            ];
        }

        try {
            $targetUser = User::find($targetUserId);

            if (!$targetUser) {
                return [
                    'success' => false,
                    'message' => 'لم يتم العثور على المستخدم'
                ];
            }

            // التبديل (Toggle) بين مفعّل وغير مفعّل
            $targetUser->is_active = !$targetUser->is_active;
            $targetUser->save();

            return [
                'success' => true,
                'message' => 'تم تحديث حالة المستخدم بنجاح'
            ];
        } catch (\Exception $e) {
            return [
                'success' => false,
                'message' => 'خطأ في تحديث حالة المستخدم: ' . $e->getMessage()
            ];
        }
    }
    public function deleteUser($token, $data)
    {
        if (!$token) {
            return [
                'success' => false,
                'message' => 'التوكن مطلوب'
            ];
        }

        // التحقق من صلاحية التوكن
        $record = $this->service->validateToken($token);
        if (!$record) {
            return [
                'success' => false,
                'message' => 'التوكن غير صالح'
            ];
        }

        $user = User::find($record->id);
        if (!$user || !$user->is_admin) {
            return [
                'success' => false,
                'message' => 'ليس لديك صلاحيات إدارية'
            ];
        }

        $targetUserId = $data['id'] ?? 0;
        if (!$targetUserId) {
            return [
                'success' => false,
                'message' => 'معرف المستخدم مطلوب'
            ];
        }

        try {
            // حذف منشورات المستخدم
            // Post::where('user_id', $targetUserId)->delete();

            // حذف المستخدم
            $deleted = User::where('id', $targetUserId)->delete();

            if ($deleted > 0) {
                return [
                    'success' => true,
                    'message' => 'تم حذف المستخدم بنجاح'
                ];
            } else {
                return [
                    'success' => false,
                    'message' => 'لم يتم العثور على المستخدم'
                ];
            }
        } catch (\Exception $e) {
            return [
                'success' => false,
                'message' => 'خطأ في حذف المستخدم: ' . $e->getMessage()
            ];
        }
    }public function getUserProfileAndPosts($targetUserId)
{
    // جلب ملف المستخدم
    $user = User::where('id', $targetUserId)
        ->where('is_active', 1)
        ->first(['id', 'full_name', 'email', 'phone', 'gender', 'created_at', 'user_type']);

    if (!$user) {
        return [
            'success' => false,
            'message' => 'المستخدم غير موجود أو غير نشط'
        ];
    }

    // جلب منشورات المستخدم
    $posts = $user->posts()
        ->where('is_active', 1)
        ->orderByDesc('created_at')
        ->limit(50)
        ->get();

    $posts = $posts->map(function ($post) use ($user) {
        $postArray = $post->toArray();

        // ✅ معالجة الصور ككائنات
        $postArray['images'] = [];
        if (!empty($post->images)) {
            $images = json_decode($post->images, true);
            if (is_array($images)) {
                $postArray['images'] = array_map(fn($img) => [
                    'image_path' => url('storage/' . $img)
                ], $images);
            }
        }

        // ✅ الفيديو
        $postArray['video'] = null;
        if (!empty($post->video_url)) {
            $postArray['video'] = preg_match('/^http/', $post->video_url)
                ? $post->video_url
                : url('storage/' . $post->video_url);
        }
        unset($postArray['video_url']); // ما بدنا نرجع video_url

        // ✅ تضمين بيانات المستخدم داخل كل بوست
        $postArray['user'] = [
            'id' => $user->id,
            'full_name' => $user->full_name,
            'gender' => $user->gender,
            'user_type' => $user->user_type,
        ];

        return $postArray;
    });

    return [
        'success' => true,
        'data' => [
            'user' => $user,
            'posts' => $posts
        ]
    ];
}

}
