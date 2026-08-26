import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/dashboard_models.dart';
import 'base_service.dart';
import 'cache_service.dart';

class DashboardService with AuthenticatedService {
  DashboardService._();
  static final instance = DashboardService._();

  static const _cacheKey = 'cache_dashboard_v1';

  Future<DashboardData?> getCached() async {
    try {
      final json = await CacheService.instance.getJson(_cacheKey);
      if (json == null) return null;
      return DashboardData.fromJson(json as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<DashboardData> fetchDashboard() async {
    final uri = Uri.parse('${AppConfig.hospitalApiUrl}/admin/dashboard');
    final response = await http.get(uri, headers: await headers).timeout(AppConfig.requestTimeout);
    final json = parseApiResponse(response);
    await CacheService.instance.setJson(_cacheKey, json);
    return DashboardData.fromJson(json);
  }

  Future<TodayPatientsData> fetchTodayPatients({String searchContact = ''}) async {
    final uri = Uri.parse('${AppConfig.hospitalApiUrl}/dashboard/today-patients').replace(
      queryParameters: searchContact.isNotEmpty ? {'search_contact': searchContact} : null,
    );
    final response = await http.get(uri, headers: await headers).timeout(AppConfig.requestTimeout);
    return TodayPatientsData.fromJson(parseApiResponse(response));
  }
}
