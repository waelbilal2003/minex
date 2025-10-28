<?php

namespace App\Http\Services;

use App\Models\User;
use App\Models\VipAd;
use App\Models\UserToken;
use Illuminate\Support\Facades\URL;
use Illuminate\Support\Facades\File;
class VipAdService
{
    public function getVipAds(?string $token): array
    {
        $isAdminRequest = false;

        if ($token) {
            $userToken = UserToken::with('user')->where('token', $token)->first();
            if ($userToken && $userToken->user && $userToken->user->is_admin) {
                $isAdminRequest = true;
            }
        }

        $query = VipAd::with('user')
            ->when(!$isAdminRequest, function ($q) {
                $q->where('status', 'active')
                  ->where('expires_at', '>', now())
                  ->limit(10);
            })
            ->orderByDesc('created_at');

        $ads = $query->get()->map(function ($ad) {
            return $this->formatAd($ad, false);
        });

        return [
            'success' => true,
            'message' => 'تم جلب الإعلانات المميزة',
            'data' => ['vip_ads' => $ads]
        ];
    }

    public function getVipAdsPublic(): array
    {
        $ads = VipAd::with('user')
            ->where('status', 'active')
            ->where('expires_at', '>', now())
            ->orderByDesc('created_at')
            ->limit(10)
            ->get()
            ->map(function ($ad) {
                return $this->formatAd($ad, true);
            });

        return [
            'success' => true,
            'message' => 'تم جلب الإعلانات المميزة',
            'data' => $ads
        ];
    }

    private function formatAd(VipAd $ad, bool $withVideos): array
    {
        // معالجة صورة الغلاف
        $cover = $ad->cover_image_url
            ? $this->makeFullUrl($ad->cover_image_url)
            : 'https://via.placeholder.com/400x200/4ECDC4/FFFFFF?text=VIP+Ad';

        $data = [
            'id' => $ad->id,
            'title' => $ad->title,
            'description' => $ad->description,
            'category' => $ad->category,
            'image' => $cover,
            'cover_image_url' => $cover,
            'price' => $ad->price_paid . ' ' . $ad->currency,
            'location' => $ad->location ?? 'غير محدد',
            'phone' => $ad->contact_phone ?? '',
            'user_name' => $ad->user?->full_name,
            'created_at' => $ad->created_at,
            'expires_at' => $ad->expires_at,
        ];

        // معالجة الميديا
        $mediaFiles = $ad->media_files ?? [];
        if ($withVideos) {
            $data['additional_images'] = [];
            $data['videos'] = [];
            if (!is_array($mediaFiles)) {
    $mediaFiles = json_decode($mediaFiles, true) ?? [];
}
            foreach ($mediaFiles as $file) {
                $url = $this->makeFullUrl($file);
                if (preg_match('/\.(mp4|avi|mov|mkv|3gp)$/i', $url)) {
                    $data['videos'][] = $url;
                } else {
                    $data['additional_images'][] = $url;
                }
            }
        } else {
$mediaFiles = $ad->media_files;

// تأكد إنو Array، إذا رجع String أو Null حوّليه
if (!is_array($mediaFiles)) {
    $mediaFiles = json_decode($mediaFiles, true) ?? [];
}

// الآن آمن نعمل array_map
$data['images'] = array_map(fn($file) => $this->makeFullUrl($file), $mediaFiles);
        }

        return $data;
    }

