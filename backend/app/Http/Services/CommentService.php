<?php

namespace App\Http\Services;

use PDOException;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use App\Http\Services\FirebaseNotificationService;

class CommentService
{
        public function __construct(protected TokenService $service){
    }


public function addComment(Request $request)
{
    $token = $this->service->getBearerToken($request);
    if (!$token) {
        return $this->sendResponse(false, 'التوكن مطلوب');
    }

    $userToken = $this->service->validateToken($token);
    if (!$userToken) {
        return $this->sendResponse(false, 'التوكن غير صالح');
    }

    $userId = $userToken->id;

    $postId = $request->input('post_id', 0);
    $content = $request->input('content', '');
    $parentCommentId = $request->input('parent_comment_id');

    if (!$postId || empty($content)) {
        return $this->sendResponse(false, 'معرف المنشور والمحتوى مطلوبان');
    }

    // إذا كان رد، تحقق أن التعليق الأب موجود
    if ($parentCommentId) {
        $parentExists = DB::table('comments')->where('id', $parentCommentId)->exists();
        if (!$parentExists) {
            return $this->sendResponse(false, 'التعليق الأصلي غير موجود');
        }
    }

    try {
        DB::beginTransaction();

        // إدخال التعليق الجديد
        $commentId = DB::table('comments')->insertGetId([
            'post_id'           => $postId,
            'user_id'           => $userId,
            'parent_comment_id' => $parentCommentId,
            'content'           => $content,
            'likes_count'       => 0,
            'replies_count'     => 0,
            'created_at'        => now(),
            'updated_at'        => now(),
        ]);

        // إذا كان رد → زيادة عداد الردود للتعليق الأب
        if ($parentCommentId) {
            DB::table('comments')
                ->where('id', $parentCommentId)
                ->increment('replies_count');
        }

        // زيادة عدد التعليقات في المنشور
        DB::table('posts')
            ->where('id', $postId)
            ->increment('comments_count');

        DB::commit();

        // جلب بيانات المستخدم صاحب التعليق
        $user = DB::table('users')->select('id', 'full_name', 'gender')->find($userId);

        // تجهيز التعليق للـ Response بنفس شكل الفرونت
        $newComment = [
            'id'              => $commentId,
            'post_id'         => $postId,
            'content'         => $content,
            'likes_count'     => 0,
            'is_liked_by_user'=> false,
            'created_at'      => now(),
            'user' => [
                'id'        => $user->id,
                'full_name' => $user->full_name,
                'gender'    => $user->gender,
            ],
            'replies_count'   => 0,
            'replies'         => [], // تعليق جديد ما عنده ردود
        ];

        // 🔔 إرسال إشعار لصاحب المنشور (إذا كان تعليق رئيسي وليس رد على تعليق)
        if (!$parentCommentId) {
            $postOwnerId = DB::table('posts')->where('id', $postId)->value('user_id');
            if ($postOwnerId && $postOwnerId != $userId) {
                app(FirebaseNotificationService::class)
                    ->sendToUser(
                        $postOwnerId,
                        'تعليق جديد',
                        $user->full_name . ' أضاف تعليقاً على منشورك',
                        ['post_id' => (string)$postId, 'comment_id' => (string)$commentId]
                    );
            }
        }

        return response()->json([
            'success' => true,
            'message' => 'تم إضافة التعليق بنجاح',
            'data'    => [
                'comment' => $newComment
            ]
        ]);

    } catch (\Exception $e) {
        DB::rollBack();
        return $this->sendResponse(false, 'خطأ في إضافة التعليق: ' . $e->getMessage());
    }
}

public function getComments($request)
{
    $postId = $request->query('post_id', 0);
    $page = $request->query('page', 1);
    $limit = $request->query('limit', 20);
    $offset = ($page - 1) * $limit;

    if (!$postId) {
        return response()->json([
            'success' => false,
            'message' => 'معرف المنشور مطلوب'
        ]);
    }

    try {
        // جلب التعليقات الرئيسية
        $comments = DB::select("
            SELECT c.*, u.full_name as user_name, u.gender as user_gender,
                   (SELECT COUNT(*) FROM comment_likes WHERE comment_id = c.id) as likes_count,
                   (SELECT COUNT(*) FROM comments WHERE parent_comment_id = c.id) as replies_count
            FROM comments c
            JOIN users u ON c.user_id = u.id
            WHERE c.post_id = ? AND c.parent_comment_id IS NULL
            ORDER BY c.created_at DESC
            LIMIT ? OFFSET ?
        ", [$postId, $limit, $offset]);

        // تحويل كل تعليق لمصفوفة مثل PDO
        $comments = array_map(fn($comment) => (array) $comment, $comments);

        // جلب الردود لكل تعليق
        foreach ($comments as &$comment) {
            $replies = DB::select("
                SELECT c.*, u.full_name as user_name, u.gender as user_gender,
                       (SELECT COUNT(*) FROM comment_likes WHERE comment_id = c.id) as likes_count
                FROM comments c
                JOIN users u ON c.user_id = u.id
                WHERE c.parent_comment_id = ?
                ORDER BY c.created_at ASC
            ", [$comment['id']]);

            $replies = array_map(fn($reply) => (array) $reply, $replies);
            $comment['replies'] = $replies ?: [];
        }

        // إرجاع بالشكل المطلوب
        return response()->json([
            'success' => true,
            'comments' => $comments ?: []
        ]);

    } catch (\Exception $e) {
        return response()->json([
            'success' => false,
            'message' => 'خطأ في جلب التعليقات: ' . $e->getMessage()
        ]);
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


    public function toggleCommentLike(Request $request)
    {dd(2);
        $token = $this->service->getBearerToken($request);
        if (!$token) {
            return $this->sendResponse(false, 'التوكن مطلوب');
        }

        $userId = $this->service->validateToken($token);
        if (!$userId) {
            return $this->sendResponse(false, 'التوكن غير صالح');
        }

        $commentId = $request->input('comment_id', 0);

        if (!$commentId) {
            return $this->sendResponse(false, 'معرف التعليق مطلوب');
        }

        try {dd(1);
            DB::beginTransaction();

            $existingLike = DB::table('comment_likes')
                ->where('comment_id', $commentId)
                ->where('user_id', $userId->id)
                ->first();

            if ($existingLike) {
                // إزالة الإعجاب
                DB::table('comment_likes')
                    ->where('comment_id', $commentId)
                    ->where('user_id', $userId->id)
                    ->delete();

                DB::table('comments')
                    ->where('id', $commentId)
                    ->decrement('likes_count');

                DB::commit();
                return $this->sendResponse(true, 'تم إزالة الإعجاب', [
                    'liked' => false,
                    'likes_count' => DB::table('comments')->where('id', $commentId)->value('likes_count'),
                ]);
            } else {
                // إضافة الإعجاب
                DB::table('comment_likes')->insert([
                    'comment_id' => $commentId,
                    'user_id'    => $userId->id,
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);

                DB::table('comments')
                    ->where('id', $commentId)
                    ->increment('likes_count');

                DB::commit();
                return $this->sendResponse(true, 'تم الإعجاب', [
                    'liked' => true,
                    'likes_count' => DB::table('comments')->where('id', $commentId)->value('likes_count'),
                ]);
            }
        } catch (\Exception $e) {
            DB::rollBack();
            return $this->sendResponse(false, 'خطأ في تحديث الإعجاب: ' . $e->getMessage());
        }
    }


}
