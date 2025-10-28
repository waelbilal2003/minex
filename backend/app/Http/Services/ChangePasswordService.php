<?php

namespace App\Http\Services;

use Illuminate\Support\Facades\Hash;
use App\Models\User;

class ChangePasswordService
{
    public function change(User $user, string $currentPassword, string $newPassword): array
    {
        if (!Hash::check($currentPassword, $user->password)) {
            return [
                'success' => false,
                'message' => 'كلمة المرور الحالية غير صحيحة',
            ];
        }

        $user->password = Hash::make($newPassword);
        $user->save();

        return [
            'success' => true,
            'message' => 'تم تغيير كلمة المرور بنجاح',
        ];
    }
}
