<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Report extends Model
{
    use HasFactory;

    protected $fillable = [
        'reporter_id',
        'reported_user_id',
        'reported_product_id',
        'reported_offer_id',
        'reason',
        'description',
        'status',
        'admin_notes',
    ];



      // العلاقة مع المستخدم الذي قام بالإبلاغ
    public function reporter()
    {
        return $this->belongsTo(User::class, 'reporter_id');
    }

    // العلاقة مع المستخدم الذي تم الإبلاغ عنه (اختياري)
    public function reportedUser()
    {
        return $this->belongsTo(User::class, 'reported_user_id');
    }

    // العلاقة مع المنشور الذي تم الإبلاغ عنه
    public function post()
    {
        return $this->belongsTo(Post::class, 'reported_product_id');
    }

    // public function offer()
    // {
    //     return $this->belongsTo(Offer::class, 'reported_offer_id');
    // }

    // public function reportedProduct() { return $this->belongsTo(Product::class, 'reported_product_id'); }
    // public function reportedOffer() { return $this->belongsTo(Offer::class, 'reported_offer_id'); }
}
