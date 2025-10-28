<?php

namespace App\Http\Services;

use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

class TokenService
{
    /**
     * استخراج التوكين من الهيدر
     */
    public function getBearerToken($request): ?string
    {
        $header = $request->header('Authorization');
        if ($header && preg_match('/Bearer\s(\S+)/', $header, $matches)) {
            return $matches[1];
        }
        return null;
    }

    /**
     * التحقق من التوكين وإرجاع المستخدم إذا كان صالح
     */
    public function validateToken(?string $token): ?User
    {
        if (!$token) {
            return null;
        }

        // نحصل على كل سجلات المستخدمين يلي عندهم توكنات
        $records = DB::table('user_tokens')->get();

        foreach ($records as $record) {
            if (Hash::check($token, $record->token)) {
                return User::find($record->user_id);
            }
        }

        return null; // إذا ما طابق أي توكين
    }
}
