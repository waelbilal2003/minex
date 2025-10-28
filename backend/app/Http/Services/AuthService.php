<?php

namespace App\Http\Services;

use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Http\Request;

class AuthService
{
        public function __construct(protected TokenService $service){
    }
    public function register(array $data)
    {
        $emailOrPhone = $data['email_or_phone'];
        $column = filter_var($emailOrPhone, FILTER_VALIDATE_EMAIL) ? 'email' : 'phone';
    $phone = $column === 'phone' ? $this->formatPhone($emailOrPhone) : null;

        // التحقق إذا موجود مسبقًا
    if (
        ($column === 'email' && User::where('email', $emailOrPhone)->exists()) ||
        ($column === 'phone' && User::where('phone', $phone)->exists())
    ) {
        return [
            'success' => false,
            'message' => 'المستخدم موجود مسبقًا',
            'status'  => 400
        ];
    }

 $userType = $data['userType'] ?? null;

if ($userType && !in_array($userType, ['person', 'store'])) {
    return [
        'success' => false,
        'message' => 'نوع المستخدم غير صالح',
        'status'  => 400
    ];
}




        // إنشاء مستخدم جديد
        $user = User::create([
            'full_name' => $data['full_name'],
            'email' => $column === 'email' ? $emailOrPhone : null,
            'phone' => $phone,
            'gender' => $data['gender'],
            'password' => Hash::make($data['password']),
            'is_admin' => false,
            'is_active' => true,
        ]);
        if (!empty($data['userType'])) {
    $user['user_type'] = $data['userType'];
     $user->save();
}
$token = $this->generateToken($user->id);

$user->token = $token;
$user->tokens()->create([
    'user_id' => $user->id,
    'token' => Hash::make($token)
]);

if (!empty($data['device_token'])) {
    \App\Models\DeviceToken::updateOrCreate(
        ['user_id' => $user->id],
        ['device_token' => $data['device_token']]
    );
}

        return [
            'success' => true,
            'message' => 'تم التسجيل بنجاح',
            'user'    => $user,
            'status'  => 201
        ];
    }

     public function login(array $data,$request)
    {
        $emailOrPhone = $data['email_or_phone'];
        $password = $data['password'];

        // تحديد العمود
        $isEmail = filter_var($emailOrPhone, FILTER_VALIDATE_EMAIL);
        $column = $isEmail ? 'email' : 'phone';
        $value = $isEmail ? $emailOrPhone : $this->formatPhone($emailOrPhone);

        // البحث عن المستخدم
        $user = User::where($column, $value)->first();
        if (!$user) {
            return [
                'success' => false,
                'message' => 'المستخدم غير موجود',
                'status' => 404
            ];
        }

        if (!Hash::check($password, $user->password)) {
            return [
                'success' => false,
                'message' => 'كلمة المرور غير صحيحة',
                'status' => 401
            ];
        }

        // إنشاء توكن جديد وحفظه
        $token = $this->generateToken($user->id);
        $user->tokens()->delete(); // حذف التوكنات القديمة

$user->tokens()->create([
    'user_id' => $user->id, // لازم يتخزن
    'token' => Hash::make($token)
]);
        // $user->tokens()->create(['token' => $token]);

    if ($request->filled('device_token')) {
        \App\Models\DeviceToken::updateOrCreate(
            ['user_id' => $user->id],
            ['device_token' => $request->device_token]
        );
    }
        return [
            'success' => true,
            'message' => 'تم تسجيل الدخول بنجاح',
            'data' => [
                'user_id' => $user->id,
                'full_name' => $user->full_name,
                'email' => $user->email,
                'phone' => $user->phone,
                'gender' => $user->gender,
                'is_admin' => $user->is_admin,
                'user_type'=>$user->user_type,
                'token' => $token,
            ],
            'status' => 200
        ];
    }

    private function formatPhone($phone)
    {
        $phone = preg_replace('/[^0-9]/', '', $phone);
        if (substr($phone, 0, 1) === '0') $phone = substr($phone, 1);
        if (!str_starts_with($phone, '963')) $phone = '963' . $phone;
        return '+' . $phone;
    }

    private function generateToken($userId)
    {
        return base64_encode($userId . ':' . time() . ':' . bin2hex(random_bytes(16)));
    }

     public function verifyToken(string $token)
    {
        if (!$token) {
            return [
                'success' => false,
                'message' => 'التوكن مطلوب',
                'status'  => 400
            ];
        }

        $userId = $this->service->validateToken($token);
        if (!$userId) {
            return [
                'success' => false,
                'message' => 'التوكن غير صالح',
                'status'  => 401
            ];
        }

        $user = User::where('id', $userId)->where('is_active', true)->first();

        if (!$user) {
            return [
                'success' => false,
                'message' => 'المستخدم غير موجود أو غير مفعل',
                'status'  => 404
            ];
        }

        return [
            'success' => true,
            'message' => 'التوكن صالح',
            'status'  => 200
        ];
    }
     public function forgotPassword(string $emailOrPhone): array
    {
        if (empty($emailOrPhone)) {
            return [
                'success' => false,
                'message' => 'البريد الإلكتروني أو رقم الهاتف مطلوب',
            ];
        }

        $isEmail = filter_var($emailOrPhone, FILTER_VALIDATE_EMAIL) !== false;
        $isPhone = preg_match('/^[0-9]{9,15}$/', $emailOrPhone);

        if (!$isEmail && !$isPhone) {
            return [
                'success' => false,
                'message' => 'البريد الإلكتروني أو رقم الهاتف غير صحيح',
            ];
        }

        $column = $isEmail ? 'email' : 'phone';
        $formattedValue = $isEmail ? $emailOrPhone : $this->formatPhoneNumber($emailOrPhone);

        $user = User::where($column, $formattedValue)->first();

        if (!$user) {
            return [
                'success' => false,
                'message' => 'المستخدم غير موجود',
            ];
        }

        return [
            'success' => true,
            'message' => 'تم إرسال تعليمات استعادة كلمة المرور إلى بريدك/هاتفك',
        ];
    }

    private function formatPhoneNumber(string $phone): string
    {
        // تنظيف الرقم من أي رموز غير الأرقام
        return preg_replace('/[^0-9]/', '', $phone);
    }
        private function sendResponse($success, $message, $data = [])
    {
        return response()->json([
            'success' => $success,
            'message' => $message,
            'data'    => $data,
        ]);
    }
}
