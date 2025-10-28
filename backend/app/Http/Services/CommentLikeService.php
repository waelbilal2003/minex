<?php

namespace App\Http\Services;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class CommentLikeService
{
        public function __construct(protected TokenService $service){
    }





    public function toggleCommentLike(Request $request)
    {
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

        try {
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
                $postOwnerId = DB::table('comments')->where('id', $commentId)->value('user_id');
                $likerName   = DB::table('users')->where('id', $userId->id)->value('full_name'); // اسم الشخص الذي أعجب
                if ($postOwnerId && $postOwnerId != $userId->id) { // لا نرسل إشعار لنفس الشخص
                    app(FirebaseNotificationService::class)
                        ->sendToUser(
                            $postOwnerId,
                            'إعجاب جديد',
                            "{$likerName} قام بالإعجاب بتعليقك"
                        );
                }
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

    private function sendResponse($success, $message, $data = [])
    {
        return response()->json([
            'success' => $success,
            'message' => $message,
            'data'    => $data,
        ]);
    }
}
