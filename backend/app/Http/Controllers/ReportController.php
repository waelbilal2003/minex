<?php

namespace App\Http\Controllers;

use App\Models\UserToken;
use Illuminate\Http\Request;
use App\Http\Services\ReportService;
use App\Http\Services\TokenService;

class ReportController extends Controller
{
    protected $reportService;

    public function __construct(ReportService $reportService,protected TokenService $service)
    {
        $this->reportService = $reportService;
    }

    public function getReportedPosts(Request $request)
    {
        $token = $request->bearerToken();
        $response = $this->reportService->getReportedPosts($token);

        return response()->json($response, $response['success'] ? 200 : 403);
    }
        public function reportPost(Request $request)
    {
        $token = $request->bearerToken();
        $data = $request->all();

        $response = $this->reportService->reportPost($token, $data);

        return response()->json($response, $response['success'] ? 200 : 400);
    }
     public function updateReportStatus(Request $request)
    {
        $token = $request->bearerToken();
        if (!$token) {
            return response()->json(['success'=>false,'message'=>'التوكن مطلوب']);
        }

        $userToken =  $this->service->validateToken($token);
        if (!$userToken || !$userToken->is_admin) {
            return response()->json(['success'=>false,'message'=>'صلاحيات غير كافية']);
        }

        $reportId = $request->input('report_id');
        $status = $request->input('status');
        $adminResponse = $request->input('admin_response', '');

        if (!$reportId || empty($status)) {
            return response()->json(['success'=>false,'message'=>'معرف التقرير والحالة مطلوبان']);
        }

        $response = $this->reportService->updateReportStatus($reportId, $status, $adminResponse);

        return response()->json($response);
    }
}
