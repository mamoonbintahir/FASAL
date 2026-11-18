import 'dart:async';

import 'package:fasal_core/fasal_core.dart';
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'auth/jwt.dart';
import 'auth/otp_service.dart';
import 'config.dart';
import 'http/api.dart';
import 'services/farm_service.dart';
import 'store/database.dart';
import 'weather/weather_service.dart';

final _log = Logger('http');

/// Everything the API needs, wired once at startup (or in tests).
class FasalServer {
  FasalServer({
    required this.config,
    required this.db,
    required WeatherProvider weatherProvider,
    SmsSender? sms,
    PushSender? push,
    DateTime Function()? now,
  }) : jwt = Jwt(config.jwtSecret),
       _now = now ?? DateTime.now {
    otp = OtpService(db: db, config: config, sms: sms ?? LoggingSmsSender(), jwt: jwt, now: _now);
    farm = FarmService(
      db: db,
      weather: WeatherService(weatherProvider, ttl: config.weatherCacheTtl),
      push: push ?? LoggingPushSender(),
      now: _now,
    );
  }

  final Config config;
  final Database db;
  final Jwt jwt;
  final DateTime Function() _now;
  late final OtpService otp;
  late final FarmService farm;
  final RateLimiter _authLimiter = RateLimiter(limit: 10, window: const Duration(minutes: 1));

  /// The complete request handler (router + middleware).
  Handler get handler => const Pipeline()
      .addMiddleware(_errors())
      .addMiddleware(_cors(config.corsOrigins))
      .addMiddleware(_logRequests())
      .addHandler(_router().call);

  // ───────────────────────── Routing ─────────────────────────

  Router _router() {
    final r = Router(notFoundHandler: (_) => errorResponse(ApiError.notFound('Unknown endpoint')));

    r.get('/health', (Request _) => jsonResponse({'status': 'ok', 'db': db.kind, 'time': _now().toIso8601String()}));

    // Auth
    r.post('/v1/auth/otp/request', (Request req) async {
      _limit(req);
      final body = await readJson(req);
      final result = await otp.request(body.reqString('phone', max: 20));
      return jsonResponse({'sent': true, 'phone': result.phone, 'devCode': ?result.devCode});
    });
    r.post('/v1/auth/otp/verify', (Request req) async {
      _limit(req);
      final body = await readJson(req);
      final session = await otp.verify(body.reqString('phone', max: 20), body.reqString('code', max: 10));
      final me = await farm.me(session.user['id'] as String);
      return jsonResponse({'token': session.token, ...me});
    });

    // Me / profile
    r.get('/v1/me', (Request req) => _authed(req, (uid) async => jsonResponse(await farm.me(uid))));
    r.put(
      '/v1/me/profile',
      (Request req) =>
          _authed(req, (uid) async => jsonResponse((await farm.saveProfile(uid, await readJson(req))).toJson())),
    );
    r.delete(
      '/v1/me',
      (Request req) => _authed(req, (uid) async {
        await farm.deleteAccount(uid);
        return Response(204);
      }),
    );

    // Crops
    r.get(
      '/v1/crops',
      (Request req) => _authed(req, (uid) async => jsonResponse([for (final c in await farm.crops(uid)) c.toJson()])),
    );
    r.post(
      '/v1/crops',
      (Request req) => _authed(req, (uid) async {
        final crop = await farm.addCrop(uid, await readJson(req));
        return jsonResponse(crop.toJson(), status: 201);
      }),
    );
    r.put(
      '/v1/crops/<id>',
      (Request req, String id) =>
          _authed(req, (uid) async => jsonResponse((await farm.updateCrop(uid, id, await readJson(req))).toJson())),
    );
    r.delete(
      '/v1/crops/<id>',
      (Request req, String id) => _authed(req, (uid) async {
        await farm.deleteCrop(uid, id);
        return Response(204);
      }),
    );

    // Tasks
    r.get(
      '/v1/tasks',
      (Request req) => _authed(req, (uid) async => jsonResponse([for (final t in await farm.tasks(uid)) t.toJson()])),
    );
    r.patch(
      '/v1/tasks/<id>',
      (Request req, String id) =>
          _authed(req, (uid) async => jsonResponse((await farm.updateTask(uid, id, await readJson(req))).toJson())),
    );

    // Weather
    r.get(
      '/v1/weather',
      (Request req) => _authed(req, (uid) async {
        final report = await farm.weatherFor(uid, district: req.url.queryParameters['district']);
        return jsonResponse(report.toJson());
      }),
    );
    r.get(
      '/v1/weather/alerts',
      (Request req) => _authed(req, (uid) async => jsonResponse([for (final a in await farm.alerts(uid)) a.toJson()])),
    );
    r.post(
      '/v1/weather/alerts/read-all',
      (Request req) => _authed(req, (uid) async {
        await farm.markAllAlertsRead(uid);
        return Response(204);
      }),
    );
    r.post(
      '/v1/weather/alerts/<id>/read',
      (Request req, String id) => _authed(req, (uid) async {
        await farm.markAlertRead(uid, id);
        return Response(204);
      }),
    );

    // Guidance (public reference data; still requires sign-in to limit abuse)
    r.get(
      '/v1/guidance/<cropType>/<kind>',
      (Request req, String cropType, String kind) => _authed(req, (_) async {
        if (kCropCatalog.every((c) => c.id != cropType)) throw ApiError.notFound('Unknown crop type');
        return switch (kind) {
          'fertilizer' => jsonResponse([
            for (final g in kFertilizerGuides.where((g) => g.cropTypeId == cropType)) g.toJson(),
          ]),
          'pests' => jsonResponse([for (final g in kPestGuides.where((g) => g.cropTypeId == cropType)) g.toJson()]),
          'sprays' => jsonResponse([
            for (final g in kPesticideGuides.where((g) => g.cropTypeId == cropType)) g.toJson(),
          ]),
          'irrigation' => jsonResponse(kIrrigationGuides.where((g) => g.cropTypeId == cropType).firstOrNull?.toJson()),
          _ => throw ApiError.notFound('Unknown guidance kind'),
        };
      }),
    );
    r.get(
      '/v1/advice',
      (Request req) => _authed(req, (uid) async => jsonResponse([for (final a in await farm.advice(uid)) a.toJson()])),
    );
    r.post(
      '/v1/ask',
      (Request req) => _authed(req, (uid) async {
        final body = await readJson(req);
        return jsonResponse((await farm.ask(uid, body.reqString('question', max: 500))).toJson());
      }),
    );

    // Notifications & devices
    r.get(
      '/v1/notifications',
      (Request req) =>
          _authed(req, (uid) async => jsonResponse([for (final n in await farm.notifications(uid)) n.toJson()])),
    );
    r.post(
      '/v1/notifications/read-all',
      (Request req) => _authed(req, (uid) async {
        await farm.markAllNotificationsRead(uid);
        return Response(204);
      }),
    );
    r.post(
      '/v1/notifications/<id>/read',
      (Request req, String id) => _authed(req, (uid) async {
        await farm.markNotificationRead(uid, id);
        return Response(204);
      }),
    );
    r.post(
      '/v1/notifications/<id>/restore',
      (Request req, String id) => _authed(req, (uid) async {
        await farm.restoreNotification(uid, id);
        return Response(204);
      }),
    );
    r.delete(
      '/v1/notifications/<id>',
      (Request req, String id) => _authed(req, (uid) async {
        await farm.deleteNotification(uid, id);
        return Response(204);
      }),
    );
    r.post(
      '/v1/devices',
      (Request req) => _authed(req, (uid) async {
        final body = await readJson(req);
        await farm.registerDevice(uid, body.reqString('token', max: 4096), body.optString('platform', max: 20));
        return Response(204);
      }),
    );

    // Records
    r.get(
      '/v1/records/activities',
      (Request req) =>
          _authed(req, (uid) async => jsonResponse([for (final a in await farm.activities(uid)) a.toJson()])),
    );
    r.post(
      '/v1/records/activities',
      (Request req) => _authed(
        req,
        (uid) async => jsonResponse((await farm.addActivity(uid, await readJson(req))).toJson(), status: 201),
      ),
    );
    r.delete(
      '/v1/records/activities/<id>',
      (Request req, String id) => _authed(req, (uid) async {
        await farm.deleteActivity(uid, id);
        return Response(204);
      }),
    );
    r.get(
      '/v1/records/expenses',
      (Request req) =>
          _authed(req, (uid) async => jsonResponse([for (final e in await farm.expenses(uid)) e.toJson()])),
    );
    r.post(
      '/v1/records/expenses',
      (Request req) => _authed(
        req,
        (uid) async => jsonResponse((await farm.addExpense(uid, await readJson(req))).toJson(), status: 201),
      ),
    );
    r.delete(
      '/v1/records/expenses/<id>',
      (Request req, String id) => _authed(req, (uid) async {
        await farm.deleteExpense(uid, id);
        return Response(204);
      }),
    );

    return r;
  }

