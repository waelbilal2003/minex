<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Http\Services\CommentLikeService;

class CommentLikeController extends Controller
{
    protected $commentLikeService;

    public function __construct(CommentLikeService $commentLikeService)
    {
        $this->commentLikeService = $commentLikeService;
    }

    public function toggle(Request $request)
    {
        return $this->commentLikeService->toggleCommentLike($request);
    }
}
