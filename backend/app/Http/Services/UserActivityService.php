<?php
namespace App\Http\Services;

use App\Models\UserSession;

class UserActivityService
{
    public function updateUserActivity(int $userId): void
    {
       UserSession::updateOrCreate(
    ['user_id' => $userId],
    [
        'last_seen' => now(),
        'ip_address' => request()->ip(),
        'user_agent' => request()->userAgent(),
    ]
);

    }
}
