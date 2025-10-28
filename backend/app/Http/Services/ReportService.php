<?php

namespace App\Http\Services;

use App\Models\Post;
use App\Models\User;
use App\Models\Report;
use App\Models\UserToken;
use App\Models\PostReport;

class ReportService
{    public function __construct(protected TokenService $service){
    }
   public function getReportedPosts($token)
{
    if (!$token) {
        return ['success' => false, 'message' => 'التوكن مطلوب'];
    }

    // التحقق من التوكن
    $userToken =  $this->service->validateToken($token);
    if (!$userToken ) {
        return ['success' => false, 'message' => 'توكن غير صالح'];
    }

    // التحقق من صلاحيات الأدمن
    if (!$userToken->is_admin) {
        return ['success' => false, 'message' => 'صلاحيات غير كافية'];
    }

    try {
        $reports = PostReport::with(['post', 'reporter', 'post.user'])
            ->orderByDesc('created_at')
            ->get()
            ->map(function ($report) {
                return [
                    'id' => $report->id,
                    'post_id' => $report->post_id,
                    'reporter_id' => $report->reporter_id,
                    'reason' => $report->reason,
                    'description' => $report->description,
                    'status' => $report->status,
                    'admin_response' => $report->admin_response,
                    'created_at' => $report->created_at,
                    'updated_at' => $report->updated_at,
                    'post_title' => $report->post?->title,
                    'post_content' => $report->post?->content,
                    'reporter_name' => $report->reporter?->full_name,
                    'post_author_name' => $report->post?->user?->full_name,
                ];
            });

        return [
            'success' => true,
            'message' => 'تم جلب التقارير بنجاح',
            'data' => ['reports' => $reports]
        ];

    } catch (\Exception $e) {
        return [
            'success' => false,
            'message' => 'خطأ في جلب التقارير: ' . $e->getMessage()
        ];
    }
}
public function reportPost($token, $data)
{
    if (!$token) {
        return ['success' => false, 'message' => 'التوكن مطلوب'];
    }

    // التحقق من التوكن
    $userToken =$this->service->validateToken($token);

    if (!$userToken) {

        return ['success' => false, 'message' => 'التوكن غير صالح'];
    }

    // $user = $userToken;
// dd($user);
    $postId = $data['post_id'] ?? 0;
    $reason = $data['reason'] ?? '';
    $description = $data['description'] ?? '';

    if (!$postId || empty($reason)) {
        return ['success' => false, 'message' => 'معرف المنشور وسبب الإبلاغ مطلوبان'];
    }

    // التحقق من وجود المنشور
    $post = Post::find($postId);
    if (!$post) {
        return ['success' => false, 'message' => 'المنشور غير موجود'];
    }

    // التحقق من عدم وجود إبلاغ سابق من نفس المستخدم
    $existingReport = PostReport::where('post_id', $postId)
        ->where('reporter_id', $userToken->id)
        ->first();

    if ($existingReport) {
        return ['success' => false, 'message' => 'لقد قمت بالإبلاغ عن هذا المنشور مسبقاً'];
    }

    try {
        // إنشاء التقرير
        $report = PostReport::create([
            'post_id' => $postId,
            'reporter_id' => $userToken->id,
            'reason' => $reason,
            'description' => $description,
        ]);

        // إرسال إشعار للإدمن
        $admins = User::where('is_admin', 1)->get();

        // foreach ($admins as $admin) {
        //     Notification::create([
        //         'user_id' => $admin->id,
        //         'title' => 'إبلاغ جديد عن منشور',
        //         'content' => "تم الإبلاغ عن منشور بسبب: $reason",
        //         'type' => 'system',
        //         'related_id' => $postId,
        //         'related_type' => 'post_report',
        //     ]);
        // }

            foreach ($admins as $admin) {
        app(FirebaseNotificationService::class)
            ->sendToUser(
                $admin->id,
                'إبلاغ جديد عن منشور',
                "تم الإبلاغ عن منشور بسبب: $reason"
            );
    }
        return [
            'success' => true,
            'message' => 'تم إرسال الإبلاغ بنجاح. سيقوم فريق الإدارة بمراجعته.'
        ];

    } catch (\Exception $e) {
        return [
            'success' => false,
            'message' => 'خطأ في إرسال الإبلاغ: ' . $e->getMessage()
        ];
    }
}

  public function updateReportStatus($reportId, $status, $adminResponse)
{
    try {
        $report = PostReport::find($reportId);
        if (!$report) {
            return ['success' => false, 'message' => 'التقرير غير موجود'];
        }

        // تحديث الحالة ورد الإدارة
        $report->status = $status;
        $report->admin_response = $adminResponse;
        $report->save();

        // إرسال إشعار للمبلّغ
        // if ($report->reporter_id) {
        //     $responseMessage = "تم الرد على إبلاغك. الحالة: $status";
        //     if (!empty($adminResponse)) {
        //         $responseMessage .= "\nرد الإدارة: $adminResponse";
        //     }

        //     Notification::create([
        //         'user_id' => $report->reporter_id,
        //         'title' => 'رد على إبلاغك',
        //         'content' => $responseMessage,
        //         'type' => 'report_response',
        //     ]);
        // }

        return ['success' => true, 'message' => 'تم تحديث حالة التقرير بنجاح'];

    } catch (\Exception $e) {
        return [
            'success' => false,
            'message' => 'خطأ في تحديث التقرير: ' . $e->getMessage()
        ];
    }
}

}
