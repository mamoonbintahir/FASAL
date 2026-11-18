import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fasal/core/network/api_client.dart';
import 'package:fasal/core/network/app_exception.dart';
import 'package:fasal/core/storage/secure_storage.dart';
import 'package:fasal/data/api/api_repositories.dart';
import 'package:fasal_core/fasal_core.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSecure extends SecureStorage {
  String? token;
  @override
  Future<String?> readToken() async => token;
  @override
  Future<void> writeToken(String t) async => token = t;
  @override
  Future<void> clear() async => token = null;
}

typedef _Handler = (int, Object?) Function(RequestOptions req, Object? body);

/// Answers requests in memory, recording what the app sent.
class _FakeServer implements HttpClientAdapter {
  _FakeServer(this.handler);
  final _Handler handler;
  final List<(String, String, Object?, String?)> calls = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    Object? body;
    if (requestStream != null) {
      final bytes = await requestStream.expand((c) => c).toList();
      if (bytes.isNotEmpty) body = jsonDecode(utf8.decode(bytes));
    }
    calls.add((options.method, options.path, body, options.headers['Authorization'] as String?));
    final (status, json) = handler(options, body);
    return ResponseBody.fromString(
      jsonEncode(json),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  final wheat = kCropCatalog.firstWhere((c) => c.id == 'wheat');
  final crop = Crop(
    id: 'srv_crop_1',
    cropTypeId: 'wheat',
    sowingDate: DateTime(2026, 10, 11),
    area: 5,
    createdAt: DateTime(2026, 11, 18),
  );

  (ApiClient, _FakeServer, _FakeSecure, List<int>) setup(_Handler h) {
    final server = _FakeServer(h);
    final secure = _FakeSecure();
    final expired = <int>[];
    final dio = Dio(BaseOptions(baseUrl: 'http://test'))..httpClientAdapter = server;
    final api = ApiClient(secureStorage: secure, dio: dio, onUnauthorized: () => expired.add(1));
    return (api, server, secure, expired);
  }

  test('sign-in stores the token and sends it on later calls', () async {
    final (api, server, secure, _) = setup(
      (req, body) => switch (req.path) {
        '/v1/auth/otp/request' => (200, {'sent': true, 'phone': '+923001234567', 'devCode': '123456'}),
        '/v1/auth/otp/verify' => (
          200,
          {
            'token': 'tkn',
            'user': {'id': 'u1', 'phone': '+923001234567'},
            'profile': const UserProfile(district: 'Sahiwal', farmArea: 5).toJson(),
          },
        ),
        '/v1/crops' => (200, [crop.toJson()]),
        _ => (
          404,
          {
            'error': {'code': 'not_found', 'message': 'Not found'},
          },
        ),
      },
    );
    final auth = ApiAuthRepository(api, secure);
    expect(auth.requiresSignIn, isTrue);
    expect(await auth.isSignedIn(), isFalse);

    final otp = await auth.requestOtp('0300 1234567');
    expect(otp.devCode, '123456');
    final session = await auth.verifyOtp(otp.phone, '123456');
    expect(session.profile?.district, 'Sahiwal');
    expect(secure.token, 'tkn');
    expect(await auth.isSignedIn(), isTrue);

    final crops = await ApiCropRepository(api).getCrops();
    expect(crops.single.id, 'srv_crop_1');
    expect(server.calls.last.$4, 'Bearer tkn');

    await auth.signOut();
    expect(secure.token, isNull);
  });

  test('completing a task sends PATCH {done:true} and parses the server task', () async {
    final task = const TaskScheduler().generate(crop, wheat, {}).first;
    final (api, server, _, _) = setup(
      (req, body) => (200, task.copyWith(completedAt: DateTime(2026, 11, 18)).toJson()),
    );
    final updated = await ApiTaskRepository(api).setCompleted(task, true);
    expect(server.calls.single.$1, 'PATCH');
    expect(server.calls.single.$2, '/v1/tasks/${task.id}');
    expect(server.calls.single.$3, {'done': true});
    expect(updated.isDone, isTrue);
  });

  test('weather, alerts, guidance and advice parse', () async {
    final report = WeatherReport(
      location: 'Sahiwal',
      current: const CurrentWeather(
        temperature: 24,
        feelsLike: 24,
        condition: WeatherCondition.cloudy,
        humidity: 50,
        windKmh: 5,
        rainChance: 10,
        minTemp: 10,
        maxTemp: 25,
      ),
      daily: [
        DailyForecast(
          date: DateTime(2026, 11, 18),
          condition: WeatherCondition.heavyRain,
          minTemp: 10,
          maxTemp: 20,
          rainChance: 90,
          windKmh: 10,
          humidity: 80,
        ),
      ],
      updatedAt: DateTime(2026, 11, 18),
      isSample: false,
    );
    final alerts = const AlertRules().fromForecast(report);
    final (api, server, _, _) = setup(
      (req, body) => switch (req.path) {
        '/v1/weather' => (200, report.toJson()),
        '/v1/weather/alerts' => (200, [for (final a in alerts) a.toJson()]),
        '/v1/guidance/wheat/fertilizer' => (
          200,
          [for (final g in kFertilizerGuides.where((g) => g.cropTypeId == 'wheat')) g.toJson()],
        ),
        '/v1/guidance/wheat/irrigation' => (200, null),
        _ => (404, null),
      },
    );
    final weather = ApiWeatherRepository(api);
    expect((await weather.getForecast('Sahiwal')).isSample, isFalse);
    expect(server.calls.last.$2, '/v1/weather');
    expect((await weather.getAlerts('Sahiwal')).first.type, AlertType.heavyRain);
    final rec = ApiRecommendationRepository(api);
    expect(await rec.fertilizerGuides('wheat'), isNotEmpty);
    expect(await rec.irrigationGuide('wheat'), isNull);
  });

  test('server errors map to app exceptions; 401 signals session expiry', () async {
    final (api, _, secure, expired) = setup(
      (req, body) => switch (req.path) {
        '/v1/auth/otp/verify' => (
          400,
          {
            'error': {'code': 'otp_invalid', 'message': 'That code is not correct'},
          },
        ),
        _ => (
          401,
          {
            'error': {'code': 'unauthorized', 'message': 'Session expired'},
          },
        ),
      },
    );
    await expectLater(
      ApiAuthRepository(api, secure).verifyOtp('+923001234567', '000000'),
      throwsA(isA<ValidationException>().having((e) => e.message, 'message', 'That code is not correct')),
    );
    expect(expired, isEmpty, reason: 'a wrong code is not a session expiry');
    await expectLater(ApiCropRepository(api).getCrops(), throwsA(isA<UnauthorizedException>()));
    expect(expired, hasLength(1));
  });
}
