import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/doctor_dashboard_models.dart';
import 'base_service.dart';

class DoctorDashboardService with AuthenticatedService {
  DoctorDashboardService._();
  static final DoctorDashboardService instance = DoctorDashboardService._();

  Future<DoctorDashboardData> fetchDashboard({int? viewDoctorId}) async {
    var urlStr = '${AppConfig.hospitalApiUrl}/dashboard/doctor';
    if (viewDoctorId != null) urlStr += '?view_doctor_id=$viewDoctorId';

    final uri = Uri.parse(urlStr);
    debugPrint('[DoctorDashboardService] GET $uri');

    final response = await http.get(uri, headers: await headers).timeout(AppConfig.requestTimeout);

    debugPrint('[DoctorDashboardService] Status: ${response.statusCode}');

    final body = parseApiResponse(response);
    return DoctorDashboardData.fromJson(body['data'] as Map<String, dynamic>);
  }
}
