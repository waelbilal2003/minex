<?php

namespace App\Http\Controllers;

use App\Http\Services\TokenService;
use App\Models\UserToken;
use Illuminate\Http\Request;
use App\Http\Services\VipAdService;

class VipAdController extends Controller
{
    protected $vipAdService;
    protected $service;

    public function __construct(VipAdService $vipAdService, TokenService $service)
    {
        $this->vipAdService = $vipAdService;
        $this->service = $service;
    }

    // جلب الإعلانات مع التحقق من الأدمن (مثل getVipAds)
    public function getVipAds(Request $request)
    {
        $token = $request->bearerToken();
        return response()->json(
            $this->vipAdService->getVipAds($token)
        );
    }

    // جلب الإعلانات العامة للصفحة الرئيسية (مثل get_vip_ads)
    public function getVipAdsPublic()
    {
        return response()->json(
            $this->vipAdService->getVipAdsPublic()
        );
    }
    public function uploadCoverImage(Request $request)
    {

        $token = $request->bearerToken();

        if (!$token) {
            return response()->json([
                'success' => false,
                'message' => 'التوكن مطلوب'
            ], 401);
        }

        // التحقق من التوكن من جدول user_tokens
        $userToken = $this->service->validateToken($token);
        if (!$userToken ) {
            return response()->json([
                'success' => false,
                'message' => 'توكن غير صالح'
            ], 401);
        }

   $validated = $request->validate([
        'image' => 'required|file|mimes:jpg,jpeg,png,webp|max:5120', // 5MB
        'file_name' => 'required|string|max:255'
    ]);
        $imageData = $request->file('image', '');
        $fileName  = $request->input('file_name', '');

        $result = $this->vipAdService->uploadCoverImage($userToken, $imageData, $fileName);

        return response()->json($result, $result['success'] ? 200 : 422);
    }
    public function uploadMediaFile(Request $request)
    {
        $token = $request->bearerToken();
        if (!$token) {
            return response()->json([
                'success' => false,
                'message' => 'التوكن مطلوب'
            ], 401);
        }
        $userToken = $this->service->validateToken($token);
        if (!$userToken) {
            return response()->json([
                'success' => false,
                'message' => 'توكن غير صالح'
            ], 401);
        }

    $validated = $request->validate([
        'file' => 'required|file|mimes:jpg,jpeg,png,webp,mp4,mov,avi|max:10240', // 10MB
        'file_name' => 'required|string|max:255',
        'file_type' => 'required|in:image,video'
    ]);
        $file = $request->file('file');
        $fileName = $request->input('file_name', '');
        $fileType = $request->input('file_type', 'image'); // image أو video

        $result = $this->vipAdService->uploadMediaFile($userToken, $file, $fileName, $fileType);

        return response()->json($result, $result['success'] ? 200 : 422);
    }
    public function createEnhancedVipAd(Request $request)
    {
        $token = $request->bearerToken();
        if (!$token) {
            return response()->json([
                'success' => false,
                'message' => 'التوكن مطلوب'
            ], 401);
        }
        $userToken = $this->service->validateToken($token);
        if (!$userToken ) {
            return response()->json([
                'success' => false,
                'message' => 'توكن غير صالح'
            ], 401);
        }


        $data = $request->all();

        $result = $this->vipAdService->createEnhancedVipAd($userToken, $data);

        return response()->json($result, $result['success'] ? 200 : 422);
    }

    public function getVipAdDetails(Request $request)
    {
        $adId = $request->query('ad_id', 0);

        $result = $this->vipAdService->getVipAdDetails((int) $adId);

        return response()->json($result, $result['success'] ? 200 : 404);
    }
}
