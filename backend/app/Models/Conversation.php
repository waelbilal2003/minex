<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Conversation extends Model
{
    use HasFactory;

    protected $fillable = [
        'user1_id',
        'user2_id',
        'min_user_id',
        'max_user_id',
        'last_message_id',
        'last_message_at',
        'is_active',
    ];

    // العلاقات مع المستخدمين
    public function user1()
    {
        return $this->belongsTo(User::class, 'user1_id');
    }

    public function user2()
    {
        return $this->belongsTo(User::class, 'user2_id');
    }

    // العلاقة مع الرسالة الأخيرة
    public function lastMessage()
    {
        return $this->belongsTo(Message::class, 'last_message_id');
    }
}
