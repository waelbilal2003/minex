<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Category extends Model
{
    protected $table = 'categories';
    protected $fillable = [
        'name',
        // 'description',
        // 'icon',
        // 'color',
        // 'is_active',
        // 'created_at',
    ];

   
}
