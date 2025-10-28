<?php

namespace App\Http\Services;

use App\Models\User;
use App\Models\DeviceToken;
use Kreait\Firebase\Factory;
use Kreait\Firebase\Messaging\CloudMessage;
use Illuminate\Support\Facades\Log;

class FirebaseNotificationService
{
    protected $messaging;

    public function messaging()
    {
        if ($this->messaging) {
            return $this->messaging;
        }

        $credentialsFile = config('firebase.projects.app.credentials.credentials_file');
        $projectId = config('firebase.projects.app.credentials.project_id');

        if (!$credentialsFile || !$projectId) {
            Log::error('Firebase credentials or project ID not set.');
            throw new \Exception('Firebase credentials or project ID not set.');
        }

        $factory = (new Factory)
            ->withServiceAccount($credentialsFile)
            ->withProjectId($projectId);

        return $this->messaging = $factory->createMessaging();
    }

    public function sendToUser(int $userId, string $title, string $body, array $data = []): bool
    {
        $deviceTokens = DeviceToken::where('user_id', $userId)->pluck('device_token')->toArray();

        if (empty($deviceTokens)) {
            Log::warning("No device tokens found for user_id={$userId}");
            return false;
        }

        foreach ($deviceTokens as $token) {

            try {
                $message = CloudMessage::fromArray([
                    'token' => $token,
                    'notification' => [
                        'title' => $title,
                        'body'  => $body,
                    ],
                    'data' => $data,
                ]);

                $this->messaging()->send($message);

                Log::info("Notification sent successfully to user_id={$userId}, token={$token}");
            } catch (\Throwable $e) {
                Log::error("Failed to send notification to user_id={$userId}, token={$token}. Error: " . $e->getMessage());
            }
        }

        return true;
    }

}
