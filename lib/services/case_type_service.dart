import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'auth_service.dart';

class CaseTypeItem {
  final int id;
  final String caseType;
  final double caseFee;

  const CaseTypeItem({
    required this.id,
    required this.caseType,
    required this.caseFee,
  });

  factory CaseTypeItem.fromJson(Map<String, dynamic> j) => CaseTypeItem(
        id: j['id'] as int,
        caseType: j['case_type'] as String? ?? '',
        caseFee: (j['case_fee'] as num?)?.toDouble() ?? 0.0,
      );
}

class CaseTypeService {
  CaseTypeService._();
  static final CaseTypeService instance = CaseTypeService._();

  String get _base => AppConfig.hospitalApiUrl;

  Future<Map<String, String>> get _headers async {
    final token = await AuthService.instance.getStoredToken();
    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
  }

  Map<String, dynamic> _parse(http.Response res) {
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 400) {
      throw Exception(body['message'] ?? 'Request failed (${res.statusCode})');
    }
    return body;
  }

  Future<List<CaseTypeItem>> fetchAll() async {
    final res = await http
        .get(Uri.parse('$_base/masters/case-types'), headers: await _headers)
        .timeout(AppConfig.requestTimeout);
    final body = _parse(res);
    return (body['data'] as List? ?? [])
        .map((e) => CaseTypeItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CaseTypeItem> create(String caseType, double caseFee) async {
    final res = await http
        .post(
          Uri.parse('$_base/masters/case-types'),
          headers: await _headers,
          body: jsonEncode({'case_type': caseType, 'case_fee': caseFee}),
        )
        .timeout(AppConfig.requestTimeout);
    final body = _parse(res);
    return CaseTypeItem.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<CaseTypeItem> update(int id, String caseType, double caseFee) async {
    final res = await http
        .put(
          Uri.parse('$_base/masters/case-types/$id'),
          headers: await _headers,
          body: jsonEncode({'case_type': caseType, 'case_fee': caseFee}),
        )
        .timeout(AppConfig.requestTimeout);
    final body = _parse(res);
    return CaseTypeItem.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<void> delete(int id) async {
    final res = await http
        .delete(Uri.parse('$_base/masters/case-types/$id'), headers: await _headers)
        .timeout(AppConfig.requestTimeout);
    _parse(res);
  }
}
