<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Http\Services\AppStatisticsService;

class AppStatisticsController extends Controller
{
    protected $service;

    public function __construct(AppStatisticsService $service)
    {
        $this->service = $service;
    }

    public function index(Request $request)
    {
        return $this->service->getAppStatistics($request);
    }
      public function detailed(Request $request)
    {
        return $this->service->getDetailedStatistics($request);
    }
}
