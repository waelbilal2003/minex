<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class CommentLike extends Model
{
    protected $table = 'comment_likes';

    protected $fillable = [
        'comment_id',
        'user_id',
    ];

    // العلاقة مع التعليق
    public function comment()
    {
        return $this->belongsTo(Comment::class);
    }

    // العلاقة مع المستخدم
    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
