<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Http\Services\ConversationService;

class ConversationController extends Controller
{
    protected $conversationService;

    public function __construct(ConversationService $conversationService)
    {
        $this->conversationService = $conversationService;
    }

    public function getConversations(Request $request)
    {
        return $this->conversationService->getConversations($request);
    }
}
