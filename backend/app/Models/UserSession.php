<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class UserSession extends Model
{
    use HasFactory;
        protected $fillable = [
        'user_id',
        'last_seen',
        'ip_address',
        'user_agent',
    ];
}
