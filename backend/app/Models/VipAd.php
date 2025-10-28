<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class VipAd extends Model
{
    use HasFactory;

    protected $table = 'vip_ads';

    protected $fillable = [
        'user_id',
        'title',
        'description',
        'category',
        'location',
        'cover_image_url',
        'media_files',
        'contact_whatsapp',
        'contact_phone',
        'price_paid',
        'currency',
        'duration_hours',
        'status',
        'expires_at',
    ];

    protected $casts = [
        'media_files' => 'array', // يخزن كـ JSON
        'expires_at' => 'datetime',
    ];

    // علاقة مع المستخدم
    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
