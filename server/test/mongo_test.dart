// Runs the main API flow against a real MongoDB. Skipped unless MONGODB_URI
// is set (CI provides a MongoDB service container).
import 'dart:convert';
import 'dart:io';

import 'package:fasal_server/fasal_server.dart';
import 'package:fasal_server/src/store/mongo_database.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

void main() {
  final uri = Platform.environment['MONGODB_URI'];

  test('sign in, profile, crop, task, records on MongoDB', () async {
    final db = await MongoDatabase.connect(uri!);
    addTearDown(db.close);
    for (final c in ['users', 'otps', 'crops', 'task_states', 'activities', 'expenses', 'alerts', 'notifications']) {
      await db.collection(c).delete({});
    }
    final server = FasalServer(
      config: Config(jwtSecret: 'mongo-test-secret-that-is-long-enough-123'),
      db: db,
      weatherProvider: SampleWeatherProvider(),
    );
    String? token;
    Future<(int, dynamic)> call(String method, String path, [Object? body]) async {
      final res = await server.handler(
        Request(
          method,
          Uri.parse('http://localhost$path'),
          body: body == null ? null : jsonEncode(body),
          headers: {'content-type': 'application/json', 'authorization': ?(token == null ? null : 'Bearer $token')},
        ),
      );
      final text = await res.readAsString();
      return (res.statusCode, text.isEmpty ? null : jsonDecode(text));
    }

    final (_, otp) = await call('POST', '/v1/auth/otp/request', {'phone': '03001234567'});
    final (s, session) = await call('POST', '/v1/auth/otp/verify', {
      'phone': '03001234567',
      'code': (otp as Map)['devCode'],
    });
    expect(s, 200);
    token = (session as Map)['token'] as String;

    expect((await call('PUT', '/v1/me/profile', {'district': 'Multan', 'farmArea': 3})).$1, 200);
    final sown = DateTime.now().subtract(const Duration(days: 38)).toIso8601String();
    final (cs, crop) = await call('POST', '/v1/crops', {'cropTypeId': 'wheat', 'sowingDate': sown, 'area': 3});
    expect(cs, 201);
    final (_, tasks) = await call('GET', '/v1/tasks');
    final today = (tasks as List).firstWhere((t) => t['id'] == '${(crop as Map)['id']}_irrcheck');
    expect((await call('PATCH', '/v1/tasks/${today['id']}', {'done': true})).$1, 200);
    final (_, acts) = await call('GET', '/v1/records/activities');
    expect(acts, hasLength(1));
    final (_, me) = await call('GET', '/v1/me');
    expect((me as Map)['profile']['district'], 'Multan');
    expect((await call('DELETE', '/v1/me')).$1, 204);
  }, skip: uri == null ? 'Set MONGODB_URI to run against MongoDB' : false);
}
