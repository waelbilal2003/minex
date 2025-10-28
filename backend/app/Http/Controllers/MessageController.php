<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Http\Services\MessageService;

class MessageController extends Controller
{
    protected $messageService;

    public function __construct(MessageService $messageService)
    {
        $this->messageService = $messageService;
    }

    public function getMessages(Request $request)
    {
        return $this->messageService->getMessages($request);
    }

    public function sendMessage(Request $request)
    {
        return $this->messageService->sendMessage($request);
    }
}
