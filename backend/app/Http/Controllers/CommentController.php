<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Http\Services\CommentService;

class CommentController extends Controller
{
    protected $commentService;

    public function __construct(CommentService $commentService)
    {
        $this->commentService = $commentService;
    }

    public function addComment(Request $request)
    {
        return $this->commentService->addComment($request);
    }
      public function getComments(Request $request)
    {
        return $this->commentService->getComments($request);
    }
  
}
