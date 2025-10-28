<?php

namespace App\Http\Controllers;

use App\Models\UserToken;
use Illuminate\Http\Request;
use App\Http\Services\UserService;
use App\Http\Requests\ProfileRequest;
use App\Http\Services\TokenService;

class UserController extends Controller
{
    protected $userService;
    protected $service;

    public function __construct(UserService $userService, TokenService $service)
    {
        $this->userService = $userService;
        $this->service = $service;
    }

    public function profile(Request $request)
    {
        $token = $request->bearerToken();

        if (!$token) {
            return response()->json([
                'success' => false,
                'message' => 'التوكن مطلوب',
            ]);
        }

        $result = $this->userService->getProfile($token);

        return response()->json($result);
    }

    public function updateProfile(ProfileRequest $request)
    {
        $token = $request->bearerToken();
        return response()->json(
            $this->userService->updateProfile($token, $request->validated())
        );
    }
    public function index(Request $request)
    {
        $authHeader = $request->header('Authorization', '');
        $token = null;
        if (preg_match('/Bearer\s+(.*)$/i', $authHeader, $matches)) {
            $token = $matches[1];
        }
        $response = $this->userService->getAllUsers($token);

        return response()->json($response, $response['success'] ? 200 : 403);
    }

    public function toggleUserStatus(Request $request)
    {
        $authHeader = $request->header('Authorization', '');
        $token = null;

        if (preg_match('/Bearer\s+(.*)$/i', $authHeader, $matches)) {
            $token = $matches[1];
        }

        $response = $this->userService->toggleUserStatus($token, $request->all());

        return response()->json($response, $response['success'] ? 200 : 403);
    }
    public function deleteUser(Request $request)
    {
        $authHeader = $request->header('Authorization', '');
        $token = null;

        if (preg_match('/Bearer\s+(.*)$/i', $authHeader, $matches)) {
            $token = $matches[1];
        }

        $response = $this->userService->deleteUser($token, $request->all());

        return response()->json($response, $response['success'] ? 200 : 403);
    }
    public function getUserProfileAndPosts(Request $request)
    {
        $token = $request->bearerToken();
        if (!$token) {
            return response()->json(['success' => false, 'message' => 'التوكن مطلوب']);
        }

        $userToken = $this->service->validateToken($token);
        if (!$userToken ) {
            return response()->json(['success' => false, 'message' => 'التوكن غير صالح']);
        }

        $targetUserId =$request->input('id');

        if (!$targetUserId) {
            return response()->json(['success' => false, 'message' => 'معرف المستخدم الهدف مطلوب']);
        }
// dd($requesظt->all());
        $response = $this->userService->getUserProfileAndPosts($targetUserId);
        return response()->json($response);
    }
}
