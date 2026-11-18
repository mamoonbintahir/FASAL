// Phase 2 API implementations (skeletons).
//
// These show the integration pattern against the planned Node.js/Express +
// MongoDB REST API. They are NOT active in Phase 1 — enable with
// `--dart-define=USE_MOCK_DATA=false --dart-define=API_BASE_URL=https://...`
// once the endpoints exist. Repositories not listed here fall back to mocks.
//
// Planned endpoints (see README "Backend contract"):
//   GET    /crops                 -> [CropDto]
//   POST   /crops                 -> CropDto
//   PUT    /crops/:id             -> CropDto
//   DELETE /crops/:id
//   GET    /weather?district=...  -> WeatherDto (server calls the weather provider;
//                                   the API key never reaches the app)
//   GET    /weather/alerts?district=...

import '../../core/network/api_client.dart';
import '../../core/network/app_exception.dart';
import '../models/crop.dart';
import '../models/weather.dart';
import '../repositories/repositories.dart';

class ApiCropRepository implements CropRepository {
  ApiCropRepository(this._api);
  final ApiClient _api;

  @override
  Future<List<Crop>> getCrops() async {
    final data = await _api.get('/crops');
    if (data is! List) throw const ServerException('Unexpected response');
    return data.whereType<Map<String, dynamic>>().map(CropDto.fromJson).map((d) => d.toModel()).toList();
  }

  @override
  Future<Crop> addCrop(Crop crop) async {
    final data = await _api.post('/crops', body: CropDto.fromModel(crop).toJson());
    return CropDto.fromJson(data as Map<String, dynamic>).toModel();
  }

  @override
  Future<void> updateCrop(Crop crop) => _api.put('/crops/${crop.id}', body: CropDto.fromModel(crop).toJson());

  @override
  Future<void> deleteCrop(String cropId) => _api.delete('/crops/$cropId');
}

/// Wire format for a crop. Kept separate from the domain model so API field
/// names (e.g. MongoDB `_id`) never leak into the UI.
class CropDto {
  CropDto(this.json);
  final Map<String, dynamic> json;

  factory CropDto.fromJson(Map<String, dynamic> json) => CropDto(json);

  factory CropDto.fromModel(Crop c) => CropDto({...c.toJson(), '_id': c.id}..remove('id'));

  Crop toModel() => Crop.fromJson({...json, 'id': json['_id'] ?? json['id']});

  Map<String, dynamic> toJson() => json;
}

class ApiWeatherRepository implements WeatherRepository {
  ApiWeatherRepository(this._api);
  final ApiClient _api;

  @override
  Future<WeatherReport> getForecast(String district) async {
    final data = await _api.get('/weather', query: {'district': district}) as Map<String, dynamic>;
    return WeatherReport(
      location: data['location'] as String? ?? district,
      current: CurrentWeather.fromJson(data['current'] as Map<String, dynamic>),
      daily: (data['daily'] as List).whereType<Map<String, dynamic>>().map(DailyForecast.fromJson).toList(),
      updatedAt: DateTime.tryParse(data['updatedAt'] as String? ?? '') ?? DateTime.now(),
      isSample: false,
    );
  }

  @override
  Future<List<WeatherAlert>> getAlerts(String district) async =>
      throw UnimplementedError('Alerts endpoint is part of Phase 2');

  @override
  Future<void> markAlertRead(String alertId) => _api.post('/weather/alerts/$alertId/read');

  @override
  Future<void> markAllAlertsRead() => _api.post('/weather/alerts/read-all');
}
