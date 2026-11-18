import 'dart:async';
import 'dart:io';

import 'package:fasal_server/fasal_server.dart';
import 'package:fasal_server/src/store/mongo_database.dart';
import 'package:logging/logging.dart';
import 'package:shelf/shelf_io.dart' as io;

Future<void> main() async {
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((r) {
    stdout.writeln(
      '${r.time.toIso8601String()} ${r.level.name} ${r.loggerName}: ${r.message}'
      '${r.error == null ? '' : ' — ${r.error}'}',
    );
  });
  final log = Logger('main');
  final config = Config.fromEnvironment();

  final Database db;
  if (config.mongoUri != null) {
    db = await MongoDatabase.connect(config.mongoUri!);
    log.info('Connected to MongoDB');
  } else {
    if (config.production) throw StateError('MONGODB_URI is required in production');
    db = MemoryDatabase();
    log.warning('MONGODB_URI not set — using in-memory storage (data is lost on restart).');
  }

  final server = FasalServer(
    config: config,
    db: db,
    weatherProvider: config.weatherProvider == 'sample' ? SampleWeatherProvider() : OpenMeteoProvider(),
  );

  // Hourly: create reminders/alerts for all users (and push them once FCM is configured).
  final job = Timer.periodic(const Duration(hours: 1), (_) => server.farm.syncAllUsers());

  final http = await io.serve(server.handler, config.host, config.port);
  log.info('FASAL API listening on http://${http.address.host}:${http.port} (db: ${db.kind})');

  Future<void> shutdown(ProcessSignal s) async {
    log.info('Shutting down ($s)');
    job.cancel();
    await http.close();
    await db.close();
    exit(0);
  }

  ProcessSignal.sigint.watch().listen(shutdown);
  if (!Platform.isWindows) ProcessSignal.sigterm.watch().listen(shutdown);
}
