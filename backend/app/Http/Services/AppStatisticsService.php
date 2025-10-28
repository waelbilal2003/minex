<?php

namespace App\Http\Services;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Auth;

class AppStatisticsService
{
    public function __construct(protected TokenService $service){
    }
    public function getAppStatistics($request)
    {
         $token = $this->service->getBearerToken($request);
        if (!$token) {
            return $this->sendResponse(false, 'التوكن مطلوب');
        }

        // التحقق من صلاحية التوكن
        $userId = $this->service->validateToken($token);
        if (!$userId) {
            return $this->sendResponse(false, 'توكن غير صالح');
        }

        $user = DB::table('users')->find($userId->id);
        if (!$user || !$user->is_admin) {
            return $this->sendResponse(false, 'صلاحيات غير كافية');
        }

        try {
            $stats = [];

            // إحصائيات المستخدمين
            $stats['total_users'] = DB::table('users')->count();
            $stats['active_users'] = DB::table('users')->count();
$lastSeen = DB::table('user_sessions')->value('last_seen');
           // المستخدمون المتصلون (آخر 5 دقائق)
            $stats['online_users'] = DB::table('user_sessions')
                ->where('last_seen', '>', now()->subMinutes(5))
                ->distinct('user_id')
                ->count('user_id');

            // إحصائيات المنشورات
            $stats['total_posts'] = DB::table('posts')->count();
            $stats['active_posts'] = DB::table('posts')->where('is_active', 1)->count();

            // إحصائيات التقارير
            $stats['pending_reports'] = DB::table('post_reports')->where('status', 'pending')->count();

            // إحصائيات الفئات
            $stats['active_categories'] = DB::table('categories')->count();

            // أكثر الفئات استخدامًا
            $stats['top_categories'] = DB::table('posts')
                ->select('category', DB::raw('COUNT(*) as count'))
                ->groupBy('category')
                ->orderByDesc('count')
                ->limit(5)
                ->get();

            // المنشورات اليومية لآخر 30 يوم
            $stats['daily_posts'] = DB::table('posts')
                ->selectRaw('DATE(created_at) as date, COUNT(*) as posts_count')
                ->where('created_at', '>=', now()->subDays(30))
                ->groupBy(DB::raw('DATE(created_at)'))
                ->orderBy('date', 'asc')
                ->get();

            return $this->sendResponse(true, 'تم جلب الإحصائيات بنجاح', ['statistics' => $stats]);
        } catch (\Exception $e) {
            return $this->sendResponse(false, 'خطأ في جلب الإحصائيات: ' . $e->getMessage());
        }
    }

    private function sendResponse($success, $message, $data = [])
    {
        return response()->json([
            'success' => $success,
            'message' => $message,
            'data'    => $data,
        ]);
    }

        public function getDetailedStatistics(Request $request)
    {
        $token = $this->service->getBearerToken($request);

        if (!$token) {
            return $this->sendResponse(false, 'التوكن مطلوب');
        }

        $userId = $this->service->validateToken($token);

        if (!$userId || !$this->isAdmin($userId)) {
            return $this->sendResponse(false, 'صلاحيات غير كافية');
        }

        try {
            // إحصائيات المستخدمين
            $usersStats = DB::table('users')
                ->selectRaw('COUNT(*) as total')
                ->selectRaw('SUM(is_admin = 1) as admins')
                ->selectRaw('SUM(is_active = 1) as active')
                ->selectRaw("SUM(gender = 'male') as male")
                ->selectRaw("SUM(gender = 'female') as female")
                ->first();

            // إحصائيات المنتجات
            // $productsStats = DB::table('products')
            //     ->selectRaw('COUNT(*) as total')
            //     ->selectRaw("SUM(status = 'active') as active")
            //     ->selectRaw("SUM(status = 'sold') as sold")
            //     ->selectRaw("SUM(status = 'inactive') as inactive")
            //     ->first();

            // إحصائيات المنشورات
            $postsStats = DB::table('posts')
                ->selectRaw('COUNT(*) as total')
                ->selectRaw('SUM(is_active = 1) as active')
                ->first();

            $stats = [
                'users' => $usersStats,
                // 'products' => $productsStats,
                'posts' => $postsStats,
            ];

            return $this->sendResponse(true, 'تم جلب الإحصائيات التفصيلية', $stats);
        } catch (\Exception $e) {
            return $this->sendResponse(false, 'خطأ في جلب الإحصائيات التفصيلية: ' . $e->getMessage());
        }
    }
    private function isAdmin($userId)
    {
        return DB::table('users')->where('id', $userId->id)->where('is_admin', 1)->exists();
    }

}
