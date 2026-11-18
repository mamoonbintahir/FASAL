import 'dart:convert';

import 'package:fasal_server/fasal_server.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

class _Clock {
  DateTime now = DateTime.now();
  DateTime call() => now;
}

class _Api {
  _Api() {
    server = FasalServer(
      config: Config(jwtSecret: 'test-secret-that-is-long-enough-1234567890'),
      db: MemoryDatabase(),
      weatherProvider: SampleWeatherProvider(),
      now: clock.call,
    );
  }

  final clock = _Clock();
  late final FasalServer server;
  String? token;

  Future<(int, dynamic)> call(String method, String path, {Object? body, bool auth = true}) async {
    final res = await server.handler(
      Request(
        method,
        Uri.parse('http://localhost$path'),
        body: body == null ? null : jsonEncode(body),
        headers: {'content-type': 'application/json', if (auth && token != null) 'authorization': 'Bearer $token'},
      ),
    );
    final text = await res.readAsString();
    return (res.statusCode, text.isEmpty ? null : jsonDecode(text));
  }

  Future<void> signIn([String phone = '03001234567']) async {
    final (_, req) = await call('POST', '/v1/auth/otp/request', body: {'phone': phone}, auth: false);
    final (_, res) = await call(
      'POST',
      '/v1/auth/otp/verify',
      body: {'phone': phone, 'code': (req as Map)['devCode']},
      auth: false,
    );
    token = (res as Map)['token'] as String;
  }

  Future<void> setProfile() async {
    await call(
      'PUT',
      '/v1/me/profile',
      body: {'name': 'Ahmed', 'district': 'Sahiwal', 'province': 'Punjab', 'farmArea': 5, 'areaUnit': 'acre'},
    );
  }

  Future<Map<String, dynamic>> addWheat({int daysAgo = 38}) async {
    final sown = clock.now.subtract(Duration(days: daysAgo));
    final (status, body) = await call(
      'POST',
      '/v1/crops',
      body: {'cropTypeId': 'wheat', 'sowingDate': sown.toIso8601String(), 'area': 5, 'areaUnit': 'acre', 'seedKg': 50},
    );
    expect(status, 201);
    return body as Map<String, dynamic>;
  }
}

