import 'package:mongo_dart/mongo_dart.dart' as m;

import 'database.dart';

/// MongoDB (local or Atlas) implementation of [Database].
/// The FASAL `id` is stored as Mongo `_id` (a string).
class MongoDatabase implements Database {
  MongoDatabase._(this._db);

  final m.Db _db;

  @override
  String get kind => 'mongodb';

  static Future<MongoDatabase> connect(String uri) async {
    final db = await m.Db.create(uri);
    final secure = uri.startsWith('mongodb+srv://') || uri.contains('tls=true') || uri.contains('ssl=true');
    await db.open(secure: secure);
    final store = MongoDatabase._(db);
    await store._ensureIndexes();
    return store;
  }

  Future<void> _ensureIndexes() async {
    await _db.collection('users').createIndex(keys: {'phone': 1}, unique: true);
    for (final c in ['crops', 'task_states', 'activities', 'expenses', 'notifications', 'alerts', 'devices']) {
      await _db.collection(c).createIndex(keys: {'userId': 1});
    }
  }

  @override
  DocCollection collection(String name) => _MongoCollection(_db.collection(name));

  @override
  Future<void> close() => _db.close();
}

class _MongoCollection implements DocCollection {
  _MongoCollection(this._c);

  final m.DbCollection _c;

  Map<String, Object?> _selector(Map<String, Object?> where) => {
    for (final e in where.entries) e.key == 'id' ? '_id' : e.key: e.value,
  };

  Map<String, dynamic> _fromMongo(Map<String, dynamic> doc) {
    final out = Map<String, dynamic>.of(doc)..remove('_id');
    out['id'] = doc['_id'].toString();
    return out;
  }

  @override
  Future<Map<String, dynamic>?> findOne(Map<String, Object?> where) async {
    final d = await _c.findOne(_selector(where));
    return d == null ? null : _fromMongo(d);
  }

  @override
  Future<List<Map<String, dynamic>>> find(Map<String, Object?> where) async => [
    await for (final d in _c.find(_selector(where))) _fromMongo(d),
  ];

  @override
  Future<void> put(Map<String, dynamic> doc) async {
    final id = doc['id'] as String;
    final body = Map<String, dynamic>.of(doc)
      ..remove('id')
      ..['_id'] = id;
    await _c.replaceOne({'_id': id}, body, upsert: true);
  }

  @override
  Future<int> delete(Map<String, Object?> where) async {
    final r = await _c.deleteMany(_selector(where));
    return r.nRemoved;
  }
}
