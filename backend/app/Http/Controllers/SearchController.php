<?php

namespace App\Http\Controllers;

use App\Http\Requests\SearchRequest;
use App\Http\Services\SearchService;

class SearchController extends Controller
{
    protected $service;

    public function __construct(SearchService $service)
    {
        $this->service = $service;
    }

    public function search(SearchRequest $request)
    {
        $query = $request->input('query');
        return response()->json($this->service->search($query));
    }
}
