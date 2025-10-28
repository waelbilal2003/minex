<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Models\UserToken;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use App\Http\Services\AuthService;
use App\Http\Requests\LoginRequest;
use Illuminate\Support\Facades\Auth;
use App\Http\Requests\RegisterRequest;
use App\Http\Requests\ChangePasswordRequest;
use App\Http\Services\ChangePasswordService;
use App\Http\Services\TokenService;

class AuthController extends Controller
{
    protected $authService,$passwordService;

    public function __construct(AuthService $authService,ChangePasswordService $passwordService , protected TokenService $service)
    {
        $this->authService = $authService;
         $this->passwordService = $passwordService;
    }

    public function register(RegisterRequest $request)
    {
        $result = $this->authService->register($request->validated());

        return response()->json([
            'success' => $result['success'],
            'message' => $result['message'],
            'data'    => $result['user'] ?? null,
        ], $result['status']);
    }

       public function login(LoginRequest $request)
    {
        $result = $this->authService->login($request->validated(),$request);

        return response()->json([
            'success' => $result['success'],
            'message' => $result['message'],
            'data' => $result['data'] ?? null,
        ], $result['status']);
    }

    public function verifyToken(Request $request)
    {
        // جلب التوكن من الهيدر Bearer
        $authHeader = $request->header('Authorization', '');
        $token = null;
        if (preg_match('/Bearer\s+(.*)$/i', $authHeader, $matches)) {
            $token = $matches[1];
        }

        $result = $this->authService->verifyToken($token);

        return response()->json([
            'success' => $result['success'],
            'message' => $result['message'],
        ], $result['status']);
    }
      public function forgotPassword(Request $request)
    {
              $request->validate([
            'email_or_phone' => 'required|string|max:100',
        ]);
        $result = $this->authService->forgotPassword($request->input('email_or_phone'));

        return response()->json($result);
    }

        public function changePassword(ChangePasswordRequest $request): JsonResponse
    {
         $userId=$this->service->validateToken($request->bearerToken());
$user=User::where('id',$userId->id)->first();
        $result = $this->passwordService->change(
            $user,
            $request->current_password,
            $request->new_password
        );

        return response()->json($result);
    }

}
