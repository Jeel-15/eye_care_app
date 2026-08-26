import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'base_service.dart';

class LocationItem {
  final int id;
  final String city;
  final String? district;
  final String? state;

  const LocationItem({
    required this.id,
    required this.city,
    this.district,
    this.state,
  });

  factory LocationItem.fromJson(Map<String, dynamic> j) => LocationItem(
        id: j['id'] as int,
        city: j['city'] as String? ?? '',
        district: j['district'] as String?,
        state: j['state'] as String?,
      );

  String get subtitle {
    final parts = [
      if (district != null && district!.isNotEmpty) district!,
      if (state != null && state!.isNotEmpty) state!,
    ];
    return parts.join(', ');
  }
}

class LocationService with AuthenticatedService {
  LocationService._();
  static final LocationService instance = LocationService._();

  Future<List<LocationItem>> fetchAll() async {
    final res = await http
        .get(Uri.parse('${AppConfig.hospitalApiUrl}/masters/locations'), headers: await headers)
        .timeout(AppConfig.requestTimeout);

    final body = parseApiResponse(res);
    return (body['data'] as List? ?? [])
        .map((e) => LocationItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
