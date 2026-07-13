import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/clinical_queue_models.dart';
import 'auth_service.dart';

class ClinicalQueueService {
  ClinicalQueueService._();
  static final ClinicalQueueService instance = ClinicalQueueService._();

  Future<Map<String, String>> get _headers async {
    final token = await AuthService.instance.getStoredToken();
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<QueueData> fetchQueue({
    required String date,
    int? doctorId,
  }) async {
    final params = <String, String>{
      'date': date,
      if (doctorId != null) 'doctor_id': doctorId.toString(),
    };
    final uri = Uri.parse('${AppConfig.hospitalApiUrl}/clinical-queue')
        .replace(queryParameters: params);
    final resp = await http
        .get(uri, headers: await _headers)
        .timeout(AppConfig.requestTimeout);

    if (resp.statusCode != 200) {
      throw Exception('Failed to load queue: ${resp.statusCode}');
    }

    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>;

    return QueueData(
      filterDate: (data['filter_date'] as String?) ?? date,
      thresholds: data['wait_thresholds'] != null
          ? AllWaitThresholds.fromJson(
              data['wait_thresholds'] as Map<String, dynamic>)
          : AllWaitThresholds.defaults,
      doctors: (data['doctors'] as List)
          .map((e) => DoctorSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
      primaryQueue: (data['primary_queue'] as List)
          .map((e) => QueuePatient.fromJson(e as Map<String, dynamic>))
          .toList(),
      dilationQueue: (data['dilation_queue'] as List)
          .map((e) => QueuePatient.fromJson(e as Map<String, dynamic>))
          .toList(),
      secondaryQueue: (data['secondary_queue'] as List)
          .map((e) => QueuePatient.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
