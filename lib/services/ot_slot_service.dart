import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'auth_service.dart';

class OtSlotItem {
  final int id;
  final String slotName;
  final String? startTime;
  final String? endTime;

  const OtSlotItem({
    required this.id,
    required this.slotName,
    this.startTime,
    this.endTime,
  });

  factory OtSlotItem.fromJson(Map<String, dynamic> j) => OtSlotItem(
        id: j['id'] as int,
        slotName: j['slot_name'] as String? ?? '',
        startTime: j['start_time'] as String?,
        endTime: j['end_time'] as String?,
      );
}

class OtSlotService {
  OtSlotService._();
  static final OtSlotService instance = OtSlotService._();

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

  Future<List<OtSlotItem>> fetchAll() async {
    final res = await http
        .get(Uri.parse('$_base/masters/ot-slots'), headers: await _headers)
        .timeout(AppConfig.requestTimeout);
    final body = _parse(res);
    return (body['data'] as List? ?? [])
        .map((e) => OtSlotItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<OtSlotItem> create(
      String slotName, String? startTime, String? endTime) async {
    final res = await http
        .post(
          Uri.parse('$_base/masters/ot-slots'),
          headers: await _headers,
          body: jsonEncode({
            'slot_name': slotName,
            'start_time': startTime,
            'end_time': endTime,
          }),
        )
        .timeout(AppConfig.requestTimeout);
    final body = _parse(res);
    return OtSlotItem.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<OtSlotItem> update(
      int id, String slotName, String? startTime, String? endTime) async {
    final res = await http
        .put(
          Uri.parse('$_base/masters/ot-slots/$id'),
          headers: await _headers,
          body: jsonEncode({
            'slot_name': slotName,
            'start_time': startTime,
            'end_time': endTime,
          }),
        )
        .timeout(AppConfig.requestTimeout);
    final body = _parse(res);
    return OtSlotItem.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<void> delete(int id) async {
    final res = await http
        .delete(Uri.parse('$_base/masters/ot-slots/$id'), headers: await _headers)
        .timeout(AppConfig.requestTimeout);
    _parse(res);
  }
}
