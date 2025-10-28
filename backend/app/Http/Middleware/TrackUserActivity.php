<?php

namespace App\Http\Middleware;

use App\Http\Services\TokenService;
use App\Models\UserToken;
use App\Http\Services\UserActivityService;
use Closure;
use Illuminate\Http\Request;

class TrackUserActivity
{
public function __construct(protected TokenService $service){}
    public function handle(Request $request, Closure $next)
    {
        // جلب التوكين من الهيدر
        $authHeader = $request->header('Authorization');
        if ($authHeader && str_starts_with($authHeader, 'Bearer ')) {
            $token = substr($authHeader, 7);

            // تحقق من التوكين في جدول user_tokens
            $userToken =  $this->service->validateToken($token);

            if ($userToken) {
                $userId = $userToken->id;

                // تحديث النشاط
                app(UserActivityService::class)->updateUserActivity($userId);

                // نمرر user_id ضمن الريكوست للكنترولر
                $request->merge(['user_id' => $userId]);
            }
        }

        return $next($request);
    }
}
