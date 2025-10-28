<?php

namespace App\Http\Services;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ConversationService
{
    public function __construct(protected TokenService $service){
    }

    public function getConversations(Request $request)
    {
        $token = $this->service->getBearerToken($request);
        if (!$token) {
            return $this->sendResponse(false, 'التوكن مطلوب');
        }

        $userId = $this->service->validateToken($token);
        if (!$userId) {
            return $this->sendResponse(false, 'التوكن غير صالح');
        }

        try {
            $conversations = DB::select("
                SELECT
                    c.id as conversation_id,
                    c.last_message_at,
                    other_user.id as other_user_id,
                    other_user.full_name as other_user_name,
                    other_user.gender as other_user_gender,
                    last_msg.content as last_message_content,
                    last_msg.sender_id as last_message_sender_id,
                    (
                        SELECT COUNT(*)
                        FROM messages m
                        WHERE m.conversation_id = c.id
                          AND m.is_read = 0
                          AND m.sender_id != ?
                    ) as unread_count
                FROM conversations c
                JOIN users as other_user
                  ON (other_user.id = c.user1_id OR other_user.id = c.user2_id)
                 AND other_user.id != ?
                LEFT JOIN messages as last_msg
                  ON c.last_message_id = last_msg.id
                WHERE (c.user1_id = ? OR c.user2_id = ?)
                ORDER BY c.last_message_at DESC
            ", [$userId->id, $userId->id, $userId->id, $userId->id]);
            return $this->sendResponse(true, 'تم جلب المحادثات', $conversations);
        } catch (\Exception $e) {
            return $this->sendResponse(false, 'خطأ في جلب المحادثات: ' . $e->getMessage());
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
