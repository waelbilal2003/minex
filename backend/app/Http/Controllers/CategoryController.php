<?php

namespace App\Http\Controllers;

use App\Http\Services\CategoryService;
use Illuminate\Http\Request;

class CategoryController extends Controller
{
    protected $categoryService;

    public function __construct(CategoryService $categoryService)
    {
        $this->categoryService = $categoryService;
    }

    public function index($id =null)
    {
        $response = $this->categoryService->getCategories($id);
        return response()->json($response, $response['success'] ? 200 : 500);
    }
}
