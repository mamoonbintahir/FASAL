/// Tiny document-store abstraction so the API runs on MongoDB in production
/// and on an in-memory store for tests / local development.
///
/// Documents are JSON maps with a string `id`. Filters are simple equality
/// matches on top-level fields — all FASAL queries are of that shape.
abstract interface class DocCollection {
  Future<Map<String, dynamic>?> findOne(Map<String, Object?> where);
  Future<List<Map<String, dynamic>>> find(Map<String, Object?> where);

  /// Insert or replace the document with this `id`.
  Future<void> put(Map<String, dynamic> doc);
  Future<int> delete(Map<String, Object?> where);
}

abstract interface class Database {
  String get kind;
  DocCollection collection(String name);
  Future<void> close();
}

/// In-memory implementation (data is lost on restart).
class MemoryDatabase implements Database {
  final Map<String, MemoryCollection> _collections = {};

  @override
  String get kind => 'memory';

  @override
  DocCollection collection(String name) => _collections.putIfAbsent(name, MemoryCollection.new);

  @override
  Future<void> close() async {}
}

class MemoryCollection implements DocCollection {
  final Map<String, Map<String, dynamic>> _docs = {};

  bool _matches(Map<String, dynamic> doc, Map<String, Object?> where) =>
      where.entries.every((e) => doc[e.key] == e.value);

  Map<String, dynamic> _copy(Map<String, dynamic> d) => Map<String, dynamic>.of(d);

  @override
  Future<Map<String, dynamic>?> findOne(Map<String, Object?> where) async {
    for (final d in _docs.values) {
      if (_matches(d, where)) return _copy(d);
    }
    return null;
  }

  @override
  Future<List<Map<String, dynamic>>> find(Map<String, Object?> where) async => [
    for (final d in _docs.values)
      if (_matches(d, where)) _copy(d),
  ];

  @override
  Future<void> put(Map<String, dynamic> doc) async {
    final id = doc['id'];
    if (id is! String || id.isEmpty) throw ArgumentError('document needs a string id');
    _docs[id] = _copy(doc);
  }

  @override
  Future<int> delete(Map<String, Object?> where) async {
    final ids = [
      for (final e in _docs.entries)
        if (_matches(e.value, where)) e.key,
    ];
    for (final id in ids) {
      _docs.remove(id);
    }
    return ids.length;
  }
}