void main() {
  group('phone numbers', () {
    test('normalises Pakistani mobile formats', () {
      for (final input in ['03001234567', '3001234567', '923001234567', '+92 300 1234567', '0092-300-1234567']) {
        expect(normalizePkPhone(input), '+923001234567', reason: input);
      }
      expect(normalizePkPhone('0423456789'), isNull);
      expect(normalizePkPhone('12345'), isNull);
    });
  });

  group('JWT', () {
    final jwt = Jwt('secret-secret-secret-secret-secret-12');
    test('round trip, tamper and expiry', () {
      final t = jwt.sign({'sub': 'u1'}, ttl: const Duration(minutes: 5));
      expect(jwt.verify(t)?['sub'], 'u1');
      final parts = t.split('.');
      final forged =
          '${parts[0]}.${base64Url.encode(utf8.encode('{"sub":"admin","exp":9999999999}')).replaceAll('=', '')}.${parts[2]}';
      expect(jwt.verify(forged), isNull);
      expect(Jwt('another-secret-another-secret-another').verify(t), isNull);
      expect(jwt.verify(t, now: DateTime.now().add(const Duration(minutes: 6))), isNull);
      expect(jwt.verify('not.a.token'), isNull);
    });
  });

  group('auth', () {
    test('OTP request validates, rate-limits resend, and verifies', () async {
      final api = _Api();
      var (s, b) = await api.call('POST', '/v1/auth/otp/request', body: {'phone': '12'}, auth: false);
      expect(s, 400);
      expect((b as Map)['error']['code'], 'invalid_phone');

      (s, b) = await api.call('POST', '/v1/auth/otp/request', body: {'phone': '0300 1234567'}, auth: false);
      expect(s, 200);
      final code = (b as Map)['devCode'] as String;
      expect(code, hasLength(6));

      (s, _) = await api.call('POST', '/v1/auth/otp/request', body: {'phone': '03001234567'}, auth: false);
      expect(s, 429, reason: 'resend within 60 s');

      (s, b) = await api.call(
        'POST',
        '/v1/auth/otp/verify',
        body: {'phone': '03001234567', 'code': '000000'},
        auth: false,
      );
      expect(s, 400);
      expect((b as Map)['error']['code'], 'otp_invalid');

      (s, b) = await api.call('POST', '/v1/auth/otp/verify', body: {'phone': '03001234567', 'code': code}, auth: false);
      expect(s, 200);
      expect((b as Map)['token'], isA<String>());
      expect(b['user']['phone'], '+923001234567');
      expect(b['profile'], isNull);

      // Code is single-use.
      (s, _) = await api.call('POST', '/v1/auth/otp/verify', body: {'phone': '03001234567', 'code': code}, auth: false);
      expect(s, 400);
    });

    test('OTP expires after 5 minutes', () async {
      final api = _Api();
      final (_, b) = await api.call('POST', '/v1/auth/otp/request', body: {'phone': '03111111111'}, auth: false);
      api.clock.now = api.clock.now.add(const Duration(minutes: 6));
      final (s, e) = await api.call(
        'POST',
        '/v1/auth/otp/verify',
        body: {'phone': '03111111111', 'code': (b as Map)['devCode']},
        auth: false,
      );
      expect(s, 400);
      expect((e as Map)['error']['code'], 'otp_expired');
    });

    test('protected endpoints need a valid token', () async {
      final api = _Api();
      expect((await api.call('GET', '/v1/crops')).$1, 401);
      api.token = 'garbage';
      expect((await api.call('GET', '/v1/crops')).$1, 401);
    });

    test('same phone signs into the same account', () async {
      final api = _Api();
      await api.signIn();
      await api.setProfile();
      api.clock.now = api.clock.now.add(const Duration(minutes: 2));
      await api.signIn();
      final (_, me) = await api.call('GET', '/v1/me');
      expect((me as Map)['profile']['district'], 'Sahiwal');
    });
  });

  group('farm data', () {
    late _Api api;
    setUp(() async {
      api = _Api();
      await api.signIn();
      await api.setProfile();
    });

    test('profile validation', () async {
      final (s, b) = await api.call('PUT', '/v1/me/profile', body: {'district': 'Atlantis', 'farmArea': 5});
      expect(s, 400);
      expect((b as Map)['error']['code'], 'validation');
      expect((await api.call('PUT', '/v1/me/profile', body: {'district': 'Sahiwal', 'farmArea': -1})).$1, 400);
    });

    test('crop validation', () async {
      expect(
        (await api.call('POST', '/v1/crops', body: {'cropTypeId': 'banana', 'sowingDate': '2026-01-01', 'area': 5})).$1,
        400,
      );
      final future = api.clock.now.add(const Duration(days: 90)).toIso8601String();
      expect(
        (await api.call('POST', '/v1/crops', body: {'cropTypeId': 'wheat', 'sowingDate': future, 'area': 5})).$1,
        400,
      );
      expect(
        (await api.call('POST', '/v1/crops', body: {'cropTypeId': 'wheat', 'sowingDate': 'x', 'area': 5})).$1,
        400,
      );
      expect(
        (await api.call('POST', '/v1/crops', body: {'cropTypeId': 'wheat', 'sowingDate': '2026-11-01', 'area': 0})).$1,
        400,
      );
    });

    test('crop → tasks → complete (logs record) → undo → delete', () async {
      final crop = await api.addWheat();
      final (_, crops) = await api.call('GET', '/v1/crops');
      expect(crops, hasLength(1));

      var (_, tasks) = await api.call('GET', '/v1/tasks');
      final list = (tasks as List).cast<Map<String, dynamic>>();
      expect(list, isNotEmpty);
      // Tasks due well before the crop was added count as already done.
      expect(list.firstWhere((t) => t['id'] == '${crop['id']}_irr1')['completedAt'], isNotNull);
      final today = list.firstWhere((t) => t['id'] == '${crop['id']}_irrcheck');
      expect(today['completedAt'], isNull);

      var (s, t) = await api.call('PATCH', '/v1/tasks/${today['id']}', body: {'done': true});
      expect(s, 200);
      expect((t as Map)['completedAt'], isNotNull);
      var (_, acts) = await api.call('GET', '/v1/records/activities');
      expect((acts as List).single['sourceTaskId'], today['id']);

      (s, t) = await api.call('PATCH', '/v1/tasks/${today['id']}', body: {'done': false, 'reminder': 'dayBefore'});
      expect((t as Map)['completedAt'], isNull);
      expect(t['reminder'], 'dayBefore');
      (_, acts) = await api.call('GET', '/v1/records/activities');
      expect(acts, isEmpty);

      expect((await api.call('PATCH', '/v1/tasks/nope', body: {'done': true})).$1, 404);
      expect((await api.call('PATCH', '/v1/tasks/${today['id']}', body: {'reminder': 'weekly'})).$1, 400);

      expect((await api.call('DELETE', '/v1/crops/${crop['id']}')).$1, 204);
      (_, tasks) = await api.call('GET', '/v1/tasks');
      expect(tasks, isEmpty);
      expect((await api.call('DELETE', '/v1/crops/${crop['id']}')).$1, 404);
    });

    test('users cannot see each other\'s data', () async {
      final crop = await api.addWheat();
      final firstToken = api.token;
      api.clock.now = api.clock.now.add(const Duration(minutes: 2));
      await api.signIn('03219876543');
      final (_, crops) = await api.call('GET', '/v1/crops');
      expect(crops, isEmpty);
      expect((await api.call('DELETE', '/v1/crops/${crop['id']}')).$1, 404);
      api.token = firstToken;
      expect((await api.call('GET', '/v1/crops')).$2, hasLength(1));
    });

    test('weather, alerts and read state', () async {
      await api.addWheat();
      final (s, w) = await api.call('GET', '/v1/weather');
      expect(s, 200);
      expect((w as Map)['daily'], hasLength(7));
      expect(w['location'], 'Sahiwal');

      var (_, alerts) = await api.call('GET', '/v1/weather/alerts');
      final heavy = (alerts as List).cast<Map<String, dynamic>>().firstWhere((a) => a['type'] == 'heavyRain');
      expect(heavy['affectedCropTypeIds'], contains('wheat'));
      expect(heavy['isRead'], isFalse);
      expect((await api.call('POST', '/v1/weather/alerts/${heavy['id']}/read')).$1, 204);
      (_, alerts) = await api.call('GET', '/v1/weather/alerts');
      expect((alerts as List).firstWhere((a) => a['id'] == heavy['id'])['isRead'], isTrue);

      expect((await api.call('GET', '/v1/weather?district=Nowhere')).$1, 404);
    });

    test('notifications: generated once, read, delete and restore', () async {
      await api.addWheat();
      var (_, list) = await api.call('GET', '/v1/notifications');
      final items = (list as List).cast<Map<String, dynamic>>();
      expect(items.map((n) => n['type']), containsAll(['weather', 'irrigation']));
      final count = items.length;
      (_, list) = await api.call('GET', '/v1/notifications');
      expect(list, hasLength(count), reason: 'sync is idempotent');

      final id = items.first['id'];
      expect((await api.call('POST', '/v1/notifications/$id/read')).$1, 204);
      expect((await api.call('DELETE', '/v1/notifications/$id')).$1, 204);
      (_, list) = await api.call('GET', '/v1/notifications');
      expect(list, hasLength(count - 1), reason: 'deleted stays deleted');
      expect((await api.call('POST', '/v1/notifications/$id/restore')).$1, 204);
      expect((await api.call('POST', '/v1/notifications/read-all')).$1, 204);
      (_, list) = await api.call('GET', '/v1/notifications');
      expect((list as List).every((n) => n['isRead'] == true), isTrue);
    });

    test('records validation and CRUD', () async {
      final crop = await api.addWheat();
      expect(
        (await api.call(
          'POST',
          '/v1/records/expenses',
          body: {'category': 'gold', 'amount': 10, 'date': '2026-11-01'},
        )).$1,
        400,
      );
      expect(
        (await api.call(
          'POST',
          '/v1/records/expenses',
          body: {'category': 'seeds', 'amount': 12.5, 'date': '2026-11-01'},
        )).$1,
        400,
      );
      expect(
        (await api.call(
          'POST',
          '/v1/records/expenses',
          body: {'category': 'seeds', 'amount': 10, 'date': '2026-11-01', 'cropId': 'stranger'},
        )).$1,
        400,
      );
      final (s, e) = await api.call(
        'POST',
        '/v1/records/expenses',
        body: {'category': 'seeds', 'amount': 9000, 'date': '2026-11-01', 'cropId': crop['id']},
      );
      expect(s, 201);
      expect((await api.call('GET', '/v1/records/expenses')).$2, hasLength(1));
      expect((await api.call('DELETE', '/v1/records/expenses/${(e as Map)['id']}')).$1, 204);

      final (s2, a) = await api.call(
        'POST',
        '/v1/records/activities',
        body: {'type': 'note', 'date': '2026-11-02', 'note': 'Field looks good'},
      );
      expect(s2, 201);
      expect((a as Map)['note'], 'Field looks good');
    });

    test('guidance, advice and Ask Fasal', () async {
      await api.addWheat();
      var (s, g) = await api.call('GET', '/v1/guidance/wheat/fertilizer');
      expect(s, 200);
      expect(g, isNotEmpty);
      expect((g as List).first['source'], 'sample');
      (s, g) = await api.call('GET', '/v1/guidance/wheat/irrigation');
      expect((g as Map)['criticalStages'], isNotEmpty);
      expect((await api.call('GET', '/v1/guidance/banana/pests')).$1, 404);

      final (_, advice) = await api.call('GET', '/v1/advice');
      expect((advice as List).map((a) => a['category']), contains('irrigation'));

      final (_, answer) = await api.call('POST', '/v1/ask', body: {'question': 'When should I water my crop?'});
      expect((answer as Map)['answer']['en'], isNotEmpty);
      expect(answer['answer']['ur'], isNotEmpty);
    });

    test('account deletion removes everything', () async {
      await api.addWheat();
      expect((await api.call('DELETE', '/v1/me')).$1, 204);
      expect((await api.call('GET', '/v1/me')).$1, 401);
    });
  });

  group('misc', () {
    test('health, unknown endpoint, bad JSON', () async {
      final api = _Api();
      final (s, h) = await api.call('GET', '/health', auth: false);
      expect(s, 200);
      expect((h as Map)['db'], 'memory');
      expect((await api.call('GET', '/v1/nothing', auth: false)).$1, 404);
      final res = await api.server.handler(
        Request('POST', Uri.parse('http://localhost/v1/auth/otp/request'), body: '{oops'),
      );
      expect(res.statusCode, 400);
    });

    test('Open-Meteo response parsing', () {
      final report = parseOpenMeteo('Sahiwal', {
        'current': {
          'temperature_2m': 25.6,
          'apparent_temperature': 24.1,
          'relative_humidity_2m': 51,
          'weather_code': 2,
          'wind_speed_10m': 8.4,
        },
        'daily': {
          'time': ['2026-11-18', '2026-11-19'],
          'weather_code': [0, 65],
          'temperature_2m_max': [26.1, 19.4],
          'temperature_2m_min': [11.2, 12.0],
          'precipitation_probability_max': [0, 85],
          'wind_speed_10m_max': [9.1, 24.0],
          'relative_humidity_2m_mean': [48, null],
        },
      });
      expect(report.current.temperature, 26);
      expect(report.current.condition.name, 'partlyCloudy');
      expect(report.daily, hasLength(2));
      expect(report.daily[1].condition.name, 'heavyRain');
      expect(report.daily[1].rainChance, 85);
      expect(report.daily[1].humidity, 51, reason: 'falls back to current humidity');
      expect(report.isSample, isFalse);
    });
  });
}
