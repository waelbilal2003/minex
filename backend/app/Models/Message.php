<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Message extends Model
{
    use HasFactory;

    public $timestamps = false; // لأن created_at فقط موجود

    protected $fillable = [
        'conversation_id',
        'sender_id',
        'content',
        'message_type',
        'media_url',
        'is_read',
        'created_at',
    ];

    // العلاقة مع المحادثة
    public function conversation()
    {
        return $this->belongsTo(Conversation::class, 'conversation_id');
    }

    // العلاقة مع المستخدم (المرسل)
    public function sender()
    {
        return $this->belongsTo(User::class, 'sender_id');
    }
}
