<?php

namespace App\Http\Services;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class MessageService
{
    public function __construct(protected TokenService $service){
    }
    public function getMessages(Request $request)
    {
        $token = $this->service->getBearerToken($request);
        if (!$token) {
            return $this->sendResponse(false, 'التوكن مطلوب');
        }

        $userId = $this->service->validateToken($token);
        if (!$userId) {
            return $this->sendResponse(false, 'التوكن غير صالح');
        }

        $conversationId = $request->query('conversation_id', 0);
        $page  = $request->query('page', 1);
        $limit = $request->query('limit', 20);
        $offset = ($page - 1) * $limit;

        if (!$conversationId) {
            return $this->sendResponse(false, 'معرف المحادثة مطلوب');
        }

        try {
            // جلب الرسائل
            $messages = DB::select("
                SELECT id, sender_id, content, created_at
                FROM messages
                WHERE conversation_id = ?
                ORDER BY created_at DESC
                LIMIT ? OFFSET ?
            ", [$conversationId, $limit, $offset]);

            // عكس الترتيب
            $messages = array_reverse($messages);

            // تحديث حالة الرسائل لمقروءة
            DB::update("
                UPDATE messages
                SET is_read = 1
                WHERE conversation_id = ? AND sender_id != ? AND is_read = 0
            ", [$conversationId, $userId->id]);
            return $this->sendResponse(true, 'تم جلب الرسائل', $messages);
        } catch (\Exception $e) {
            return $this->sendResponse(false, 'خطأ في جلب الرسائل: ' . $e->getMessage());
        }
    }

    public function sendMessage(Request $request)
    {
        $token = $this->service->getBearerToken($request);
        if (!$token) {
            return $this->sendResponse(false, 'التوكن مطلوب');
        }

        $senderId = $this->service->validateToken($token);
        if (!$senderId) {
            return $this->sendResponse(false, 'التوكن غير صالح');
        }

        $receiverId = $request->input('receiver_id', 0);
        $content    = $request->input('content', '');

        if (!$receiverId || empty(trim($content))) {
            return $this->sendResponse(false, 'معرف المستلم والمحتوى مطلوبان');
        }

        if ($senderId->id == $receiverId) {
            return $this->sendResponse(false, 'لا يمكنك مراسلة نفسك');
        }

        DB::beginTransaction();
        try {
            $minUserId = min($senderId->id, $receiverId);
            $maxUserId = max($senderId->id, $receiverId);

            // التحقق من وجود المحادثة أو إنشائها
            $conversation = DB::table('conversations')
                ->where('min_user_id', $minUserId)
                ->where('max_user_id', $maxUserId)
                ->first();

            $conversationId = null;
            if ($conversation) {
                $conversationId = $conversation->id;
            } else {
                $conversationId = DB::table('conversations')->insertGetId([
                    'user1_id'     => $senderId->id,
                    'user2_id'     => $receiverId,
                    'min_user_id'  => $minUserId,
                    'max_user_id'  => $maxUserId,
                    'created_at'   => now(),
                    'updated_at'   => now(),
                ]);
            }

            // إدراج الرسالة
            $messageId = DB::table('messages')->insertGetId([
                'conversation_id' => $conversationId,
                'sender_id'       => $senderId->id,
                'content'         => $content,
                'created_at'      => now(),
            ]);

            // تحديث المحادثة بآخر رسالة
            DB::table('conversations')
                ->where('id', $conversationId)
                ->update([
                    'last_message_id' => $messageId,
                    'last_message_at' => now(),
                    'updated_at'      => now(),
                ]);

            DB::commit();

            // جلب الرسالة الجديدة
            $newMessage = DB::table('messages')->where('id', $messageId)->first();

              app(FirebaseNotificationService::class)
            ->sendToUser(
                $receiverId,
                'رسالة جديدة',
                "{$senderId->full_name} أرسل لك رسالة: {$content}"
            );
            
            return $this->sendResponse(true, 'تم إرسال الرسالة', [
                'message'         => $newMessage,
                'conversation_id' => $conversationId,
            ]);
        } catch (\Exception $e) {
            DB::rollBack();
            return $this->sendResponse(false, 'خطأ في إرسال الرسالة: ' . $e->getMessage());
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