    private function makeFullUrl(string $path): string
    {
        if (preg_match('/^http/', $path)) {
            return $path;
        }
        return URL::to($path);
    }public function uploadCoverImage(User $user, \Illuminate\Http\UploadedFile $imageFile, string $fileName): array
{
    // تحقق من صلاحيات الأدمن
    if (!$user->is_admin) {
        return [
            'success' => false,
            'message' => 'صلاحيات غير كافية'
        ];
    }

    if (!$imageFile || empty($fileName)) {
        return [
            'success' => false,
            'message' => 'بيانات الصورة واسم الملف مطلوبان'
        ];
    }

    try {
        // إضافة الامتداد الصحيح لاسم الملف
        $extension = $imageFile->getClientOriginalExtension();
        $safeFileName = pathinfo($fileName, PATHINFO_FILENAME) . '.' . $extension;

        // تخزين الصورة في storage/app/public/vip_covers
        $path = $imageFile->storeAs('public/vip_covers', $safeFileName);

        if (!$path) {
            return [
                'success' => false,
                'message' => 'فشل في حفظ الصورة'
            ];
        }

        // إنشاء رابط صالح للعرض
        $imageUrl = asset(str_replace('public/', 'storage/', $path));

        return [
            'success' => true,
            'message' => 'تم رفع صورة الغلاف بنجاح',
            'data' => [
                'image_url' => $imageUrl,
                'file_path' => storage_path('app/' . $path)
            ]
        ];

    } catch (\Exception $e) {
        return [
            'success' => false,
            'message' => 'خطأ في رفع الصورة: ' . $e->getMessage()
        ];
    }
}
public function uploadMediaFile(User $user, \Illuminate\Http\UploadedFile $file, string $fileName, string $fileType = 'image'): array
    {
        // تحقق من صلاحيات الأدمن
        if (!$user->is_admin) {
            return [
                'success' => false,
                'message' => 'صلاحيات غير كافية'
            ];
        }

        if (!$file || empty($fileName)) {
            return [
                'success' => false,
                'message' => 'بيانات الملف واسم الملف مطلوبان'
            ];
        }

        try {
            // تحديد مجلد التخزين
            $dir = $fileType === 'video' ? 'public/vip_videos' : 'public/vip_images';

            // إضافة الامتداد الصحيح
            $extension = $file->getClientOriginalExtension();
            $safeFileName = pathinfo($fileName, PATHINFO_FILENAME) . '.' . $extension;

            // التحقق من حجم الملف
            $fileSizeMB = $file->getSize() / (1024 * 1024);
            if ($fileType === 'video' && $fileSizeMB > 50) {
                return ['success' => false, 'message' => 'حجم الفيديو كبير جداً (الحد الأقصى 50 ميجابايت)'];
            }
            if ($fileType === 'image' && $fileSizeMB > 10) {
                return ['success' => false, 'message' => 'حجم الصورة كبير جداً (الحد الأقصى 10 ميجابايت)'];
            }

            // تخزين الملف
            $path = $file->storeAs($dir, $safeFileName);

            if (!$path) {
                return ['success' => false, 'message' => 'فشل في حفظ الملف'];
            }

            // رابط صالح للعرض
            $fileUrl = asset(str_replace('public/', 'storage/', $path));

            return [
                'success' => true,
                'message' => 'تم رفع الملف بنجاح',
                'data' => [
                    'file_url' => $fileUrl,
                    'file_path' => storage_path('app/' . $path),
                    'file_type' => $fileType,
                    'file_size_mb' => round($fileSizeMB, 2)
                ]
            ];

        } catch (\Exception $e) {
            return [
                'success' => false,
                'message' => 'خطأ في رفع الملف: ' . $e->getMessage()
            ];
        }
    }
       public function createEnhancedVipAd(User $user, array $data): array
    {
        // تحقق من صلاحيات الأدمن
        if (!$user->is_admin) {
            return [
                'success' => false,
                'message' => 'صلاحيات غير كافية'
            ];
        }

        if (empty($data['title'])) {
            return [
                'success' => false,
                'message' => 'عنوان الإعلان مطلوب'
            ];
        }

        try {
            // حساب تاريخ الانتهاء
$durationHours = isset($data['duration_hours'])
    ? (int) $data['duration_hours']
    : 720;
            $expiresAt = now()->addHours($durationHours);

            // تحويل ملفات الوسائط إلى JSON
            $mediaFilesJson = !empty($data['media_files'])
                ? json_encode($data['media_files'])
                : null;

            // إنشاء الإعلان
            $vipAd = VipAd::create([
                'user_id'         => $user->id,
                'title'           => $data['title'],
                'description'     => $data['description'] ?? '',
                'cover_image_url' => $data['cover_image_url'] ?? '',
                'media_files'     => $mediaFilesJson,
                'contact_phone'   => $data['contact_phone'] ?? '',
                'contact_whatsapp'=> $data['contact_whatsapp'] ?? '',
                'price_paid'      => $data['price_paid'] ?? 10.00,
                'currency'        => $data['currency'] ?? 'USD',
                'duration_hours'  => $durationHours,
                'status'          => $data['status'] ?? 'active',
                'expires_at'      => $expiresAt,
            ]);

            return [
                'success' => true,
                'message' => 'تم إنشاء الإعلان المميز بنجاح',
                'data' => [
                    'ad_id' => $vipAd->id,
                    'expires_at' => $expiresAt->toDateTimeString(),
                ]
            ];

        } catch (\Exception $e) {
            return [
                'success' => false,
                'message' => 'خطأ في إنشاء الإعلان: ' . $e->getMessage()
            ];
        }
    }

    public function getVipAdDetails(int $adId): array
    {
        if (!$adId) {
            return [
                'success' => false,
                'message' => 'معرف الإعلان مطلوب'
            ];
        }

        $ad = VipAd::with('user')
            ->where('id', $adId)
            ->where('status', 'active')
            ->first();

        if (!$ad) {
            return [
                'success' => false,
                'message' => 'الإعلان غير موجود أو غير نشط'
            ];
        }

        // معالجة الوسائط
        $additionalImages = [];
        $videos = [];

        $mediaFiles = $ad->media_files;

        if (!empty($mediaFiles)) {
            if (!is_array($mediaFiles)) {
                $mediaFiles = json_decode($mediaFiles, true) ?? [];
            }

            foreach ($mediaFiles as $media) {
                $url = $this->makeFullUrl($media);

                if (preg_match('/\.(mp4|avi|mov|mkv|3gp)$/i', $url)) {
                    $videos[] = $url;
                } else {
                    $additionalImages[] = $url;
                }
            }
        }

        // إذا ما في صور إضافية، حط صورة الغلاف
        if (empty($additionalImages) && !empty($ad->cover_image_url)) {
            $additionalImages[] = $this->makeFullUrl($ad->cover_image_url);
        }

        return [
            'success' => true,
            'message' => 'تم جلب تفاصيل الإعلان',
            'data' => [
                'id' => $ad->id,
                'title' => $ad->title,
                'description' => $ad->description,
                'cover_image_url' => $this->makeFullUrl($ad->cover_image_url),
                'additional_images' => $additionalImages,
                'videos' => $videos,
                'price' => $ad->price_paid . ' ' . $ad->currency,
                'duration_hours' => $ad->duration_hours,
                'status' => $ad->status,
                'expires_at' => $ad->expires_at,
                'user_name' => $ad->user?->full_name,
                'user_phone' => $ad->user?->phone,
                'created_at' => $ad->created_at,
            ]
        ];
    }
}