  // ───────────────────────── Helpers ─────────────────────────

  Future<Response> _authed(Request req, Future<Response> Function(String userId) body) async {
    final header = req.headers['authorization'] ?? '';
    if (!header.startsWith('Bearer ')) throw ApiError.unauthorized();
    final claims = jwt.verify(header.substring(7).trim(), now: _now());
    final uid = claims?['sub'];
    if (uid is! String) throw ApiError.unauthorized('Session expired. Please sign in again.');
    return body(uid);
  }

  void _limit(Request req) {
    final ip =
        req.headers['x-forwarded-for']?.split(',').first.trim() ??
        (req.context['shelf.io.connection_info']?.toString() ?? 'local');
    if (!_authLimiter.allow(ip)) throw ApiError.tooMany('Too many attempts. Try again in a minute.');
  }
}

Middleware _errors() =>
    (inner) => (request) async {
      try {
        return await inner(request);
      } on ApiError catch (e) {
        return errorResponse(e);
      } catch (e, st) {
        _log.severe('Unhandled error on ${request.method} /${request.url}', e, st);
        return errorResponse(const ApiError(500, 'server_error', 'Something went wrong'));
      }
    };

Middleware _cors(String origins) {
  final headers = {
    'access-control-allow-origin': origins,
    'access-control-allow-methods': 'GET, POST, PUT, PATCH, DELETE, OPTIONS',
    'access-control-allow-headers': 'authorization, content-type',
  };
  return (inner) => (request) async {
    if (request.method == 'OPTIONS') return Response(204, headers: headers);
    final res = await inner(request);
    return res.change(headers: headers);
  };
}

Middleware _logRequests() =>
    (inner) => (request) async {
      final sw = Stopwatch()..start();
      final res = await inner(request);
      _log.info('${request.method} /${request.url.path} → ${res.statusCode} (${sw.elapsedMilliseconds} ms)');
      return res;
    };
